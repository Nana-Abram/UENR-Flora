// lib/features/scan/services/gate_classifier_service.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

@JS('uenrFloraGate.classify')
external JSPromise<JSObject> _classify(JSUint8Array bytes);

@JS('uenrFloraGate.preload')
external JSPromise<JSAny?> _preload();

/// Outcome of running a photo through the binary plant/not-plant gate
/// model — screens out non-plant photos before they ever reach the
/// (much more expensive, and easier to fool) 76-class species model.
class GateResult {
  final bool isPlant;
  final double confidence;

  const GateResult({required this.isPlant, required this.confidence});

  /// User-facing copy for a rejected photo. Only meaningful when
  /// [isPlant] is false — [isPlant] true never surfaces this.
  String get message {
    if (isPlant) return '';
    if (confidence < 0.20) {
      return 'No plant detected — point the camera at a leaf.';
    }
    return 'Cannot confirm this is a plant — try a clearer angle.';
  }
}

/// Runs the binary gate model (a small MobileNetV2, exported to
/// TensorFlow.js) via web/gate_classifier.js. Web-only, same as
/// TfjsClassifierService — see that class for the shared js_interop/
/// warm-up pattern this mirrors.
class GateClassifierService {
  final Completer<void> _ready = Completer<void>();

  Future<void> get ready => _ready.future;

  /// Starts the model download/compile. Called explicitly (not from the
  /// constructor) so it can be kicked off in lockstep with
  /// TfjsClassifierService's own load — see main.dart, which awaits both
  /// in parallel before the scan screen allows scanning.
  Future<void> loadModel() {
    if (!_ready.isCompleted) {
      unawaited(_preload().toDart.catchError((_) => null).whenComplete(() {
        if (!_ready.isCompleted) _ready.complete();
      }));
    }
    return ready;
  }

  Future<GateResult> classify(Uint8List imageBytes) async {
    final result = await _classify(imageBytes.toJS).toDart;
    final confidence =
        (result.getProperty('confidence'.toJS) as JSNumber).toDartDouble;
    return GateResult(isPlant: confidence >= 0.50, confidence: confidence);
  }
}
