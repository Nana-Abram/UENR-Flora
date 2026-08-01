// lib/core/species_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/plant_species.dart';
import '../services/persistent_cache.dart';
import '../services/species_repository.dart';

/// Single source of truth for live Supabase plant-species data, shared by
/// the Explorer screen and the Home screen's stats / recent / daily-fact
/// sections. Loaded once at app startup.
///
/// See [DashboardProvider] for why that's a separate provider rather than
/// merged into this one — this is the species content catalog
/// (`plant_species`), that's scan-usage analytics (`identification_logs`).
class SpeciesProvider extends ChangeNotifier {
  static const _cacheKey = 'species_cache_v1';

  final SpeciesRepository _repository;
  final PersistentCache _cache = PersistentCache();

  SpeciesProvider(this._repository) {
    _init();
  }

  /// Shows whatever's on disk instantly (if present and not expired), then
  /// always follows up with a real network load — the disk copy is a
  /// display shortcut, never a substitute for a real refresh, so species
  /// added/edited in Supabase since the cache was written still show up.
  Future<void> _init() async {
    final cached = await _cache.read(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        all = cached.map(PlantSpecies.fromJson).toList();
        _allFacts = all.expand((s) => s.didYouKnowFacts).toList();
        loading = false;
        notifyListeners();
      } catch (_) {
        // Incompatible cached shape (e.g. a field was renamed) — ignore and
        // fall through to the real load below.
        all = [];
      }
    }
    await _load();
  }

  List<PlantSpecies> all = [];
  List<PlantSpecies> recent = [];
  bool loading = true;
  String? error;

  int get totalCount => all.length;

  /// Flattened once per [_load] rather than re-derived from [all] on every
  /// [dailyFact] read (every rebuild that touches it).
  List<String> _allFacts = [];

  /// A fact that rotates once per calendar day, picked from every species'
  /// did-you-know facts. Null while loading or if no facts exist yet.
  String? get dailyFact {
    if (_allFacts.isEmpty) return null;
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final index = dayIndex % _allFacts.length;
    return _allFacts[index < 0 ? index + _allFacts.length : index];
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    // Nothing on screen yet (no cache hit) — show the full loading state.
    // Otherwise this is a silent background refresh behind already-visible
    // cached data, so don't blank the screen with a spinner for it.
    final hadData = all.isNotEmpty;
    if (!hadData) {
      loading = true;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _repository.getAll(),
        _repository.getRecent(limit: 3),
      ]);
      all = results[0];
      recent = results[1];
      _allFacts = all.expand((s) => s.didYouKnowFacts).toList();
      error = null;
      unawaited(_cache.write(_cacheKey, all.map((s) => s.toJson()).toList()));
    } catch (_) {
      // A failed background refresh just leaves the cached copy on screen —
      // only surface the error banner when there was nothing to fall back on.
      if (!hadData) {
        error = 'Could not load plant species. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
