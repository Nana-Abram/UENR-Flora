// lib/core/species_provider.dart
import 'package:flutter/foundation.dart';
import '../models/plant_species.dart';
import '../services/species_repository.dart';

/// Single source of truth for live Supabase plant-species data, shared by
/// the Explorer screen and the Home screen's stats / recent / daily-fact
/// sections. Loaded once at app startup.
class SpeciesProvider extends ChangeNotifier {
  final SpeciesRepository _repository;
  SpeciesProvider(this._repository) {
    _load();
  }

  List<PlantSpecies> all = [];
  List<PlantSpecies> recent = [];
  bool loading = true;
  String? error;

  int get totalCount => all.length;

  /// A fact that rotates once per calendar day, picked from every species'
  /// did-you-know facts. Null while loading or if no facts exist yet.
  String? get dailyFact {
    final facts = all.expand((s) => s.didYouKnowFacts).toList();
    if (facts.isEmpty) return null;
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final index = dayIndex % facts.length;
    return facts[index < 0 ? index + facts.length : index];
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getAll(),
        _repository.getRecent(limit: 3),
      ]);
      all = results[0];
      recent = results[1];
      error = null;
    } catch (_) {
      error = 'Could not load plant species. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
