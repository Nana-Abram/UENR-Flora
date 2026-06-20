// lib/models/plant_species.dart

/// Full species record returned by Supabase, with family name and facts joined.
class PlantSpecies {
  final String id;
  final String scientificName;
  final String commonName;
  final String? localNameTwi;
  final String? familyName;
  final String? growthHabit;
  final String? heightRange;
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
  final String? referenceImageUrl;
  final int modelClassIndex;
  final List<String> didYouKnowFacts;

  const PlantSpecies({
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.modelClassIndex,
    this.localNameTwi,
    this.familyName,
    this.growthHabit,
    this.heightRange,
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
    this.referenceImageUrl,
    this.didYouKnowFacts = const [],
  });

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    final factsRaw  = map['did_you_know_facts'] as List<dynamic>? ?? const [];
    final familyRaw = map['plant_families'] as Map<String, dynamic>?;

    return PlantSpecies(
      id:                    map['id'] as String,
      scientificName:        map['scientific_name'] as String,
      commonName:            map['common_name'] as String,
      localNameTwi:          map['local_name_twi'] as String?,
      familyName:            familyRaw?['name'] as String?,
      growthHabit:           map['growth_habit'] as String?,
      heightRange:           map['height_range'] as String?,
      leafType:              map['leaf_type'] as String?,
      floweringSeason:       map['flowering_season'] as String?,
      origin:                map['origin'] as String?,
      ecologicalImportance:  map['ecological_importance'] as String?,
      environmentalBenefits: map['environmental_benefits'] as String?,
      medicinalUses:         map['medicinal_uses'] as String?,
      economicImportance:    map['economic_importance'] as String?,
      waterRequirements:     map['water_requirements'] as String?,
      sunlightRequirements:  map['sunlight_requirements'] as String?,
      soilPreference:        map['soil_preference'] as String?,
      referenceImageUrl:     map['reference_image_url'] as String?,
      modelClassIndex:       map['model_class_index'] as int,
      didYouKnowFacts: factsRaw
          .map((f) => (f as Map<String, dynamic>)['fact_text'] as String)
          .toList(),
    );
  }
}
