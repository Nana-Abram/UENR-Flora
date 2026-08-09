// lib/core/species_text.dart
import '../models/identification_result.dart';
import '../models/plant_species.dart';

/// The factual (name/habit/origin/height) sentence at the start of
/// [speciesOverviewSummary], without the trailing `ecological_importance`
/// prose — used by the detail modal's Overview tab, which shows that prose
/// as a separate [BulletList] instead of appending it to this sentence.
String speciesOverviewIntro(PlantSpecies species) {
  final habit = species.growthHabit ?? 'plant';
  final origin = species.origin;
  final height = species.heightRange;
  final buffer = StringBuffer(
      '${species.commonName} is a $habit${origin != null ? ' native to $origin' : ''}');
  if (height != null) buffer.write(', typically growing $height');
  buffer.write('.');
  return buffer.toString();
}

/// Synthesizes a short intro paragraph from real species fields — there's
/// no single freeform "description" column in plant_species. Used by the
/// Explorer's list view (see [speciesOverviewIntro] for the detail modal's
/// Overview tab, which needs the two halves separately).
String speciesOverviewSummary(PlantSpecies species) {
  final intro = speciesOverviewIntro(species);
  if (species.ecologicalImportance == null) return intro;
  return '$intro ${species.ecologicalImportance}';
}

/// Builds a full spoken narration covering overview, ecology, benefits, and
/// care — used by [ReadAloudButton] on the plant detail modal and results
/// screen so the same species reads the same way in either place.
String speciesFullReadText(PlantSpecies species) {
  final buffer = StringBuffer()
    ..writeln('${species.commonName}, scientific name ${species.scientificName}.')
    ..writeln(speciesOverviewSummary(species));
  if (species.localNameTwi != null) {
    buffer.writeln('Known locally as ${species.localNameTwi}.');
  }
  if (species.familyName != null) {
    buffer.writeln('Family: ${species.familyName}.');
  }
  buffer
    ..writeln('Ecology. ${species.ecologicalImportance ?? 'Supports local wildlife.'}')
    ..writeln('Environmental benefits. ${species.environmentalBenefits ?? 'Contributes to environmental health.'}')
    ..writeln('Medicinal uses. ${species.medicinalUses ?? 'No documented medicinal uses.'}')
    ..writeln('Economic importance. ${species.economicImportance ?? 'No documented economic importance.'}')
    ..writeln('Care tips. Water: ${species.waterRequirements ?? 'Moderate watering.'} '
        'Sunlight: ${species.sunlightRequirements ?? 'Full sun preferred.'} '
        'Soil: ${species.soilPreference ?? 'Well-draining soil.'}');
  if (species.didYouKnowFacts.isNotEmpty) {
    buffer.writeln('Did you know? ${species.didYouKnowFacts.first}');
  }
  return buffer.toString();
}

/// Same as [speciesFullReadText] but prefixed with the scan outcome — used
/// on the results screen where a classification is available.
String identificationReadText(PlantSpecies species, ClassificationOutput cls) {
  final health = switch (cls.healthStatus) {
    HealthStatus.healthy => 'The plant appears healthy.',
    HealthStatus.unhealthy => 'The plant appears unhealthy and may need care.',
  };
  final confidence = 'Identified with ${(cls.confidence * 100).round()} percent confidence.';
  return '$confidence $health ${speciesFullReadText(species)}';
}
