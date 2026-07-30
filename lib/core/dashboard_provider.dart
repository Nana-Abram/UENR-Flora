// lib/core/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../services/species_repository.dart';

/// Derives the Home dashboard's scan-activity numbers (total scans, healthy %,
/// monthly chart) from real `identification_logs` rows, so the dashboard
/// doesn't show fabricated figures once the app has real usage.
///
/// Deliberately a separate provider from [SpeciesProvider], not a
/// consolidation candidate: this one is usage analytics derived from
/// `identification_logs` (server-aggregated — see
/// supabase/dashboard_aggregates.sql); SpeciesProvider is the species
/// content catalog from `plant_species`. A widget showing a species card
/// with a confidence badge reads both, the same way it might read two
/// unrelated providers for two unrelated facts about one entity — that's
/// not the same as the two providers overlapping in responsibility.
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

  static const dailyWindowSize = 14;
  static const weeklyWindowSize = 8;

  List<int> dailyCounts = []; // last 14 days, oldest..today
  List<DateTime> dailyDates = [];
  double? dayOverDayDelta; // % change vs yesterday, null if not computable

  List<int> weeklyCounts = []; // last 8 weeks, oldest..this week
  List<DateTime> weeklyStarts = []; // Monday of each bucket
  double? weekOverWeekDelta; // % change vs previous week, null if not computable

  /// Average AI confidence (0..1) per species id, derived from real scan
  /// history — null/absent for species that have never been scanned yet.
  Map<String, double> avgConfidenceBySpecies = {};
  double? confidenceFor(String speciesId) => avgConfidenceBySpecies[speciesId];

  Future<void> reload() => _load();

  Future<void> _load() async {
    loading = true;
    notifyListeners();
    try {
      // All-time totals/averages are computed server-side (see
      // supabase/dashboard_aggregates.sql) — only the chart-bucketing
      // timestamps are fetched raw, and only for recent history.
      final results = await Future.wait([
        _repository.getDashboardTotals(),
        _repository.getSpeciesAvgConfidence(),
        _repository.getScanTimestampsSinceYearStart(),
      ]);
      final totals = results[0] as ({int totalScans, int healthyCount, int unhealthyCount});
      avgConfidenceBySpecies = results[1] as Map<String, double>;
      final timestamps = results[2] as List<DateTime>;

      totalScans = totals.totalScans;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      scansThisWeek = timestamps.where((t) => t.isAfter(weekAgo)).length;
      scansToday = timestamps
          .where((t) => t.year == now.year && t.month == now.month && t.day == now.day)
          .length;

      final healthTotal = totals.healthyCount + totals.unhealthyCount;
      healthyPercent = healthTotal > 0 ? totals.healthyCount / healthTotal * 100 : null;

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

      final today = DateTime(now.year, now.month, now.day);
      dailyDates = List.generate(
          dailyWindowSize, (i) => today.subtract(Duration(days: dailyWindowSize - 1 - i)));
      dailyCounts = dailyDates
          .map((d) => timestamps
              .where((t) => t.year == d.year && t.month == d.month && t.day == d.day)
              .length)
          .toList();
      final todayCount = dailyCounts.last;
      final yesterdayCount = dailyCounts[dailyCounts.length - 2];
      dayOverDayDelta =
          yesterdayCount > 0 ? (todayCount - yesterdayCount) / yesterdayCount * 100 : null;

      final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
      weeklyStarts = List.generate(
          weeklyWindowSize, (i) => currentWeekStart.subtract(Duration(days: (weeklyWindowSize - 1 - i) * 7)));
      weeklyCounts = weeklyStarts.map((start) {
        final end = start.add(const Duration(days: 7));
        return timestamps.where((t) => !t.isBefore(start) && t.isBefore(end)).length;
      }).toList();
      final thisWeekCount = weeklyCounts.last;
      final lastWeekCount = weeklyCounts[weeklyCounts.length - 2];
      weekOverWeekDelta =
          lastWeekCount > 0 ? (thisWeekCount - lastWeekCount) / lastWeekCount * 100 : null;

    } catch (_) {
      // Leave defaults (zeros) — dashboard sections render their loading/empty states.
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
