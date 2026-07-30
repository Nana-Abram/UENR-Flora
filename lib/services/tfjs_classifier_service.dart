// lib/services/tfjs_classifier_service.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import '../models/identification_result.dart';
import 'classifier_service.dart';

@JS('uenrFlora.classify')
external JSPromise<JSObject> _classify(JSUint8Array bytes);

/// Runs the trained MobileNetV2 model (exported to TensorFlow.js) via
/// web/classifier.js. Web-only — this app has no android/ios targets.
///
/// The model has two heads: a 76-way species softmax and a binary health
/// sigmoid (0 = healthy, 1 = unhealthy). See
/// D:\Final Year Project\Training\training_guide.py for how it was trained.
class TfjsClassifierService implements ClassifierService {
  @override
  Future<ClassificationOutput> classify(List<Uint8List> images) async {
    // A real check, not `assert` — asserts are stripped from release web
    // builds, so this guarded nothing in production. Without it, an empty
    // list reaches `perImageSpecies.first`/`.reduce` below and fails with
    // an opaque "Bad state: no element" instead of a clear error.
    if (images.isEmpty) {
      throw ArgumentError.value(images, 'images', 'must not be empty');
    }

    // Each photo's inference is independent — run them concurrently instead
    // of one after another. Safe with respect to TF.js's tf.tidy() scoping
    // in web/classifier.js: that scope's body is synchronous, so JS's
    // single-threaded event loop can never interleave one call's tidy
    // block with another's, even when multiple classify() calls are
    // in-flight at once.
    final results = await Future.wait(
      images.map((bytes) => _classify(bytes.toJS).toDart),
    );

    final perImageSpecies = <List<double>>[];
    final perImageHealth = <double>[];

    for (final result in results) {
      final speciesJS = result.getProperty('species'.toJS) as JSArray;
      final healthJS = result.getProperty('health'.toJS) as JSNumber;

      perImageSpecies.add(speciesJS.toDart
          .map((p) => (p as JSNumber).toDartDouble)
          .toList(growable: false));
      perImageHealth.add(healthJS.toDartDouble);
    }

    // Multiple photos of the same plant are combined by averaging their
    // probability distributions — agreement across angles raises confidence
    // in the right class, rather than just picking whichever photo "won".
    final numClasses = perImageSpecies.first.length;
    final n = images.length;
    final avgSpecies = List<double>.generate(numClasses, (i) {
      var sum = 0.0;
      for (final probs in perImageSpecies) {
        sum += probs[i];
      }
      return sum / n;
    });
    final avgHealth = perImageHealth.reduce((a, b) => a + b) / n;

    var bestIndex = 0;
    var bestProb = avgSpecies[0];
    for (var i = 1; i < avgSpecies.length; i++) {
      if (avgSpecies[i] > bestProb) {
        bestProb = avgSpecies[i];
        bestIndex = i;
      }
    }

    final isUnhealthy = avgHealth >= 0.5;

    return ClassificationOutput(
      classIndex: bestIndex,
      confidence: bestProb,
      healthStatus: isUnhealthy ? HealthStatus.unhealthy : HealthStatus.healthy,
      healthConfidence: isUnhealthy ? avgHealth : 1 - avgHealth,
    );
  }
}
