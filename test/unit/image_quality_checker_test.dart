import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plantid_app/features/scan/services/image_quality_checker.dart';

/// Encodes a solid-colour test image — used for the tooDark/tooUniform
/// cases, since a flat colour has ~0 variance by construction regardless
/// of how bright it is.
Uint8List _solidColor(int rgb) {
  final image = img.Image(width: 64, height: 64);
  img.fill(image, color: img.ColorRgb8((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF));
  return Uint8List.fromList(img.encodePng(image));
}

/// Encodes a bright, high-variance random-noise test image — passes both
/// the brightness and variance floors, giving ImageQuality.good.
Uint8List _brightNoise() {
  final random = Random(7);
  final image = img.Image(width: 64, height: 64);
  for (var y = 0; y < 64; y++) {
    for (var x = 0; x < 64; x++) {
      // Biased toward the bright half of the range so the mean clears
      // the tooDark floor (30) comfortably, while still varying enough
      // pixel-to-pixel to clear the tooUniform floor (200).
      final v = 140 + random.nextInt(115);
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final checker = ImageQualityChecker();

  group('ImageQualityChecker.checkDetailed', () {
    test('near-black image → tooDark, with a low brightness reading', () async {
      final bytes = _solidColor(0x050505);
      final result = await checker.checkDetailed(bytes);
      expect(result.quality, ImageQuality.tooDark);
      expect(result.brightness, lessThan(30));
    });

    test('solid mid-grey image → tooUniform, with ~0 variance', () async {
      final bytes = _solidColor(0x808080);
      final result = await checker.checkDetailed(bytes);
      expect(result.quality, ImageQuality.tooUniform);
      expect(result.brightness, greaterThanOrEqualTo(30)); // clears the dark floor
      expect(result.variance, lessThan(1)); // a flat colour is ~exactly 0
    });

    test('bright, high-variance photo → good, with plausible brightness/variance', () async {
      final bytes = _brightNoise();
      final result = await checker.checkDetailed(bytes);
      expect(result.quality, ImageQuality.good);
      expect(result.brightness, greaterThanOrEqualTo(30));
      expect(result.variance, greaterThanOrEqualTo(200));
    });

    test('check() still returns just the enum, unchanged from before checkDetailed existed', () async {
      final bytes = _brightNoise();
      final quality = await checker.check(bytes);
      expect(quality, ImageQuality.good);
    });
  });

  group('ImageQualityChecker.getMessage', () {
    test('non-good states have non-empty user-facing copy', () {
      expect(checker.getMessage(ImageQuality.tooDark), isNotEmpty);
      expect(checker.getMessage(ImageQuality.tooUniform), isNotEmpty);
    });

    test('good state has no message (never shown)', () {
      expect(checker.getMessage(ImageQuality.good), isEmpty);
    });
  });
}
