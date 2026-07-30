// web/speech.js
//
// Thin wrapper around the browser's built-in speech synthesis (Web Speech
// API) so plant and article content can be read aloud. No server cost, no
// extra dependency — degrades to a no-op where the API isn't available.
// Loaded by index.html; called from Dart via js_interop in
// lib/services/web_speech_service.dart.
window.uenrSpeech = (function () {
  function isSupported() {
    return 'speechSynthesis' in window;
  }

  function speak(text) {
    return new Promise((resolve) => {
      if (!isSupported()) { resolve(); return; }
      // Cancel whatever's currently playing so overlapping taps (e.g.
      // switching between two "read aloud" buttons) don't queue up.
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.95;
      utterance.onend = () => resolve();
      utterance.onerror = () => resolve();
      window.speechSynthesis.speak(utterance);
    });
  }

  function stop() {
    if (isSupported()) window.speechSynthesis.cancel();
  }

  return { speak: speak, stop: stop, isSupported: isSupported };
})();
