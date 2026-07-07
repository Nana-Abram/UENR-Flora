// lib/core/species_text.dart
import '../models/plant_species.dart';

/// Synthesizes a short intro paragraph from real species fields — there's
/// no single freeform "description" column in plant_species. Shared by the
/// detail modal's Overview tab and the Explorer's list view.
String speciesOverviewSummary(PlantSpecies species) {
  final habit = species.growthHabit ?? 'plant';
  final origin = species.origin;
  final height = species.heightRange;
  final buffer = StringBuffer(
      '${species.commonName} is a $habit${origin != null ? ' native to $origin' : ''}');
  if (height != null) buffer.write(', typically growing $height');
  buffer.write('.');
  if (species.ecologicalImportance != null) {
    buffer.write(' ${species.ecologicalImportance}');
  }
  return buffer.toString();
}
