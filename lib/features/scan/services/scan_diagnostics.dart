// lib/features/scan/services/scan_diagnostics.dart
import '../../../core/constants.dart';
import '../../../models/identification_result.dart';
import '../../../models/plant_species.dart';
import 'ood_detector.dart';
import 'rejection_gate.dart';

/// One of the three OOD-driven outcomes a scan can land on — see
/// scan_screen.dart's _runIdentification decision engine and OodDetector's
/// own doc comment for what separates them.
enum ScanDecision { known, borderline, ood }

extension on ScanDecision {
  String get wireValue => switch (this) {
        ScanDecision.known => 'known',
        ScanDecision.borderline => 'borderline',
        ScanDecision.ood => 'ood',
      };
}

/// Builds the structured per-scan diagnostics payload stored in
/// identification_logs.model_diagnostics (every decision) and reused
/// verbatim for unknown_plant_reports' ood_distance/ood_threshold/entropy/
/// raw_confidence/top3_probability/tta_agreement/closest_species/
/// model_version columns (see UnknownPlantReporter) — kept as a single pure
/// function so both destinations always agree on the numbers for the same
/// scan, instead of two independently-computed versions drifting apart.
/// Intended for future model improvement and OodDetector threshold tuning,
/// never read back by the app itself.
class ScanDiagnostics {
  const ScanDiagnostics._();

  /// [gate] is only used for its (stateless) [RejectionGate.computeEntropy]/
  /// [RejectionGate.computeTopKConcentration] helpers — computed here over
  /// the same combined multi-photo [output] the confidence/OOD decision
  /// itself used, not the single-photo distribution RejectionGate's own
  /// Layer 3 screen evaluates.
  static Map<String, dynamic> build({
    required ScanDecision decision,
    required ClassificationOutput output,
    required OodResult oodResult,
    required RejectionGate gate,
    required PlantSpecies? closestSpecies,
    required bool claudeUsed,
    required bool claudeChangedPrediction,
  }) {
    return {
      'decision': decision.wireValue,
      // Key kept as `ood_distance` for continuity with rows logged before
      // 2026-08-07's switch from a Mahalanobis distance to an energy-based
      // score (see OodDetector's own doc comment) — same underlying column,
      // different-scale numbers before/after that date.
      'ood_distance': oodResult.score,
      'threshold': oodResult.threshold,
      'entropy': gate.computeEntropy(output.probabilities),
      'confidence': output.confidence,
      'top3_probability': gate.computeTopKConcentration(output.probabilities),
      'tta_agreement': output.ttaAgreement,
      'closest_species': closestSpecies?.id,
      'model_version': kModelVersion,
      'claude_used': claudeUsed,
      'claude_changed_prediction': claudeChangedPrediction,
    };
  }
}
