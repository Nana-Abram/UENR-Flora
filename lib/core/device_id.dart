// lib/core/device_id.dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Single app-wide anonymous identity — generated once per browser/device
/// and persisted in SharedPreferences. Every feature that needs to scope
/// Supabase rows to "this user" (daily challenges, profile/achievements,
/// scan history) keys off this same id, so a device only ever has one
/// identity across the whole app.
class DeviceId {
  static const _key = 'uenr_flora_device_id';
  static String? _cached;

  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = _generate();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }

  /// Forgets the cached/stored id — used by "reset my data" so the next
  /// [get] call mints a fresh identity.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
  }

  static String _generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
