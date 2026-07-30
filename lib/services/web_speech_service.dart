// lib/services/web_speech_service.dart
import 'dart:js_interop';

@JS('uenrSpeech.speak')
external JSPromise<JSAny?> _speak(JSString text);

@JS('uenrSpeech.stop')
external void _stop();

@JS('uenrSpeech.isSupported')
external JSBoolean _isSupported();

/// Reads text aloud using the browser's built-in speech synthesis (Web
/// Speech API), falling back to a no-op when unsupported. Web-only — see
/// web/speech.js.
class WebSpeechService {
  static bool get isSupported => _isSupported().toDart;

  /// Speaks [text], completing when it finishes naturally or [stop] cuts it off.
  static Future<void> speak(String text) => _speak(text.toJS).toDart;

  static void stop() => _stop();
}
