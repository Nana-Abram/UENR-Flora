// lib/models/plant_species.dart
import '../core/json_utils.dart';

/// Full species record returned by Supabase, with family name and facts joined.
class PlantSpecies {
  final String id;
  final String scientificName;
  final String commonName;
  final String? localNameTwi;
  final String? familyName;
  final String? growthHabit;
  final String? growthType; // category used for Explorer filtering: trees / shrubs / herbs / ornamental
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
  final List<String> galleryImageUrls;

  // ── Morphology fields (added for the background Claude "second opinion"
  // prompt — see BackgroundIdentifierService/SpeciesMetadata) ────────────
  // Not shown anywhere in the app's own UI today; exist purely to give
  // Claude richer text to compare a photo against, beyond leafType/
  // familyName/growthHabit alone.
  final String? leafArrangement;
  final String? leafMargin;
  final String? venation;
  final String? leafShape;
  final String? leafTexture;
  final String? flowerDescription;
  final String? fruitDescription;
  final String? barkDescription;

  /// WHEN/HOW/WHERE planting guidance for `growth_type == 'ornamental'`
  /// species — see supabase/ornamental_planting_advice.sql and
  /// PlantingGuideTab. Null for non-ornamental species, and for any
  /// ornamental species that hasn't had advice authored for it yet.
  final String? plantingAdvice;

  const PlantSpecies({
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.modelClassIndex,
    this.localNameTwi,
    this.familyName,
    this.growthHabit,
    this.growthType,
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
    this.galleryImageUrls = const [],
    this.leafArrangement,
    this.leafMargin,
    this.venation,
    this.leafShape,
    this.leafTexture,
    this.flowerDescription,
    this.fruitDescription,
    this.barkDescription,
    this.plantingAdvice,
  });

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    const table = 'plant_species';
    final factsRaw   = map['did_you_know_facts'] as List<dynamic>? ?? const [];
    final familyRaw  = map['plant_families'] as Map<String, dynamic>?;
    final imagesRaw  = map['species_images'] as List<dynamic>? ?? const [];
    final sortedImages = List<Map<String, dynamic>>.from(imagesRaw)
      ..sort((a, b) => ((a['display_order'] as int?) ?? 0)
          .compareTo((b['display_order'] as int?) ?? 0));

    return PlantSpecies(
      id:                    requireField<String>(map, 'id', table: table),
      scientificName:        requireField<String>(map, 'scientific_name', table: table),
      commonName:            requireField<String>(map, 'common_name', table: table),
      localNameTwi:          map['local_name_twi'] as String?,
      familyName:            familyRaw?['name'] as String?,
      growthHabit:           map['growth_habit'] as String?,
      growthType:            map['growth_type'] as String?,
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
      modelClassIndex:       requireField<int>(map, 'model_class_index', table: table),
      leafArrangement:       map['leaf_arrangement'] as String?,
      leafMargin:            map['leaf_margin'] as String?,
      venation:              map['venation'] as String?,
      leafShape:             map['leaf_shape'] as String?,
      leafTexture:           map['leaf_texture'] as String?,
      flowerDescription:     map['flower_description'] as String?,
      fruitDescription:      map['fruit_description'] as String?,
      barkDescription:       map['bark_description'] as String?,
      plantingAdvice:        map['planting_advice'] as String?,
      didYouKnowFacts: factsRaw
          .map((f) => requireField<String>(f as Map<String, dynamic>, 'fact_text',
              table: 'plant_facts'))
          .toList(),
      galleryImageUrls: sortedImages
          .map((img) => requireField<String>(img, 'image_url', table: 'species_images'))
          .toList(),
    );
  }

  /// Flat (non-nested) JSON used by [PersistentCache] — deliberately not
  /// the same shape as the Supabase row [fromMap] expects (that shape has
  /// `plant_families`/`species_images` nested join objects that only exist
  /// mid-query, not once flattened into this class's fields).
  Map<String, dynamic> toJson() => {
        'id': id,
        'scientific_name': scientificName,
        'common_name': commonName,
        'local_name_twi': localNameTwi,
        'family_name': familyName,
        'growth_habit': growthHabit,
        'growth_type': growthType,
        'height_range': heightRange,
        'leaf_type': leafType,
        'flowering_season': floweringSeason,
        'origin': origin,
        'ecological_importance': ecologicalImportance,
        'environmental_benefits': environmentalBenefits,
        'medicinal_uses': medicinalUses,
        'economic_importance': economicImportance,
        'water_requirements': waterRequirements,
        'sunlight_requirements': sunlightRequirements,
        'soil_preference': soilPreference,
        'reference_image_url': referenceImageUrl,
        'model_class_index': modelClassIndex,
        'did_you_know_facts': didYouKnowFacts,
        'gallery_image_urls': galleryImageUrls,
        'leaf_arrangement': leafArrangement,
        'leaf_margin': leafMargin,
        'venation': venation,
        'leaf_shape': leafShape,
        'leaf_texture': leafTexture,
        'flower_description': flowerDescription,
        'fruit_description': fruitDescription,
        'bark_description': barkDescription,
        'planting_advice': plantingAdvice,
      };

  factory PlantSpecies.fromJson(Map<String, dynamic> map) => PlantSpecies(
        id: map['id'] as String,
        scientificName: map['scientific_name'] as String,
        commonName: map['common_name'] as String,
        localNameTwi: map['local_name_twi'] as String?,
        familyName: map['family_name'] as String?,
        growthHabit: map['growth_habit'] as String?,
        growthType: map['growth_type'] as String?,
        heightRange: map['height_range'] as String?,
        leafType: map['leaf_type'] as String?,
        floweringSeason: map['flowering_season'] as String?,
        origin: map['origin'] as String?,
        ecologicalImportance: map['ecological_importance'] as String?,
        environmentalBenefits: map['environmental_benefits'] as String?,
        medicinalUses: map['medicinal_uses'] as String?,
        economicImportance: map['economic_importance'] as String?,
        waterRequirements: map['water_requirements'] as String?,
        sunlightRequirements: map['sunlight_requirements'] as String?,
        soilPreference: map['soil_preference'] as String?,
        referenceImageUrl: map['reference_image_url'] as String?,
        modelClassIndex: map['model_class_index'] as int,
        didYouKnowFacts:
            (map['did_you_know_facts'] as List<dynamic>?)?.cast<String>() ?? const [],
        galleryImageUrls:
            (map['gallery_image_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
        leafArrangement: map['leaf_arrangement'] as String?,
        leafMargin: map['leaf_margin'] as String?,
        venation: map['venation'] as String?,
        leafShape: map['leaf_shape'] as String?,
        leafTexture: map['leaf_texture'] as String?,
        flowerDescription: map['flower_description'] as String?,
        fruitDescription: map['fruit_description'] as String?,
        barkDescription: map['bark_description'] as String?,
        plantingAdvice: map['planting_advice'] as String?,
      );
}
