// lib/models/identification_result.dart
import '../core/constants.dart';

enum HealthStatus { healthy, unhealthy, unknown }

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
  final PlantSpeciesSimple? species; // null means below-threshold result
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

/// Lightweight species data used by the Results screen before the full
/// Supabase model is connected in step 13.
class PlantSpeciesSimple {
  final String id;
  final String commonName;
  final String scientificName;
  final String? localNameTwi;
  final String? familyName;
  final String? growthHabit;
  final String? leafType;
  final String? floweringSeason;
  final String? origin;
  final String? ecologicalImportance;
  final String? environmentalBenefits;
  final String? medicinalUses;
  final String? economicImportance;
  final String? waterRequirements;
  final String? sunlightRequirements;
  final String? soilPreference;
  final List<String> didYouKnowFacts;
  final int modelClassIndex;

  const PlantSpeciesSimple({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.modelClassIndex,
    this.localNameTwi,
    this.familyName,
    this.growthHabit,
    this.leafType,
    this.floweringSeason,
    this.origin,
    this.ecologicalImportance,
    this.environmentalBenefits,
    this.medicinalUses,
    this.economicImportance,
    this.waterRequirements,
    this.sunlightRequirements,
    this.soilPreference,
    this.didYouKnowFacts = const [],
  });

  // Hard-coded sample for testing before Supabase is live
  static const PlantSpeciesSimple mangoSample = PlantSpeciesSimple(
    id: 'sample-mango',
    commonName: 'Mango Tree',
    scientificName: 'Mangifera indica',
    localNameTwi: 'Mangoro',
    familyName: 'Anacardiaceae',
    growthHabit: 'Tree (10–30 m)',
    leafType: 'Simple, lanceolate',
    floweringSeason: 'Jan – Apr',
    origin: 'South Asia',
    ecologicalImportance:
        'Fruit feeds birds and fruit bats; canopy shelters campus wildlife.',
    environmentalBenefits:
        'Reduces surface temperature by up to 4°C; absorbs 5–22 kg CO₂ annually.',
    medicinalUses:
        'Leaves used in traditional medicine for managing diabetes. '
        'Bark has antimicrobial properties in Ghanaian herbal practice.',
    economicImportance:
        'Ghana\'s third most important fruit crop. Brong-Ahafo Region is '
        'a primary production zone.',
    waterRequirements: 'Moderate — water deeply fortnightly in dry season. '
        'Drought-tolerant once established.',
    sunlightRequirements: 'Full sun — minimum 6 hours of direct sunlight daily.',
    soilPreference: 'Well-draining loamy soil, pH 5.5–7.5.',
    modelClassIndex: 1,
    didYouKnowFacts: [
      'Mango trees can live over 300 years and continue bearing fruit '
          'throughout their entire lifespan.',
      'The Brong-Ahafo Region — where UENR is located — is one of Ghana\'s '
          'primary mango-producing zones.',
      'In Twi tradition, the "Mangoro" tree is a social gathering place — '
          'campus trees carry cultural significance beyond their ecology.',
    ],
  );
}
