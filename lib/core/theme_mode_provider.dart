// lib/core/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_brightness.dart';

/// Persisted light/dark/system preference. Also the only thing that ever
/// calls [AppBrightness.set] — resolving "system" to a real [Brightness]
/// needs [WidgetsBindingObserver.didChangePlatformBrightness], which this
/// provider registers for regardless of the current mode, so switching
/// into "system" later doesn't miss the OS's current value.
class ThemeModeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _key = 'uenr_flora_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeModeProvider() {
    WidgetsBinding.instance.addObserver(this);
    // Resolves synchronously from the platform's current brightness so
    // AppBrightness is correct before the very first frame, even though
    // the persisted preference (below) only arrives after an async gap.
    _resolveBrightness();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _resolveBrightness();
      notifyListeners();
    } catch (_) {
      // Falls back to the already-resolved system brightness above.
    }
  }

  void _resolveBrightness() {
    final resolved = switch (_mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    AppBrightness.set(resolved);
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode != ThemeMode.system) return;
    _resolveBrightness();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _resolveBrightness();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Best-effort persistence — the in-memory mode is already applied.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
