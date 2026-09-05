// lib/services/web_speech_service.dart
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';

@JS('uenrSpeech.speak')
external JSPromise<JSAny?> _speak(JSString text);

@JS('uenrSpeech.stop')
external void _stop();

@JS('uenrSpeech.isSupported')
external JSBoolean _isSupported();

@JS('uenrSpeech.isTwiSupported')
external JSBoolean _isTwiSupported();

@JS('uenrSpeech.speakTwi')
external JSPromise<JSAny?> _speakTwi(
  JSString text, JSString endpoint, JSString anonKey, JSFunction onStarted);

/// Reads text aloud using the browser's built-in speech synthesis (Web
/// Speech API), falling back to a no-op when unsupported. Web-only — see
/// web/speech.js.
class WebSpeechService {
  static final activity = ValueNotifier<int>(0);

  static bool get isSupported => _isSupported().toDart;

  static bool get isTwiSupported => _isTwiSupported().toDart;

  static int startSession() {
    final session = activity.value + 1;
    activity.value = session;
    return session;
  }

  /// Speaks [text], completing when it finishes naturally or [stop] cuts it off.
  static Future<void> speak(String text) => _speak(text.toJS).toDart;

  /// Generates and plays a Twi WAV through the Abena browser bridge.
  static Future<void> speakTwi(String text, void Function() onStarted) =>
      _speakTwi(text.toJS, '${SupabaseConfig.url}/functions/v1/abena-tts'.toJS,
        SupabaseConfig.anonKey.toJS, onStarted.toJS).toDart;

  static void stop() {
    _stop();
    activity.value++;
  }
}
