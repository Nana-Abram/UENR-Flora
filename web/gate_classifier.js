// web/gate_classifier.js
//
// Runs the UENR Flora binary plant/not-plant "gate" model (a small
// MobileNetV2 classifier, exported as a TFJS graph model) in-browser.
// Loaded by index.html after tfjs.min.js; called from Dart via js_interop
// in lib/features/scan/services/gate_classifier_service.dart.
//
// Single output (see assets/models/gate/model.json's signature):
//   Identity:0 -> [1, 1] sigmoid probability that the image contains a plant.
// Input is normalised the same way the species model is: resize to
// 224x224, scale to [-1, 1]. Unlike the species model, this one runs a
// single pass per photo (no test-time augmentation), so preprocessing
// stays here in JS via canvas, same as classifier.js used to do.
window.uenrFloraGate = (function () {
  // Same doubled "assets/assets/" prefix as classifier.js — see its
  // comment for why. Not a typo.
  const MODEL_URL = 'assets/assets/models/gate/model.json';
  let modelPromise = null;

  function getModel() {
    if (!modelPromise) {
      modelPromise = tf.loadGraphModel(MODEL_URL).catch((err) => {
        modelPromise = null;
        throw err;
      });
    }
    return modelPromise;
  }

  // Mirrors classifier.js's MAX_DIM guard — bounds the fromPixels
  // allocation regardless of what createImageBitmap decoded.
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
      bitmap.close();
      source = canvas;
    }

    let input, outputTensor;
    try {
      input = tf.tidy(() => {
        let img = tf.browser.fromPixels(source);
        img = tf.image.resizeBilinear(img, [224, 224]);
        img = img.toFloat().div(127.5).sub(1);
        return img.expandDims(0);
      });
      outputTensor = model.execute(input, 'Identity:0');
      const confidence = (await outputTensor.data())[0];
      return { confidence: confidence };
    } finally {
      if (source === bitmap) bitmap.close();
      if (input) input.dispose();
      if (outputTensor) outputTensor.dispose();
    }
  }

  // Same rationale as classifier.js's preload() — pays the WebGL
  // shader-compile cost at app boot instead of on the user's first scan.
  function preload() {
    const canvas = document.createElement('canvas');
    canvas.width = 8;
    canvas.height = 8;
    canvas.getContext('2d').fillRect(0, 0, 8, 8);

    return getModel().then(async (model) => {
      let input, outputTensor;
      try {
        input = tf.tidy(() => {
          let img = tf.browser.fromPixels(canvas);
          img = tf.image.resizeBilinear(img, [224, 224]);
          img = img.toFloat().div(127.5).sub(1);
          return img.expandDims(0);
        });
        outputTensor = model.execute(input, 'Identity:0');
        await outputTensor.data();
      } finally {
        if (input) input.dispose();
        if (outputTensor) outputTensor.dispose();
      }
    });
  }

  return { classify: classify, preload: preload };
})();
