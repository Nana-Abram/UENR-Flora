// web/image_resize.js
//
// Downscales/recompresses a photo before it's uploaded to the
// background-identify edge function (see
// lib/features/scan/services/background_identifier_service.dart). That
// call already sends the image over the network twice — browser to edge
// function, then edge function to the vision model — so shrinking the
// payload here directly cuts both legs. The vision model is only picking
// among 5 already-known candidates, not doing fine-grained taxonomy from
// scratch, so it doesn't need the full up-to-1600px capture the local
// TFJS classifier and gallery/detail views use.
//
// Uses the same native-decode approach as classifier.js's decodeImage()
// (createImageBitmap + canvas) rather than a pure-Dart resize, for the
// same reason: this must not become a multi-hundred-ms synchronous Dart
// call blocking the single UI thread.
window.uenrImageResize = (function () {
  const MAX_DIM = 800;
  const JPEG_QUALITY = 0.8;

  // Never throws — on any failure (unsupported format, decode error)
  // resolves with the original bytes unchanged, so a resize hiccup can
  // never be the reason the background second-opinion doesn't fire.
  async function resizeForUpload(bytes) {
    try {
      const blob = new Blob([bytes], { type: 'image/jpeg' });
      const bitmap = await createImageBitmap(blob);
      const scale = Math.min(1, MAX_DIM / Math.max(bitmap.width, bitmap.height));
      const width = Math.max(1, Math.round(bitmap.width * scale));
      const height = Math.max(1, Math.round(bitmap.height * scale));

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(bitmap, 0, 0, width, height);
      bitmap.close();

      const outBlob = await new Promise((resolve, reject) => {
        canvas.toBlob(
          (b) => (b ? resolve(b) : reject(new Error('toBlob returned null'))),
          'image/jpeg',
          JPEG_QUALITY,
        );
      });
      const buf = await outBlob.arrayBuffer();
      return new Uint8Array(buf);
    } catch (err) {
      console.warn('uenrImageResize.resizeForUpload: falling back to original bytes', err);
      return bytes;
    }
  }

  return { resizeForUpload: resizeForUpload };
})();
