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

  const ClassificationOutput({
    required this.classIndex,
    required this.confidence,
    required this.healthStatus,
    required this.healthConfidence,
  });
}

class IdentificationResult {
  final ClassificationOutput classification;
  final PlantSpecies? species; // null means no matching Supabase row was found
  final String imagePath;

  const IdentificationResult({
    required this.classification,
    required this.species,
    required this.imagePath,
  });

  /// True when the model was confident enough to show a result.
  bool get isConfident =>
      classification.confidence >= kConfidenceThreshold;
}
