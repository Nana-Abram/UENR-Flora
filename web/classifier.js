// web/classifier.js
//
// Runs the UENR Flora MobileNetV2 model (exported as a TFJS graph model)
// in-browser. Loaded by index.html after tfjs.min.js; called from Dart via
// js_interop in lib/services/tfjs_classifier_service.dart.
//
// Model has two named outputs (see D:\Final Year Project\Training\training_guide.py):
//   Identity:0   -> [1, 76] softmax species probabilities
//   Identity_1:0 -> [1, 1]  sigmoid health score (0 = healthy, 1 = unhealthy)
// plus a third tensor pulled from *inside* the graph rather than one of its
// declared outputs — see LOGITS_TENSOR_NAME below. Input is normalised the
// same way MobileNetV2's preprocess_input does: resize to 224x224, scale to
// [-1, 1]. That resize/normalise step now runs on the Dart side (see
// lib/services/tta_augmenter.dart) so it can produce the 5 test-time-
// augmentation variants of a photo — this file only runs the model itself
// on already-preprocessed pixel data (predictPixels).
//
// LOGITS_TENSOR_NAME is the species Dense head's raw pre-softmax output
// (species_1/BiasAdd, [1, 76]) — the same 76 values Identity:0 is the
// softmax of, read straight out of the existing graph (confirmed present
// via assets/models/model.json's own node list, and confirmed to feed
// directly into species_1/Softmax → Identity:0) rather than by
// re-exporting the model with a third declared output.
// tf.GraphModel.execute() can return any named node in the loaded graph,
// not just the ones listed in the model's signature/outputs, so this needs
// no model changes at all — just asking execute() for one more tensor.
//
// History: this used to extract the GlobalAveragePooling2D (and briefly,
// incorrectly, post-BatchNorm) penultimate-layer embedding instead, for a
// Mahalanobis-distance-to-class-centroid OOD detector. Retired 2026-08-07
// after real held-out validation showed that embedding space doesn't
// separate species well enough for reliable OOD detection (a held-out
// photo's own species' centroid was farther away than some OTHER species'
// centroid ~40% of the time, even with ~20 reference photos per class) —
// see lib/features/scan/services/ood_detector.dart's doc comment for the
// replacement approach (an energy score on these logits instead). Consumed
// by way of TfjsClassifierService averaging it across TTA frames/photos
// the same way it does the species probabilities.
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

  // Decodes the raw file bytes of a photo via the browser's own (native,
  // hardware-assisted) image decoder — createImageBitmap — instead of a
  // pure-Dart JPEG decoder, which measured 1-1.5s+ for a single ~1500px
  // photo and froze the "Analysing..." animation solid for that whole
  // stretch (Flutter Web has no real background-thread offload for CPU
  // work like native platforms do, so a long synchronous Dart decode
  // blocks the same thread the animation renders on). Also downscales to
  // MAX_DIM here, before any Dart-side buffer exists — comfortably above
  // the model's 224x224 input and the 90% center-crop augmentation, so
  // quality is unaffected, but every one of the 5 TTA augmentations
  // afterward (resize + per-pixel normalise, done in Dart — see
  // lib/services/tta_augmenter.dart) runs on a much smaller image, which
  // is what actually keeps each of those chunks short enough to not
  // visibly stutter. Returns raw RGBA pixels for TtaAugmenter to wrap
  // directly (no decode) via package:image's Image.fromBytes.
  const MAX_DIM = 512;

  async function decodeImage(bytes) {
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

    const imageData = ctx.getImageData(0, 0, width, height);
    // imageData.data is a Uint8ClampedArray — copy into a plain Uint8Array
    // since that's what Dart's js_interop typed-data bindings expect.
    return { pixels: new Uint8Array(imageData.data.buffer), width: width, height: height };
  }

  // See this file's top-of-file comment for why this is a raw graph node
  // name rather than one of the model's declared outputs.
  const LOGITS_TENSOR_NAME =
      'StatefulPartitionedCall/functional_1/species_1/BiasAdd:0';

  // pixels is a Float32Array of length 224*224*3 (HWC, RGB), already
  // resized to 224x224 and normalised to [-1, 1] by the caller (Dart) —
  // this function just runs the model on it. Kept as a single input +
  // execute() so the Dart side can call it once per TTA augmentation
  // without re-implementing tensor bookkeeping on every call site.
  //
  // Requesting all three tensors in one execute() call (rather than a
  // second execute() just for LOGITS_TENSOR_NAME) computes the shared
  // MobileNetV2 trunk once — TF.js resolves the union of the requested
  // nodes' dependencies in a single graph traversal, so the logits vector
  // costs nothing extra beyond what species/health already paid.
  async function predictPixels(pixels) {
    const model = await getModel();
    let input, speciesTensor, healthTensor, logitsTensor;
    try {
      input = tf.tidy(() => tf.tensor(pixels, [1, 224, 224, 3], 'float32'));
      [speciesTensor, healthTensor, logitsTensor] = model.execute(
          input, ['Identity:0', 'Identity_1:0', LOGITS_TENSOR_NAME]);

      const species = Array.from(await speciesTensor.data());
      const health = (await healthTensor.data())[0];
      const logits = Array.from(await logitsTensor.data());
      return { species: species, health: health, logits: logits };
    } finally {
      if (input) input.dispose();
      if (speciesTensor) speciesTensor.dispose();
      if (healthTensor) healthTensor.dispose();
      if (logitsTensor) logitsTensor.dispose();
    }
  }

  // Fire-and-forget: starts the model download *and* runs one throwaway
  // inference through it, immediately instead of waiting for the first
  // real classify() call. Just fetching the weights (the original version
  // of this function) wasn't enough to fix the first-scan stall — WebGL
  // backend selection and per-op shader compilation are separate one-time
  // costs that only happen on the first model.execute(), and were still
  // silently deferred onto the user's first real scan. Running the exact
  // same op pipeline as predictPixels() (tensor construction → execute →
  // data() readback, which forces a GPU→CPU sync) on a dummy all-zero
  // input forces all of that to happen now instead. Called from Dart as
  // soon as TfjsClassifierService is constructed (app boot).
  function preload() {
    const dummy = new Float32Array(224 * 224 * 3);
    return predictPixels(dummy);
  }

  return { decodeImage: decodeImage, predictPixels: predictPixels, preload: preload };
})();
