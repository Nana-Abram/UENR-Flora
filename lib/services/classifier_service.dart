// lib/services/classifier_service.dart
import 'dart:typed_data';
import '../models/identification_result.dart';

/// Abstraction over "image bytes → prediction".
///
/// Today:  TfjsClassifierService (calls the TensorFlow.js model via Dart JS interop)
/// Dev:    MockClassifierService (random, but class 0 or 1 so Supabase always finds a match)
///
/// Accepts multiple photos of the same plant — when more than one is given,
/// implementations should combine them (e.g. average the per-image
/// probability distributions) rather than just using the first, since this
/// is what lets a second/third angle raise a low-confidence result.
abstract class ClassifierService {
  /// Resolves once the model is loaded and ready to classify. `classify()`
  /// still works before this resolves (it awaits the load itself), but
  /// callers that want to show a "preparing model" state on a button etc.
  /// can await/watch this instead.
  Future<void> get ready;

  Future<ClassificationOutput> classify(List<Uint8List> images);
}
