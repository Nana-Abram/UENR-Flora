// lib/services/species_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant_species.dart';

class SpeciesRepository {
  final SupabaseClient _client;
  SpeciesRepository(this._client);

  static const String _select = '''
    *,
    plant_families ( name ),
    did_you_know_facts ( fact_text ),
    species_images ( image_url, display_order )
  ''';

  /// Returns the species whose model_class_index matches the classifier output.
  /// Returns null when no match is found (treat same as below-threshold).
  Future<PlantSpecies?> getByClassIndex(int classIndex) async {
    final row = await _client
        .from('plant_species')
        .select(_select)
        .eq('model_class_index', classIndex)
        .maybeSingle();
    return row != null ? PlantSpecies.fromMap(row) : null;
  }

  /// Returns all species ordered by common name — used by the Explorer screen.
  Future<List<PlantSpecies>> getAll() async {
    final rows = await _client
        .from('plant_species')
        .select(_select)
        .order('common_name');
    return rows.map(PlantSpecies.fromMap).toList();
  }

  /// Returns the most recently identified species — used by Home recent scans.
  Future<List<PlantSpecies>> getRecent({int limit = 3}) async {
    final logs = await _client
        .from('identification_logs')
        .select('predicted_species_id')
        .not('predicted_species_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);

    final ids = logs
        .map<String>((l) => l['predicted_species_id'] as String)
        .toSet()
        .toList();

    if (ids.isEmpty) return [];

    final rows = await _client
        .from('plant_species')
        .select(_select)
        .inFilter('id', ids);
    return rows.map(PlantSpecies.fromMap).toList();
  }

  /// Returns every identification log's timestamp, health status, predicted
  /// species, and confidence score — used by the Home dashboard (total scans,
  /// healthy %, monthly scan-activity chart) and the Explorer (per-species
  /// average AI confidence), without needing a dedicated aggregation endpoint.
  Future<List<Map<String, dynamic>>> getScanLogs() async {
    final rows = await _client
        .from('identification_logs')
        .select('created_at, health_status, predicted_species_id, confidence_score');
    return rows.cast<Map<String, dynamic>>();
  }
}
