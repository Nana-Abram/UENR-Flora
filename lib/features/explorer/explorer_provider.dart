// lib/features/explorer/explorer_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';

class ExplorerProvider extends ChangeNotifier {
  String _filter = 'all';
  String get filter => _filter;

  List<Map<String, dynamic>> get filtered {
    if (_filter == 'all') return kSamplePlants;
    return kSamplePlants
        .where((p) => p['type'] == _filter)
        .toList();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }
}
