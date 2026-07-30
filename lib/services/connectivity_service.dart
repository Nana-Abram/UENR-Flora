// lib/services/connectivity_service.dart
import 'dart:js_interop';

@JS('uenrConnectivity.isOnline')
external JSBoolean _isOnline();

@JS('uenrConnectivity.onChange')
external void _onChange(JSFunction callback);

/// Wraps the browser's connectivity signal (navigator.onLine + the window
/// online/offline events) — see web/connectivity.js.
class ConnectivityService {
  static bool get isOnline => _isOnline().toDart;

  /// Registers [onChange] to fire whenever the browser's connectivity flips.
  /// Meant to be called once for the app's lifetime (by
  /// ConnectivityProvider) — see connectivity.js for why there's no
  /// unsubscribe.
  static void listen(void Function(bool online) onChange) {
    _onChange(
      ((JSBoolean online) => onChange(online.toDart)).toJS,
    );
  }
}
