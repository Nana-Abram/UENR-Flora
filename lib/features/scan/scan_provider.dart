// lib/features/scan/scan_provider.dart
import 'package:flutter/foundation.dart';
import '../../models/identification_result.dart';

enum ScanState { idle, preview, analyzing, needsMoreImages }

/// Drives the multi-photo identification flow. A single low-confidence photo
/// doesn't dead-end the user — up to [maxImages] photos of the same plant
/// are collected and classified together (see ClassifierService.classify),
/// which gives the model more evidence to work with.
class ScanProvider extends ChangeNotifier {
  static const maxImages = 3;

  ScanState state = ScanState.idle;
  final List<Uint8List> images = [];
  String? errorMessage;
  double? lastConfidence;

  /// The most recent below-threshold classification — kept around so
  /// "Use this result anyway" can jump straight to the results screen
  /// without re-running inference.
  ClassificationOutput? lastClassification;

  Uint8List? get primaryImage => images.isEmpty ? null : images.first;
  Uint8List? get latestImage => images.isEmpty ? null : images.last;
  bool get canAddMoreImages => images.length < maxImages;

  /// Starts a fresh identification with a single photo.
  void setPreview(Uint8List bytes) {
    images
      ..clear()
      ..add(bytes);
    state = ScanState.preview;
    errorMessage = null;
    lastConfidence = null;
    lastClassification = null;
    notifyListeners();
  }

  /// Adds another photo of the same plant on top of what's already collected.
  void addImage(Uint8List bytes) {
    if (!canAddMoreImages) return;
    images.add(bytes);
    notifyListeners();
  }

  void startAnalyzing() {
    state = ScanState.analyzing;
    notifyListeners();
  }

  /// Confidence came in below threshold — ask for another angle rather than
  /// dead-ending with a plain "try again".
  void needsMoreImages(ClassificationOutput output) {
    lastConfidence = output.confidence;
    lastClassification = output;
    state = ScanState.needsMoreImages;
    notifyListeners();
  }

  void setError(String msg) {
    state        = ScanState.idle;
    errorMessage = msg;
    notifyListeners();
  }

  void reset() {
    state        = ScanState.idle;
    images.clear();
    errorMessage = null;
    lastConfidence = null;
    lastClassification = null;
    notifyListeners();
  }
}
