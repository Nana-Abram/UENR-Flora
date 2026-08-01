// lib/services/persistent_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed cache for a JSON-encodable list of records,
/// keyed by name, with a fixed TTL after which [read] reports a miss even
/// though a cached copy still exists on disk.
class PersistentCache {
  static const _ttl = Duration(hours: 24);

  Future<List<Map<String, dynamic>>?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final savedAtMs = prefs.getInt('$key:savedAt');
    if (raw == null || savedAtMs == null) return null;

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    if (DateTime.now().difference(savedAt) > _ttl) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      // Malformed/incompatible cache (e.g. a schema change) — treat as a miss.
      return null;
    }
  }

  Future<void> write(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
    await prefs.setInt('$key:savedAt', DateTime.now().millisecondsSinceEpoch);
  }
}
