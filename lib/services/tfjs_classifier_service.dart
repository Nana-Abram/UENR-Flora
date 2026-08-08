// lib/services/tfjs_classifier_service.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import '../models/identification_result.dart';
import 'classifier_service.dart';
import 'tta_augmenter.dart';

@JS('uenrFlora.decodeImage')
external JSPromise<JSObject> _decodeImage(JSUint8Array bytes);

@JS('uenrFlora.predictPixels')
external JSPromise<JSObject> _predictPixels(JSFloat32Array pixels);

@JS('uenrFlora.preload')
external JSPromise<JSAny?> _preload();

/// Runs the trained MobileNetV2 model (exported to TensorFlow.js) via
/// web/classifier.js. Web-only — this app has no android/ios targets.
///
/// The model has two heads: a 76-way species softmax and a binary health
/// sigmoid (0 = healthy, 1 = unhealthy). See
/// D:\Final Year Project\Training\training_guide.py for how it was trained.
class TfjsClassifierService implements ClassifierService {
  final Completer<void> _ready = Completer<void>();
  final _augmenter = TtaAugmenter();
  bool _warmupStarted = false;

  @override
  Future<void> get ready => _ready.future;

  @override
  Future<void> warmUp() {
    // Guards against a second caller re-triggering the download — main.dart
    // calls this once, post-first-frame (see its comment), but callers
    // shouldn't have to know that to safely call it again.
    if (!_warmupStarted) {
      _warmupStarted = true;
      // Errors are ignored here; a real classify() call later will retry
      // the fetch itself (see classifier.js's getModel) and surface any
      // genuine problem through the normal error path — `ready` completes
      // regardless, since a failed preload doesn't permanently block that
      // later retry.
      unawaited(_preload().toDart.catchError((_) => null).whenComplete(() {
        if (!_ready.isCompleted) _ready.complete();
      }));
    }
    return ready;
  }

  @override
  Future<ClassificationOutput> classify(List<Uint8List> images) async {
    // A real check, not `assert` — asserts are stripped from release web
    // builds, so this guarded nothing in production. Without it, an empty
    // list reaches `perImage.first`/`.reduce` below and fails with an
    // opaque "Bad state: no element" instead of a clear error.
    if (images.isEmpty) {
      throw ArgumentError.value(images, 'images', 'must not be empty');
    }

    // Each photo is independently run through test-time augmentation (see
    // _classifyWithTta) — that's already the expensive part, so photos run
    // concurrently rather than one after another, same as before TTA.
    final perImage = await Future.wait(images.map(_classifyWithTta));

    // Multiple photos of the same plant are combined by a confidence-
    // weighted average of their (already TTA-averaged) probability
    // distributions — a photo the model was more sure about (higher max
    // probability) pulls the combined result further toward its
    // prediction than a blurry/unclear one does, rather than every photo
    // counting equally regardless of how legible it was. This is why
    // attempt N+1 can push the combined confidence above threshold even
    // when attempt N alone was below it: agreement across angles compounds
    // instead of just being replaced.
    final numClasses = perImage.first.probabilities.length;
    final n = images.length;
    final weights = perImage.map((r) => r.confidence).toList(growable: false);
    final totalWeight = weights.reduce((a, b) => a + b);
    final avgSpecies = List<double>.generate(numClasses, (i) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += perImage[j].probabilities[i] * weights[j];
      }
      return sum / totalWeight;
    });
    final avgHealth =
        perImage.map((r) => r.health).reduce((a, b) => a + b) / n;

    // Simple (unweighted) arithmetic mean across photos — deliberately not
    // confidence-weighted like avgSpecies above. See
    // ClassificationOutput.logits' own doc comment for why.
    final logitLength = perImage.first.logits.length;
    final avgLogits = List<double>.generate(logitLength, (i) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += perImage[j].logits[i];
      }
      return sum / n;
    });

    // Same confidence-weighting applied to ttaAgreement as to the
    // probability vectors above, so a photo the model was surer about
    // also carries more weight in the combined agreement figure.
    var weightedAgreement = 0.0;
    for (var j = 0; j < n; j++) {
      weightedAgreement += perImage[j].ttaAgreement * weights[j];
    }
    final avgTtaAgreement =
        (weightedAgreement / totalWeight).round().clamp(0, 5);

    final bestIndex = _argmax(avgSpecies);
    final bestProb = avgSpecies[bestIndex];
    final isUnhealthy = avgHealth >= 0.5;

    return ClassificationOutput(
      classIndex: bestIndex,
      confidence: bestProb,
      healthStatus:
          isUnhealthy ? HealthStatus.unhealthy : HealthStatus.healthy,
      healthConfidence: isUnhealthy ? avgHealth : 1 - avgHealth,
      probabilities: avgSpecies,
      ttaAgreement: avgTtaAgreement,
      logits: avgLogits,
    );
  }

  /// Runs test-time augmentation for a single photo: 5 augmented variants
  /// (original, horizontal flip, brightness +15%/-15%, center-crop-90% —
  /// see TtaAugmenter) each run through the model separately, then
  /// combined by a confidence-weighted average — the same weighting
  /// scheme [classify] uses across multiple photos, applied here across
  /// multiple views of one photo. [_SingleImageResult.ttaAgreement] is how
  /// many of the 5 variants individually picked the same top species as
  /// the combined result, which is what lets a caller tell "genuinely
  /// confident" apart from "high averaged confidence hiding real
  /// disagreement between views" (see ClassificationOutput.isReliable).
  Future<_SingleImageResult> _classifyWithTta(Uint8List imageBytes) async {
    // Decoded via the browser's native decoder (see decodeImage's comment
    // in web/classifier.js) — a pure-Dart JPEG decode measured 1-1.5s+ and
    // froze the "Analysing..." animation solid for that whole stretch.
    final decoded = await _decodeImage(imageBytes.toJS).toDart;
    final rgbaPixels =
        (decoded.getProperty('pixels'.toJS) as JSUint8Array).toDart;
    final width = (decoded.getProperty('width'.toJS) as JSNumber).toDartInt;
    final height = (decoded.getProperty('height'.toJS) as JSNumber).toDartInt;

    final frames = await _augmenter.generate(
      rgbaPixels: rgbaPixels,
      width: width,
      height: height,
    );
    final results = await Future.wait(
      frames.map((f) => _predictPixels(f.pixels.toJS).toDart),
    );

    final perFrameSpecies = <List<double>>[];
    final perFrameHealth = <double>[];
    final perFrameTop = <int>[];
    final perFrameLogits = <List<double>>[];

    for (final result in results) {
      final speciesJS = result.getProperty('species'.toJS) as JSArray;
      final healthJS = result.getProperty('health'.toJS) as JSNumber;
      final logitsJS = result.getProperty('logits'.toJS) as JSArray;
      final species = speciesJS.toDart
          .map((p) => (p as JSNumber).toDartDouble)
          .toList(growable: false);
      perFrameSpecies.add(species);
      perFrameHealth.add(healthJS.toDartDouble);
      perFrameTop.add(_argmax(species));
      perFrameLogits.add(logitsJS.toDart
          .map((p) => (p as JSNumber).toDartDouble)
          .toList(growable: false));
    }

    final numClasses = perFrameSpecies.first.length;
    final n = frames.length;
    final weights = perFrameSpecies
        .map((p) => p.reduce((a, b) => a > b ? a : b))
        .toList(growable: false);
    final totalWeight = weights.reduce((a, b) => a + b);
    final averaged = List<double>.generate(numClasses, (i) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += perFrameSpecies[j][i] * weights[j];
      }
      return sum / totalWeight;
    });

    // Simple (unweighted) arithmetic mean across the 5 TTA frames —
    // deliberately not confidence-weighted like `averaged` above. See
    // ClassificationOutput.logits' own doc comment for why.
    final logitLength = perFrameLogits.first.length;
    final averagedLogits = List<double>.generate(logitLength, (i) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += perFrameLogits[j][i];
      }
      return sum / n;
    });

    final topIndex = _argmax(averaged);
    final agreement = perFrameTop.where((t) => t == topIndex).length;

    return _SingleImageResult(
      probabilities: averaged,
      confidence: averaged[topIndex],
      // Health comes from the original (unaugmented, first) frame only —
      // the 5 TTA variants exist to stabilise the species call; averaging
      // health across a flipped/cropped/brightness-shifted view doesn't
      // add signal the way it does for the 76-way species distribution.
      health: perFrameHealth.first,
      ttaAgreement: agreement,
      logits: averagedLogits,
    );
  }

  int _argmax(List<double> values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}

class _SingleImageResult {
  final List<double> probabilities;
  final double confidence;
  final double health;
  final int ttaAgreement;
  final List<double> logits;

  const _SingleImageResult({
    required this.probabilities,
    required this.confidence,
    required this.health,
    required this.ttaAgreement,
    required this.logits,
  });
}
