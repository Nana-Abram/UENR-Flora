// web/classifier.js
//
// Runs the UENR Flora MobileNetV2 model (exported as a TFJS graph model)
// in-browser. Loaded by index.html after tfjs.min.js; called from Dart via
// js_interop in lib/services/tfjs_classifier_service.dart.
//
// Model has two outputs (see D:\Final Year Project\Training\training_guide.py):
//   Identity:0   -> [1, 76] softmax species probabilities
//   Identity_1:0 -> [1, 1]  sigmoid health score (0 = healthy, 1 = unhealthy)
// Input is normalised the same way MobileNetV2's preprocess_input does:
// resize to 224x224, scale to [-1, 1].
window.uenrFlora = (function () {
  // The doubled "assets/assets/" is correct, not a typo: Flutter's web
  // build copies pubspec.yaml assets (declared as "assets/models/") under
  // an extra "assets/" prefix in the served output. Don't "fix" this to a
  // single "assets/models/model.json" — that path 404s.
  //
  // Cache-busting: these files (model.json + the .weights shards below)
  // are covered by Flutter's own generated flutter_service_worker.js,
  // which content-hashes every declared asset — including these — and
  // invalidates the whole cache atomically on each deploy. So a
  // redeployed/retrained model can't end up served as a stale shard
  // mismatched with a fresh model.json; no separate versioning scheme
  // needed here.
  const MODEL_URL = 'assets/assets/models/model.json';
  let modelPromise = null;

  function getModel() {
    if (!modelPromise) {
      // If the load fails (network blip, etc.), clear modelPromise so the
      // *next* classify() call retries the fetch instead of reusing this
      // same rejected promise forever — without this, one failed load
      // would permanently break scanning until a full page reload.
      modelPromise = tf.loadGraphModel(MODEL_URL).catch((err) => {
        modelPromise = null;
        throw err;
      });
    }
    return modelPromise;
  }

  // The model only ever sees 224x224 (resizeBilinear below), so anything
  // bigger just wastes memory getting there — but the waste matters here:
  // tf.browser.fromPixels allocates a full-resolution texture/tensor from
  // whatever it's given, *before* the resize runs. image_picker's own
  // maxWidth: 1600 (see scan_screen.dart) already keeps normal uploads
  // well under this, but that's a picker-layer convention, not a guarantee
  // this function can rely on — a decompression-bomb file (tiny bytes,
  // huge decoded dimensions) or any future upload path that skips the
  // picker would otherwise hand fromPixels an unbounded image and could
  // hang or crash the tab. Downscaling on a plain <canvas> first bounds
  // that allocation to MAX_DIM regardless of what createImageBitmap
  // decoded, and is a no-op cost-wise for the common case since it's
  // strictly cheaper than resizeBilinear-ing a larger image afterward.
  const MAX_DIM = 1024;

  async function classify(bytes) {
    const model = await getModel();
    const blob = new Blob([bytes], { type: 'image/jpeg' });
    const bitmap = await createImageBitmap(blob);

    let source = bitmap;
    const scale = Math.min(1, MAX_DIM / Math.max(bitmap.width, bitmap.height));
    if (scale < 1) {
      const canvas = document.createElement('canvas');
      canvas.width = Math.round(bitmap.width * scale);
      canvas.height = Math.round(bitmap.height * scale);
      canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
      // Only the canvas is needed from here — safe to free the (possibly
      // huge) original bitmap immediately instead of holding it until this
      // whole classify() call finishes.
      bitmap.close();
      source = canvas;
    }

    let input, speciesTensor, healthTensor;
    try {
      input = tf.tidy(() => {
        let img = tf.browser.fromPixels(source);
        img = tf.image.resizeBilinear(img, [224, 224]);
        img = img.toFloat().div(127.5).sub(1);
        return img.expandDims(0);
      });
      [speciesTensor, healthTensor] = model.execute(input, ['Identity:0', 'Identity_1:0']);

      const species = Array.from(await speciesTensor.data());
      const health = (await healthTensor.data())[0];
      return { species: species, health: health };
    } finally {
      // Only reached open (not yet closed above) when no downscale ran,
      // i.e. source === bitmap and fromPixels needed it to stay alive
      // until tidy() ran.
      if (source === bitmap) bitmap.close();
      // input is disposed here (not right after execute) so it's cleaned
      // up even if model.execute throws — it used to leak on that path.
      if (input) input.dispose();
      if (speciesTensor) speciesTensor.dispose();
      if (healthTensor) healthTensor.dispose();
    }
  }

  // Fire-and-forget: starts the model download *and* runs one throwaway
  // inference through it, immediately instead of waiting for the first
  // real classify() call. Just fetching the weights (the original version
  // of this function) wasn't enough to fix the first-scan stall — WebGL
  // backend selection and per-op shader compilation are separate one-time
  // costs that only happen on the first model.execute(), and were still
  // silently deferred onto the user's first real scan. Running the exact
  // same op pipeline as classify() (fromPixels → resize → normalize →
  // execute → data() readback, which forces a GPU→CPU sync) on a tiny
  // dummy image forces all of that to happen now instead. Called from
  // Dart as soon as TfjsClassifierService is constructed (app boot).
  function preload() {
    const canvas = document.createElement('canvas');
    canvas.width = 8;
    canvas.height = 8;
    canvas.getContext('2d').fillRect(0, 0, 8, 8);

    return getModel().then(async (model) => {
      let input, speciesTensor, healthTensor;
      try {
        input = tf.tidy(() => {
          let img = tf.browser.fromPixels(canvas);
          img = tf.image.resizeBilinear(img, [224, 224]);
          img = img.toFloat().div(127.5).sub(1);
          return img.expandDims(0);
        });
        [speciesTensor, healthTensor] = model.execute(input, ['Identity:0', 'Identity_1:0']);
        await Promise.all([speciesTensor.data(), healthTensor.data()]);
      } finally {
        if (input) input.dispose();
        if (speciesTensor) speciesTensor.dispose();
        if (healthTensor) healthTensor.dispose();
      }
    });
  }

  return { classify: classify, preload: preload };
})();
