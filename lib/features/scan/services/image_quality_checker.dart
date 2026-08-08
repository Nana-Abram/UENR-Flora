// lib/features/scan/services/image_quality_checker.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Result of [ImageQualityChecker.check] — whether a photo is even worth
/// running through the (much more expensive) gate and species models.
enum ImageQuality { good, tooDark, tooUniform }

/// Full result of [ImageQualityChecker.checkDetailed] — the raw
/// brightness/variance numbers a [quality] verdict was computed from, not
/// just the pass/fail enum. BackgroundIdentifierService.shouldActivate
/// uses these to tell "clearly fine" apart from "technically passed but
/// marginal" (e.g. brightness 32 barely clears the tooDark floor of 30) —
/// a distinction the bare enum can't make. Both zero when a codec/frame
/// edge case short-circuited the real computation (see [check]'s two
/// early returns) — that path is rare enough it isn't worth threading a
/// nullable pair through every call site instead.
class ImageQualityResult {
  final ImageQuality quality;
  final double brightness;
  final double variance;
  const ImageQualityResult({
    required this.quality,
    required this.brightness,
    required this.variance,
  });
}

/// Cheap raw-pixel screen that runs before any model inference, catching
/// the photos no classifier is needed to reject: a lens covered by a
/// thumb, a shot taken in the dark, a blank wall. Both checks are O(pixel
/// count) over decoded RGBA bytes — no TFjs involved — so this is fast
/// enough to run on every photo before either model loads a single tensor.
class ImageQualityChecker {
  static const double _minAvgBrightness = 30;
  static const double _minVariance = 200;

  /// Same computation [check] has always done, but returns the raw
  /// brightness/variance numbers alongside the pass/fail verdict instead
  /// of discarding them.
  Future<ImageQualityResult> checkDetailed(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return const ImageQualityResult(
            quality: ImageQuality.good, brightness: 0, variance: 0);
      }

      final bytes = byteData.buffer.asUint8List();
      final pixelCount = bytes.length ~/ 4;
      if (pixelCount == 0) {
        return const ImageQualityResult(
            quality: ImageQuality.good, brightness: 0, variance: 0);
      }

      // Single pass over per-pixel average RGB (alpha ignored) — mean and
      // variance from running sum/sum-of-squares rather than two passes.
      var sum = 0.0;
      var sumSq = 0.0;
      for (var i = 0; i < bytes.length; i += 4) {
        final brightness = (bytes[i] + bytes[i + 1] + bytes[i + 2]) / 3;
        sum += brightness;
        sumSq += brightness * brightness;
      }
      final mean = sum / pixelCount;
      final variance = (sumSq / pixelCount) - (mean * mean);

      final quality = mean < _minAvgBrightness
          ? ImageQuality.tooDark
          : variance < _minVariance
              ? ImageQuality.tooUniform
              : ImageQuality.good;
      return ImageQualityResult(
          quality: quality, brightness: mean, variance: variance);
    } finally {
      image.dispose();
    }
  }

  /// Pass/fail verdict only — for callers that don't need the raw
  /// numbers [checkDetailed] also computes.
  Future<ImageQuality> check(Uint8List imageBytes) async =>
      (await checkDetailed(imageBytes)).quality;

  String getMessage(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.tooDark:
        return 'Image is too dark — move to better lighting and try again.';
      case ImageQuality.tooUniform:
        return "Couldn't detect any detail — make sure the lens is clean "
            'and pointed at a plant, not a blank surface.';
      case ImageQuality.good:
        return '';
    }
  }
}
