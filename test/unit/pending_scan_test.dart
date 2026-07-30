import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/scan/pending_scan.dart';
import 'package:plantid_app/models/identification_result.dart';

void main() {
  group('PendingScan JSON round-trip', () {
    test('a confident match survives toJson/fromJson unchanged', () {
      final original = PendingScan(
        classIndex: 12,
        confidence: 0.87,
        healthStatus: HealthStatus.healthy,
        healthConfidence: 0.93,
        speciesId: 'neem-id',
        isCorrect: true,
        queuedAt: DateTime.utc(2026, 7, 27, 10, 30),
      );

      final restored = PendingScan.fromJson(original.toJson());

      expect(restored.classIndex, original.classIndex);
      expect(restored.confidence, original.confidence);
      expect(restored.healthStatus, original.healthStatus);
      expect(restored.healthConfidence, original.healthConfidence);
      expect(restored.speciesId, original.speciesId);
      expect(restored.isCorrect, original.isCorrect);
      expect(restored.queuedAt, original.queuedAt);
    });

    test('an unmatched (low-confidence) scan keeps a null speciesId', () {
      final original = PendingScan.fromClassification(
        classification: const ClassificationOutput(
          classIndex: 5,
          confidence: 0.4,
          healthStatus: HealthStatus.unhealthy,
          healthConfidence: 0.6,
        ),
        speciesId: null,
        isCorrect: false,
      );

      final restored = PendingScan.fromJson(original.toJson());

      expect(restored.speciesId, isNull);
      expect(restored.isCorrect, isFalse);
      expect(restored.healthStatus, HealthStatus.unhealthy);
    });

    test('fromClassification carries classification fields through unchanged', () {
      const classification = ClassificationOutput(
        classIndex: 3,
        confidence: 0.91,
        healthStatus: HealthStatus.healthy,
        healthConfidence: 0.88,
      );
      final scan = PendingScan.fromClassification(
        classification: classification,
        speciesId: 'abc',
        isCorrect: true,
      );

      expect(scan.classification.classIndex, classification.classIndex);
      expect(scan.classification.confidence, classification.confidence);
      expect(scan.classification.healthStatus, classification.healthStatus);
      expect(scan.classification.healthConfidence, classification.healthConfidence);
    });
  });
}
