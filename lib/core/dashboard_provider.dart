// lib/core/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../services/species_repository.dart';

/// Derives the Home dashboard's scan-activity numbers (total scans, healthy %,
/// monthly chart) from real `identification_logs` rows, so the dashboard
/// doesn't show fabricated figures once the app has real usage.
class DashboardProvider extends ChangeNotifier {
  final SpeciesRepository _repository;
  DashboardProvider(this._repository) {
    _load();
  }

  bool loading = true;
  int totalScans = 0;
  int scansThisWeek = 0;
  int scansToday = 0;
  double? healthyPercent; // null when there's no health data yet
  List<int> monthlyCounts = []; // Jan..current month of this year
  double? monthOverMonthDelta; // % change vs previous month, null if not computable

  /// Average AI confidence (0..1) per species id, derived from real scan
  /// history — null/absent for species that have never been scanned yet.
  Map<String, double> avgConfidenceBySpecies = {};
  double? confidenceFor(String speciesId) => avgConfidenceBySpecies[speciesId];

  Future<void> reload() => _load();

  Future<void> _load() async {
    loading = true;
    notifyListeners();
    try {
      final logs = await _repository.getScanLogs();
      final timestamps = logs
          .map((l) => DateTime.tryParse(l['created_at'] as String? ?? ''))
          .whereType<DateTime>()
          .toList();

      totalScans = timestamps.length;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      scansThisWeek = timestamps.where((t) => t.isAfter(weekAgo)).length;
      scansToday = timestamps
          .where((t) => t.year == now.year && t.month == now.month && t.day == now.day)
          .length;

      final healthCounts = <String, int>{};
      for (final l in logs) {
        final status = l['health_status'] as String?;
        if (status == null || status == 'unknown') continue;
        healthCounts[status] = (healthCounts[status] ?? 0) + 1;
      }
      final healthTotal = healthCounts.values.fold(0, (a, b) => a + b);
      healthyPercent = healthTotal > 0
          ? (healthCounts['healthy'] ?? 0) / healthTotal * 100
          : null;

      final currentMonth = now.month;
      final counts = List<int>.filled(currentMonth, 0);
      for (final t in timestamps) {
        if (t.year == now.year && t.month <= currentMonth) {
          counts[t.month - 1]++;
        }
      }
      monthlyCounts = counts;

      if (currentMonth >= 2) {
        final last = counts[currentMonth - 1];
        final prev = counts[currentMonth - 2];
        monthOverMonthDelta = prev > 0 ? (last - prev) / prev * 100 : null;
      } else {
        monthOverMonthDelta = null;
      }

      final confSums = <String, double>{};
      final confCounts = <String, int>{};
      for (final l in logs) {
        final id = l['predicted_species_id'] as String?;
        final conf = (l['confidence_score'] as num?)?.toDouble();
        if (id == null || conf == null) continue;
        confSums[id] = (confSums[id] ?? 0) + conf;
        confCounts[id] = (confCounts[id] ?? 0) + 1;
      }
      avgConfidenceBySpecies = {
        for (final id in confSums.keys) id: confSums[id]! / confCounts[id]!,
      };
    } catch (_) {
      // Leave defaults (zeros) — dashboard sections render their loading/empty states.
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
