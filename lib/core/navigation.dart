// lib/core/navigation.dart
import 'package:flutter/material.dart';

/// Root navigator key, wired into the app's [GoRouter] in app.dart.
/// Lets non-widget code (e.g. [ProfileProvider.showAchievementToast])
/// insert an overlay entry over whatever screen is currently visible.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
