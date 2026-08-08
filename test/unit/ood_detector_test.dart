import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/scan/services/ood_detector.dart';

/// Hand-builds a minimal, valid .npy v1.0 file (magic + version + header +
/// raw little-endian data) so the parser can be tested without touching a
/// real asset bundle. Mirrors exactly what numpy's own `np.save` writes for
/// the shapes/dtypes this project's three real assets use.
ByteData _buildNpy({
  required String descr,
  required List<int> shape,
  required List<double> values,
  bool fortranOrder = false,
}) {
  final shapeStr = shape.isEmpty
      ? '()'
      : shape.length == 1
          ? '(${shape[0]},)'
          : '(${shape.join(', ')})';
  var header = "{'descr': '$descr', 'fortran_order': "
      "${fortranOrder ? 'True' : 'False'}, 'shape': $shapeStr, }";
  // Pad so magic(6) + version(2) + headerLen(2) + header ends on a 64-byte
  // boundary and terminates with '\n', same convention numpy itself uses.
  const prefixLen = 6 + 2 + 2;
  final unpadded = header.length + 1;
  final totalLen = ((prefixLen + unpadded + 63) ~/ 64) * 64;
  final padLen = totalLen - prefixLen - unpadded;
  header = '$header${' ' * padLen}\n';
  final headerBytes = latin1.encode(header);

  final bytesPerElement = descr == '<f4' ? 4 : 8;
  final buffer = ByteData(
      prefixLen + headerBytes.length + values.length * bytesPerElement);
  var offset = 0;
  const magic = [0x93, 0x4E, 0x55, 0x4D, 0x50, 0x59];
  for (final b in magic) {
    buffer.setUint8(offset++, b);
  }
  buffer.setUint8(offset++, 1); // major version
  buffer.setUint8(offset++, 0); // minor version
  buffer.setUint16(offset, headerBytes.length, Endian.little);
  offset += 2;
  for (final b in headerBytes) {
    buffer.setUint8(offset++, b);
  }
  for (final v in values) {
    if (descr == '<f4') {
      buffer.setFloat32(offset, v, Endian.little);
      offset += 4;
    } else {
      buffer.setFloat64(offset, v, Endian.little);
      offset += 8;
    }
  }
  return buffer;
}

void main() {
  group('OodDetector npy parsing', () {
    test('parses a <f4> 1-D array', () {
      final bytes =
          _buildNpy(descr: '<f4', shape: [4], values: [1.5, -2.25, 0.0, 3.0]);
      final result = OodDetector.parseNpyForTesting(bytes, 'test');
      expect(result.shape, [4]);
      expect(result.data, [1.5, -2.25, 0.0, 3.0]);
    });

    test('parses a <f8> 2-D array', () {
      final bytes = _buildNpy(
        descr: '<f8',
        shape: [2, 3],
        values: [1, 2, 3, 4, 5, 6],
      );
      final result = OodDetector.parseNpyForTesting(bytes, 'test');
      expect(result.shape, [2, 3]);
      expect(result.data, [1, 2, 3, 4, 5, 6]);
    });

    test('parses a scalar (0-d) array', () {
      final bytes = _buildNpy(descr: '<f8', shape: [], values: [0.4237]);
      final result = OodDetector.parseNpyForTesting(bytes, 'test');
      expect(result.shape, isEmpty);
      expect(result.data.single, closeTo(0.4237, 1e-9));
    });

    test('rejects bad magic bytes', () {
      final bytes = ByteData(16);
      expect(
        () => OodDetector.parseNpyForTesting(bytes, 'test'),
        throwsFormatException,
      );
    });

    test('rejects fortran-order arrays', () {
      final bytes = _buildNpy(
        descr: '<f8',
        shape: [2],
        values: [1, 2],
        fortranOrder: true,
      );
      expect(
        () => OodDetector.parseNpyForTesting(bytes, 'test'),
        throwsFormatException,
      );
    });

    test('rejects unsupported dtypes', () {
      final bytes = _buildNpy(descr: '<i4', shape: [1], values: [1]);
      expect(
        () => OodDetector.parseNpyForTesting(bytes, 'test'),
        throwsFormatException,
      );
    });
  });

  group('OodDetector.evaluate', () {
    // Builds a 76-element logit vector that makes the energy score
    // (-logSumExp) come out to an EXACT, hand-computable value: one logit
    // at `topValue`, every other one at -1000. After max-subtraction,
    // exp(otherLogit - topValue) underflows to exactly 0.0 in IEEE 754
    // double precision for any topValue in a realistic range (exp(-1000ish)
    // is many orders of magnitude below the smallest representable double),
    // so sumExp reduces to exactly 1.0, logSumExp reduces to exactly
    // topValue, and score = -topValue exactly — no floating-point slack to
    // account for, the same "isolate to a single term" trick the old
    // Mahalanobis-distance version of these tests used.
    List<double> logitsWithTop(int topIndex, double topValue) {
      final logits = List<double>.filled(OodDetector.logitLength, -1000.0);
      logits[topIndex] = topValue;
      return logits;
    }

    test('one dominant class gives an exact score of -topValue, and picks it as closest', () {
      final detector = OodDetector.fromThreshold(10.0);
      final result = detector.evaluate(logitsWithTop(5, 20.0));
      expect(result.closestClassIndex, 5);
      expect(result.score, -20.0);
      expect(result.zone, OodZone.known);
      expect(result.isKnown, isTrue);
    });

    test('score exactly at threshold - lowerMargin is borderline (inclusive)', () {
      const threshold = 10.0;
      final detector = OodDetector.fromThreshold(threshold);
      const lowerCeiling = threshold - OodDetector.lowerMargin;
      final result = detector.evaluate(logitsWithTop(0, -lowerCeiling));
      expect(result.score, closeTo(lowerCeiling, 1e-9));
      expect(result.zone, OodZone.borderline);
      expect(result.isKnown, isFalse);
      expect(result.isOutOfDistribution, isFalse);
    });

    test('score just below threshold - lowerMargin is known', () {
      const threshold = 10.0;
      final detector = OodDetector.fromThreshold(threshold);
      const lowerCeiling = threshold - OodDetector.lowerMargin;
      final result = detector.evaluate(logitsWithTop(0, -(lowerCeiling - 0.5)));
      expect(result.zone, OodZone.known);
    });

    test('score exactly at threshold is borderline (inclusive)', () {
      const threshold = 10.0;
      final detector = OodDetector.fromThreshold(threshold);
      final result = detector.evaluate(logitsWithTop(0, -threshold));
      expect(result.score, closeTo(threshold, 1e-9));
      expect(result.zone, OodZone.borderline);
      expect(result.isOutOfDistribution, isFalse);
    });

    test('score just above threshold is out-of-distribution', () {
      const threshold = 10.0;
      final detector = OodDetector.fromThreshold(threshold);
      final result = detector.evaluate(logitsWithTop(0, -(threshold + 0.5)));
      expect(result.zone, OodZone.outOfDistribution);
      expect(result.isKnown, isFalse);
      expect(result.isBorderline, isFalse);
    });

    test('uniform logits (maximum uncertainty) score higher than a dominant class', () {
      final detector = OodDetector.fromThreshold(10.0);
      final uniform = List<double>.filled(OodDetector.logitLength, 0.0);
      final dominant = logitsWithTop(0, 20.0);
      final uniformResult = detector.evaluate(uniform);
      final dominantResult = detector.evaluate(dominant);
      expect(uniformResult.score, greaterThan(dominantResult.score));
    });

    test('closestClassIndex is the argmax of the logits, independent of the zone', () {
      final detector = OodDetector.fromThreshold(10.0);
      final result = detector.evaluate(logitsWithTop(42, -50.0)); // deep in OOD territory
      expect(result.closestClassIndex, 42);
      expect(result.zone, OodZone.outOfDistribution);
    });

    test('secondClosestClassIndex is the runner-up logit, whichever side of closestClassIndex it falls on', () {
      final detector = OodDetector.fromThreshold(10.0);
      final logits = List<double>.filled(OodDetector.logitLength, -1000.0);
      logits[42] = 20.0;
      logits[7] = 5.0; // second-highest, index BEFORE the argmax
      final result = detector.evaluate(logits);
      expect(result.closestClassIndex, 42);
      expect(result.secondClosestClassIndex, 7);

      logits[7] = -1000.0;
      logits[60] = 5.0; // second-highest, index AFTER the argmax
      final result2 = detector.evaluate(logits);
      expect(result2.closestClassIndex, 42);
      expect(result2.secondClosestClassIndex, 60);
    });

    test('rejects a logits vector of the wrong length', () {
      final detector = OodDetector.fromThreshold(10.0);
      expect(
        () => detector.evaluate(List<double>.filled(10, 0.0)),
        throwsArgumentError,
      );
    });

    test('throws StateError when evaluated before loading', () {
      final detector = OodDetector();
      expect(
        () => detector.evaluate(List<double>.filled(OodDetector.logitLength, 0.0)),
        throwsStateError,
      );
    });

    test('fromThreshold marks the detector as loaded', () {
      final detector = OodDetector.fromThreshold(10.0);
      expect(detector.isLoaded, isTrue);
    });

    test('default constructor is not loaded until ready completes', () {
      final detector = OodDetector();
      expect(detector.isLoaded, isFalse);
    });
  });
}
