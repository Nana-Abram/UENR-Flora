// lib/services/tta_augmenter.dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// One test-time-augmentation variant, preprocessed to exactly what the
/// TFjs model expects: 224x224, HWC, RGB, normalised to [-1, 1] the same
/// way MobileNetV2's preprocess_input does.
class TtaFrame {
  final Float32List pixels;
  const TtaFrame(this.pixels);
}

/// Produces the 5 test-time-augmentation variants of a photo consumed by
/// TfjsClassifierService.classifyWithTta: averaging predictions across
/// small perturbations of the same photo (a flip, a brightness shift, a
/// tighter crop) smooths out a single unlucky exposure/framing instead of
/// betting everything on one raw pass through the model.
class TtaAugmenter {
  static const size = 224;

  /// Builds each of the 5 frames one at a time with a yield to the event
  /// loop in between, instead of one long unbroken synchronous pass.
  /// Flutter Web has no true background-isolate offload for this kind of
  /// CPU-bound work (unlike native platforms, `compute()`/`Isolate.run`
  /// don't get a separate thread here) — the whole app, including the
  /// "Analysing..." animation, runs on the same single thread as this
  /// resize/crop work. Without a yield point, that thread stays busy
  /// end-to-end and the browser can't paint a frame until all 5
  /// augmentations are done, which reads as the animation freezing then
  /// jumping. `await Future.delayed(Duration.zero)` hands control back to
  /// the browser's event loop just long enough to paint a pending frame
  /// before resuming — same total work, but it stays visibly responsive.
  ///
  /// [rgbaPixels]/[width]/[height] come from web/classifier.js's
  /// decodeImage — the browser's own native, hardware-assisted image
  /// decoder, not a pure-Dart one. Decoding a ~1500px photo in pure Dart
  /// measured 1-1.5s+ and froze the "Analysing..." animation solid for
  /// that whole stretch; the browser's decoder does the same work in a
  /// fraction of the time. classifier.js also downscales to a bound there
  /// (comfortably above 224x224 and the 90% center crop below), so every
  /// augmentation here already runs on a small image.
  Future<List<TtaFrame>> generate({
    required Uint8List rgbaPixels,
    required int width,
    required int height,
  }) async {
    final base = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbaPixels.buffer,
      bytesOffset: rgbaPixels.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    await Future.delayed(Duration.zero);

    final frames = <TtaFrame>[];

    // 1. original — never mutated, safe to use directly
    frames.add(TtaFrame(_toNormalizedPixels(_resizeTo224(base))));
    await Future.delayed(Duration.zero);

    // adjustColor/flipHorizontal mutate their argument in place and return
    // that same reference — each augmentation below gets its own clone of
    // `base` first so they don't corrupt each other or the original.
    // 2. horizontal flip
    frames.add(TtaFrame(
        _toNormalizedPixels(_resizeTo224(img.flipHorizontal(base.clone())))));
    await Future.delayed(Duration.zero);

    // 3. brightness +15%
    frames.add(TtaFrame(_toNormalizedPixels(
        _resizeTo224(img.adjustColor(base.clone(), brightness: 1.15)))));
    await Future.delayed(Duration.zero);

    // 4. brightness -15%
    frames.add(TtaFrame(_toNormalizedPixels(
        _resizeTo224(img.adjustColor(base.clone(), brightness: 0.85)))));
    await Future.delayed(Duration.zero);

    // 5. center crop 90%, resized back to 224
    frames.add(TtaFrame(_toNormalizedPixels(_resizeTo224(_centerCrop90(base)))));

    return frames;
  }

  img.Image _centerCrop90(img.Image image) {
    final cropWidth = (image.width * 0.9).round();
    final cropHeight = (image.height * 0.9).round();
    return img.copyCrop(
      image,
      x: (image.width - cropWidth) ~/ 2,
      y: (image.height - cropHeight) ~/ 2,
      width: cropWidth,
      height: cropHeight,
    );
  }

  img.Image _resizeTo224(img.Image image) {
    if (image.width == size && image.height == size) return image;
    return img.copyResize(image,
        width: size, height: size, interpolation: img.Interpolation.linear);
  }

  Float32List _toNormalizedPixels(img.Image image) {
    final pixels = Float32List(size * size * 3);
    var i = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = image.getPixel(x, y);
        pixels[i++] = (p.r / 127.5) - 1;
        pixels[i++] = (p.g / 127.5) - 1;
        pixels[i++] = (p.b / 127.5) - 1;
      }
    }
    return pixels;
  }
}
