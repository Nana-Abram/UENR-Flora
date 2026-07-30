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

  /// All-time scan/health totals — computed server-side (see
  /// supabase/dashboard_aggregates.sql) instead of fetching every
  /// identification_logs row just to count/tally them client-side.
  Future<({int totalScans, int healthyCount, int unhealthyCount})> getDashboardTotals() async {
    final rows = await _client.rpc('dashboard_totals') as List;
    if (rows.isEmpty) return (totalScans: 0, healthyCount: 0, unhealthyCount: 0);
    final row = rows.first as Map<String, dynamic>;
    return (
      totalScans: (row['total_scans'] as num).toInt(),
      healthyCount: (row['healthy_count'] as num).toInt(),
      unhealthyCount: (row['unhealthy_count'] as num).toInt(),
    );
  }

  /// All-time average AI confidence per species id — same reasoning as
  /// [getDashboardTotals]: a GROUP BY in Postgres instead of averaging
  /// every row's confidence_score client-side.
  Future<Map<String, double>> getSpeciesAvgConfidence() async {
    final rows = await _client.rpc('species_avg_confidence') as List;
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['species_id'] as String: (r['avg_confidence'] as num).toDouble(),
    };
  }

  /// Raw scan timestamps for the dashboard's daily(14)/weekly(8)/monthly
  /// (Jan..now) charts. Those only ever need the current year's data (extra
  /// rows from before are simply filtered out by year), so 400 days is a
  /// safe cutoff that always covers Jan 1 of the current year plus the
  /// daily/weekly windows even in early January — bounded instead of
  /// fetching identification_logs' entire history.
  Future<List<DateTime>> getScanTimestampsSinceYearStart() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 400)).toIso8601String();
    final rows = await _client
        .from('identification_logs')
        .select('created_at')
        .gte('created_at', cutoff);
    return rows
        .map((r) => DateTime.tryParse(r['created_at'] as String? ?? ''))
        .whereType<DateTime>()
        .toList();
  }
}
