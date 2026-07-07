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
