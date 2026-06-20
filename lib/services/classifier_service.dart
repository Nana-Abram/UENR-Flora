// lib/services/classifier_service.dart
import 'dart:typed_data';
import '../models/identification_result.dart';

/// Abstraction over "image bytes → prediction".
///
/// Today:  MockClassifierService (random, but class 0 or 1 so Supabase always finds a match)
/// Later:  TfjsClassifierService (calls the TensorFlow.js model via Dart JS interop)
///
/// To swap: change the Provider<ClassifierService> in main.dart only.
/// No screen or widget code needs to change.
abstract class ClassifierService {
  Future<ClassificationOutput> classify(Uint8List imageBytes);
}
