// lib/models/identification_result.dart
import '../core/constants.dart';
import 'plant_species.dart';

// Both classifier implementations only ever emit a binary healthy/
// unhealthy call from a single sigmoid threshold — there's no "the model
// wasn't sure" path, so an `unknown` value would only ever be dead code.
enum HealthStatus { healthy, unhealthy }

class ClassificationOutput {
  final int classIndex;
  final double confidence;
  final HealthStatus healthStatus;
  final double healthConfidence;

  /// The full per-class species probability distribution (76 entries) this
  /// [confidence]/[classIndex] were derived from — kept around so
  /// RejectionGate can compute entropy across the whole distribution
  /// instead of just looking at the single winning probability. When
  /// [classify] is called with more than one image, this is *their*
  /// weighted average, same as [confidence]/[classIndex].
  final List<double> probabilities;

  /// How many of the 5 test-time-augmentation passes (see
  /// TfjsClassifierService.classifyWithTta) picked the same top species as
  /// this result's [classIndex], from 0 to 5. Low agreement means the
  /// model's averaged confidence may be hiding real disagreement between
  /// augmented views of the same photo — see
  /// IdentificationResult.isLowConfidence, which treats ttaAgreement <= 2
  /// as low-confidence even when [confidence] alone would clear the
  /// threshold. When [classify] is called with more than one image, this
  /// is their confidence-weighted average (same weighting as
  /// [probabilities]), rounded to the nearest whole augmentation.
  final int ttaAgreement;

  /// The 76-dim raw pre-softmax logits from the species Dense head — the
  /// same values [probabilities] is the softmax of, kept separately because
  /// OodDetector's energy score needs the un-normalised magnitudes (softmax
  /// throws that away: it can't tell "genuinely confident" apart from
  /// "nothing else looked good either", since everything gets rescaled to
  /// sum to 1 either way — see OodDetector's own doc comment). When
  /// [classify] is called with more than one image, this is their *simple*
  /// arithmetic mean — deliberately not confidence-weighted like
  /// [probabilities]/[ttaAgreement], since nothing in the OOD design calls
  /// for weighting this quantity. Empty for anything that predates this
  /// field (e.g. MockClassifierService, or a caller that never populates
  /// it) — callers that need it must check for that rather than assume
  /// [OodDetector.logitLength] elements are always present.
  final List<double> logits;

  const ClassificationOutput({
    required this.classIndex,
    required this.confidence,
    required this.healthStatus,
    required this.healthConfidence,
    this.probabilities = const [],
    this.ttaAgreement = 5,
    this.logits = const [],
  });

  /// True when [confidence] clears the threshold *and* the 5 TTA passes
  /// mostly agreed on the winning species. A high averaged confidence can
  /// still hide real disagreement between augmented views (ttaAgreement <=
  /// 2 of 5) — when that happens this reports false even though
  /// [confidence] alone would clear [kConfidenceThreshold], so a
  /// self-disagreeing result gets the same "ask for another angle"
  /// treatment as a genuinely low-confidence one instead of being trusted
  /// at face value.
  bool get isReliable => confidence >= kConfidenceThreshold && ttaAgreement > 2;
}

class IdentificationResult {
  final ClassificationOutput classification;
  final PlantSpecies? species; // null means no matching Supabase row was found
  final String imagePath;

  /// How many photos were combined to reach this result (1–3, see
  /// ScanProvider.maxImages). Drives the results screen's "Confirmed in N
  /// scans" chip.
  final int attemptCount;

  const IdentificationResult({
    required this.classification,
    required this.species,
    required this.imagePath,
    this.attemptCount = 1,
  });

  /// True when the model was confident enough to show a result — see
  /// ClassificationOutput.isReliable for why this isn't just a confidence
  /// threshold check.
  bool get isConfident => classification.isReliable;

  /// True when every available attempt was used and confidence still
  /// never reached threshold — the results screen shows the best guess
  /// anyway rather than dead-ending, but flags it as unconfirmed.
  bool get isLowConfidence => !isConfident;
}
