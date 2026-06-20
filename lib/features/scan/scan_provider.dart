// lib/features/scan/scan_provider.dart
import 'package:flutter/foundation.dart';

enum ScanState { idle, preview, analyzing }

class ScanProvider extends ChangeNotifier {
  ScanState state = ScanState.idle;
  Uint8List? imageBytes;
  String? errorMessage;

  void setPreview(Uint8List bytes) {
    imageBytes    = bytes;
    state         = ScanState.preview;
    errorMessage  = null;
    notifyListeners();
  }

  void startAnalyzing() {
    state = ScanState.analyzing;
    notifyListeners();
  }

  void setError(String msg) {
    state        = ScanState.idle;
    errorMessage = msg;
    notifyListeners();
  }

  void reset() {
    state        = ScanState.idle;
    imageBytes   = null;
    errorMessage = null;
    notifyListeners();
  }
}
