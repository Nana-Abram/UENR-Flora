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

  const ClassificationOutput({
    required this.classIndex,
    required this.confidence,
    required this.healthStatus,
    required this.healthConfidence,
    this.probabilities = const [],
  });
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

  /// True when the model was confident enough to show a result.
  bool get isConfident =>
      classification.confidence >= kConfidenceThreshold;

  /// True when every available attempt was used and confidence still
  /// never reached threshold — the results screen shows the best guess
  /// anyway rather than dead-ending, but flags it as unconfirmed.
  bool get isLowConfidence => !isConfident;
}
