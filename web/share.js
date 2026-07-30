// web/share.js
//
// Thin wrapper around the browser's native Web Share API, with a
// clipboard-copy fallback for contexts where it's unavailable (desktop
// Chrome with no share target, non-HTTPS, older browsers). Loaded by
// index.html; called from Dart via js_interop in
// lib/services/web_share_service.dart.
window.uenrShare = (function () {
  // True if either mechanism share() could use is actually available —
  // lets the Dart side hide the share button entirely rather than show
  // one whose only possible outcome is a failure message (e.g. a
  // non-secure context, where both navigator.share and the Clipboard API
  // are unavailable).
  function isSupported() {
    return !!(navigator.share || (navigator.clipboard && navigator.clipboard.writeText));
  }

  async function share(title, text, url) {
    if (navigator.share) {
      try {
        await navigator.share({ title: title, text: text, url: url });
        return 'shared';
      } catch (e) {
        if (e && e.name === 'AbortError') return 'cancelled';
        // Any other failure (e.g. permission denied) falls through to the
        // clipboard fallback below instead of surfacing as an error.
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      return 'copied';
    } catch (e) {
      return 'failed';
    }
  }

  return { share: share, isSupported: isSupported };
})();
