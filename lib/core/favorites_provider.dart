// lib/core/favorites_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which species this browser has marked as favorites. Stored only
/// in SharedPreferences (like [DeviceId]) rather than Supabase — favorites
/// are a personal, per-device preference with no need to sync across
/// devices.
class FavoritesProvider extends ChangeNotifier {
  static const _key = 'uenr_flora_favorite_species';

  final Set<String> _ids = {};
  bool loaded = false;

  FavoritesProvider() {
    _load();
  }

  bool isFavorite(String speciesId) => _ids.contains(speciesId);
  int get count => _ids.length;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids.addAll(prefs.getStringList(_key) ?? const []);
    loaded = true;
    notifyListeners();
  }

  /// Wipes every favorite — used by "Reset my data" so a fresh device
  /// identity doesn't inherit the previous identity's favorites.
  Future<void> clear() async {
    if (_ids.isEmpty) return;
    final previous = Set<String>.from(_ids);
    _ids.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, const []);
    } catch (_) {
      _ids.addAll(previous);
      notifyListeners();
    }
  }

  Future<void> toggle(String speciesId) async {
    final removed = _ids.remove(speciesId);
    if (!removed) _ids.add(speciesId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids.toList());
    } catch (_) {
      // Persistence failed — undo the in-memory toggle so the UI doesn't
      // show a favorited/unfavorited state that was never actually saved.
      if (removed) {
        _ids.add(speciesId);
      } else {
        _ids.remove(speciesId);
      }
      notifyListeners();
    }
  }
}
