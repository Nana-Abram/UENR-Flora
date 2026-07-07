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
  const MODEL_URL = 'assets/assets/models/model.json';
  let modelPromise = null;

  function getModel() {
    if (!modelPromise) {
      modelPromise = tf.loadGraphModel(MODEL_URL);
    }
    return modelPromise;
  }

  async function classify(bytes) {
    const model = await getModel();
    const blob = new Blob([bytes], { type: 'image/jpeg' });
    const bitmap = await createImageBitmap(blob);

    let speciesTensor, healthTensor;
    try {
      const input = tf.tidy(() => {
        let img = tf.browser.fromPixels(bitmap);
        img = tf.image.resizeBilinear(img, [224, 224]);
        img = img.toFloat().div(127.5).sub(1);
        return img.expandDims(0);
      });
      [speciesTensor, healthTensor] = model.execute(input, ['Identity:0', 'Identity_1:0']);
      input.dispose();

      const species = Array.from(await speciesTensor.data());
      const health = (await healthTensor.data())[0];
      return { species: species, health: health };
    } finally {
      bitmap.close();
      if (speciesTensor) speciesTensor.dispose();
      if (healthTensor) healthTensor.dispose();
    }
  }

  return { classify: classify };
})();
