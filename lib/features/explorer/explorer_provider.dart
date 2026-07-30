// lib/features/explorer/explorer_provider.dart
import 'package:flutter/foundation.dart';
import '../../models/plant_species.dart';

enum ExplorerViewMode { grid, list }

/// Holds the Explorer screen's active filter, search query, and grid/list
/// view mode. Species data itself lives in the app-wide [SpeciesProvider];
/// this just decides which subset to show and how.
class ExplorerProvider extends ChangeNotifier {
  String _filter = 'all';
  String get filter => _filter;

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  String _query = '';
  String get query => _query;

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  ExplorerViewMode _viewMode = ExplorerViewMode.grid;
  ExplorerViewMode get viewMode => _viewMode;

  void setViewMode(ExplorerViewMode m) {
    _viewMode = m;
    notifyListeners();
  }

  bool _compareMode = false;
  bool get compareMode => _compareMode;

  final Set<String> _compareSelection = {};
  Set<String> get compareSelection => _compareSelection;

  void toggleCompareMode() {
    _compareMode = !_compareMode;
    _compareSelection.clear();
    notifyListeners();
  }

  /// Selecting a third species bumps the oldest one rather than being a
  /// no-op — lets a device change its mind about one pick without having
  /// to deselect it first.
  void toggleCompareSelection(String speciesId) {
    if (_compareSelection.contains(speciesId)) {
      _compareSelection.remove(speciesId);
    } else {
      if (_compareSelection.length >= 2) {
        _compareSelection.remove(_compareSelection.first);
      }
      _compareSelection.add(speciesId);
    }
    notifyListeners();
  }

  void clearCompareSelection() {
    _compareSelection.clear();
    notifyListeners();
  }

  List<PlantSpecies> apply(List<PlantSpecies> all) {
    Iterable<PlantSpecies> result = all;
    switch (_filter) {
      case 'all':
        break;
      case 'medicinal':
        result = result.where((p) => (p.medicinalUses ?? '').trim().isNotEmpty);
        break;
      default:
        result = result.where((p) => p.growthType == _filter);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((p) =>
          p.commonName.toLowerCase().contains(q) ||
          p.scientificName.toLowerCase().contains(q) ||
          (p.familyName ?? '').toLowerCase().contains(q));
    }
    return result.toList();
  }
}
