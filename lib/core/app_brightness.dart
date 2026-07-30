// lib/core/app_brightness.dart
import 'package:flutter/material.dart';

/// Global, context-free brightness signal that every color token in
/// theme.dart reads from — this app's colors are plain top-level constants
/// referenced directly (`color: kTx`) across ~70 files rather than looked
/// up via `Theme.of(context)`, so making dark mode work without a massive
/// rewrite of every call site means the tokens themselves need to resolve
/// dynamically. [ThemeModeProvider] is the only thing that calls [set] —
/// widgets never touch this directly, they just keep using `kTx`/`kBg`/etc.
/// as before and it now resolves to the right value.
class AppBrightness {
  AppBrightness._();

  static Brightness _current = Brightness.light;
  static Brightness get current => _current;
  static bool get isDark => _current == Brightness.dark;

  static void set(Brightness value) {
    _current = value;
  }
}
