// web/speech.js
//
// Thin wrapper around the browser's built-in speech synthesis (Web Speech
// API) so plant and article content can be read aloud. No server cost, no
// extra dependency — degrades to a no-op where the API isn't available.
// Loaded by index.html; called from Dart via js_interop in
// lib/services/web_speech_service.dart.
window.uenrSpeech = (function () {
  let currentAudio = null;
  let currentRequest = null;
  let playbackGeneration = 0;
  const twiAudioCache = new Map();
  const maxCachedTwiAudio = 5;
  const maxTwiChunkLength = 150;

  function cancelCurrent() {
    playbackGeneration++;
    if (currentRequest) { currentRequest.abort(); currentRequest = null; }
    if (currentAudio) {
      currentAudio.pause();
      currentAudio.currentTime = 0;
      currentAudio.onended = null;
      currentAudio.onerror = null;
      currentAudio = null;
    }
  }

  function isSupported() {
    return 'speechSynthesis' in window;
  }

  function isTwiSupported() {
    return typeof Audio !== 'undefined' && typeof fetch !== 'undefined' &&
      typeof AbortController !== 'undefined';
  }

  function speak(text) {
    return new Promise((resolve) => {
      if (!isSupported()) { resolve(); return; }
      // Cancel whatever's currently playing so overlapping taps (e.g.
      // switching between two "read aloud" buttons) don't queue up.
      window.speechSynthesis.cancel();
      cancelCurrent();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.95;
      utterance.onend = () => resolve();
      utterance.onerror = () => resolve();
      window.speechSynthesis.speak(utterance);
    });
  }

  function splitTwiText(text) {
    // Split on ';' as well as sentence-enders: the authored Twi descriptions
    // are written as semicolon-joined clauses with one terminal period, so
    // treating only '.!?' as boundaries let the 250-char pack below cut
    // chunks off mid-clause instead of at a natural pause.
    const sentences = text.match(/[^.!?;]+[.!?;]+|[^.!?;]+$/g) || [text];
    const chunks = [];
    let current = '';
    sentences.forEach((sentence) => {
      const words = sentence.trim().split(/\s+/);
      words.forEach((word) => {
        if (word.length > maxTwiChunkLength) {
          if (current) { chunks.push(current.trim()); current = ''; }
          for (let offset = 0; offset < word.length; offset += maxTwiChunkLength) {
            chunks.push(word.slice(offset, offset + maxTwiChunkLength));
          }
          return;
        }
        if ((current + ' ' + word).trim().length > maxTwiChunkLength && current) {
          chunks.push(current.trim());
          current = '';
        }
        current += (current ? ' ' : '') + word;
      });
    });
    if (current.trim()) chunks.push(current.trim());
    return chunks;
  }

  function fetchTwiChunkAudio(chunk, endpoint, anonKey) {
    const cachedAudio = twiAudioCache.get(chunk);
    if (cachedAudio) return Promise.resolve(cachedAudio);
    currentRequest = new AbortController();
    const request = currentRequest;
    const timeout = setTimeout(() => request.abort(), 45000);
    return fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer ' + anonKey
      },
      body: JSON.stringify({ text: chunk, voice: 'abena_twi_high', speed: 1.0 }),
      signal: request.signal
    })
      .finally(() => clearTimeout(timeout))
      .then((response) => {
        if (!response.ok) throw new Error('Twi audio service returned HTTP ' + response.status);
        return response.json();
      })
      .then((payload) => {
        if (!payload.audio_base64) throw new Error('Twi audio was not returned');
        if (currentRequest === request) currentRequest = null;
        const dataUrl = 'data:audio/wav;base64,' + payload.audio_base64;
        twiAudioCache.delete(chunk);
        twiAudioCache.set(chunk, dataUrl);
        while (twiAudioCache.size > maxCachedTwiAudio) {
          twiAudioCache.delete(twiAudioCache.keys().next().value);
        }
        return dataUrl;
      });
  }

  function speakTwi(text, endpoint, anonKey, onStarted) {
    cancelCurrent();
    const generation = playbackGeneration;
    const chunks = splitTwiText(text);
    if (chunks.length === 0) return Promise.resolve();

    // Pipelined: chunk N+1's audio is fetched while chunk N is still playing,
    // so it's ready by the time playback reaches it instead of leaving a
    // silent gap for the network round-trip at every chunk boundary.
    return new Promise((resolve, reject) => {
      let pendingAudio = fetchTwiChunkAudio(chunks[0], endpoint, anonKey);

      function playFrom(index) {
        if (generation !== playbackGeneration) { resolve(); return; }
        pendingAudio.then((dataUrl) => {
          if (generation !== playbackGeneration) { resolve(); return; }
          if (index + 1 < chunks.length) {
            pendingAudio = fetchTwiChunkAudio(chunks[index + 1], endpoint, anonKey);
          }
          return playTwiAudio(dataUrl, generation, onStarted).then(() => {
            if (index + 1 < chunks.length) {
              playFrom(index + 1);
            } else {
              resolve();
            }
          });
        }).catch(reject);
      }

      playFrom(0);
    });
  }

  function playTwiAudio(dataUrl, generation, onStarted) {
    if (generation !== playbackGeneration) return Promise.resolve();
    return new Promise((resolve, reject) => {
      const audio = new Audio(dataUrl);
      audio.preload = 'auto';
      currentAudio = audio;
      const playbackTimeout = setTimeout(() => {
        if (currentAudio === audio) currentAudio = null;
        audio.pause();
        reject(new Error('Twi audio playback timed out'));
      }, 120000);
      audio.onended = () => {
        clearTimeout(playbackTimeout);
        if (currentAudio === audio) currentAudio = null;
        resolve();
      };
      audio.onerror = () => {
        clearTimeout(playbackTimeout);
        if (currentAudio === audio) currentAudio = null;
        reject(new Error('Twi audio could not be played'));
      };
      audio.play().then(() => {
        if (generation === playbackGeneration && onStarted) onStarted();
      }).catch((error) => {
        clearTimeout(playbackTimeout);
        if (currentAudio === audio) currentAudio = null;
        reject(error);
      });
    });
  }

  function stop() {
    if (isSupported()) window.speechSynthesis.cancel();
    cancelCurrent();
  }

  return {
    speak: speak,
    speakTwi: speakTwi,
    stop: stop,
    isSupported: isSupported,
    isTwiSupported: isTwiSupported
  };
})();
