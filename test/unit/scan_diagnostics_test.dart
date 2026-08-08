import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/core/constants.dart';
import 'package:plantid_app/features/scan/services/ood_detector.dart';
import 'package:plantid_app/features/scan/services/rejection_gate.dart';
import 'package:plantid_app/features/scan/services/scan_diagnostics.dart';
import 'package:plantid_app/models/identification_result.dart';
import 'package:plantid_app/models/plant_species.dart';

const _species = PlantSpecies(
  id: 'sp-42',
  scientificName: 'Testus plantus',
  commonName: 'Test Plant',
  modelClassIndex: 42,
);

/// A realistic-looking 76-class distribution: [named] are the top few
/// classes' exact probabilities, remainder spread evenly — mirrors
/// rejection_gate_test.dart's own fixture builder.
List<double> _probs(List<double> named, {int total = RejectionGate.numClasses}) {
  final remainingCount = total - named.length;
  final remainingTotal = 1.0 - named.fold(0.0, (a, b) => a + b);
  final tail = remainingCount > 0 ? remainingTotal / remainingCount : 0.0;
  return [...named, ...List.filled(remainingCount, tail)];
}

void main() {
  group('ScanDiagnostics.build', () {
    final gate = RejectionGate();
    final probs = _probs([0.82, 0.07, 0.04]);
    final output = ClassificationOutput(
      classIndex: 0,
      confidence: probs[0],
      healthStatus: HealthStatus.healthy,
      healthConfidence: 0.9,
      probabilities: probs,
      ttaAgreement: 4,
    );
    const oodResult = OodResult(
      zone: OodZone.known,
      score: 12.5,
      threshold: 44.0,
      closestClassIndex: 42,
      secondClosestClassIndex: 7,
    );

    test('maps every field to its documented wire key', () {
      final result = ScanDiagnostics.build(
        decision: ScanDecision.known,
        output: output,
        oodResult: oodResult,
        gate: gate,
        closestSpecies: _species,
        claudeUsed: true,
        claudeChangedPrediction: false,
      );

      expect(result['decision'], 'known');
      expect(result['ood_distance'], 12.5);
      expect(result['threshold'], 44.0);
      expect(result['entropy'], gate.computeEntropy(probs));
      expect(result['confidence'], probs[0]);
      expect(result['top3_probability'], gate.computeTopKConcentration(probs));
      expect(result['tta_agreement'], 4);
      expect(result['closest_species'], 'sp-42');
      expect(result['model_version'], kModelVersion);
      expect(result['claude_used'], true);
      expect(result['claude_changed_prediction'], false);
    });

    test('closest_species is null when no species resolved', () {
      final result = ScanDiagnostics.build(
        decision: ScanDecision.ood,
        output: output,
        oodResult: oodResult,
        gate: gate,
        closestSpecies: null,
        claudeUsed: false,
        claudeChangedPrediction: false,
      );
      expect(result['closest_species'], isNull);
    });

    test('decision wire values are exactly known|borderline|ood', () {
      for (final entry in {
        ScanDecision.known: 'known',
        ScanDecision.borderline: 'borderline',
        ScanDecision.ood: 'ood',
      }.entries) {
        final result = ScanDiagnostics.build(
          decision: entry.key,
          output: output,
          oodResult: oodResult,
          gate: gate,
          closestSpecies: null,
          claudeUsed: false,
          claudeChangedPrediction: false,
        );
        expect(result['decision'], entry.value);
      }
    });
  });
}
