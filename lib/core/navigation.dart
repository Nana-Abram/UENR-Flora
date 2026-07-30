// lib/core/navigation.dart
import 'package:flutter/material.dart';

/// Root navigator key, wired into the app's [GoRouter] in app.dart.
/// Lets non-widget code (e.g. [ProfileProvider.showAchievementToast])
/// insert an overlay entry over whatever screen is currently visible.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the `/explorer` route for a submitted search query — shared by
/// the navbar search field and the home hero search field so both actually
/// carry the query through instead of just landing on an unfiltered
/// Explorer page. `ExplorerScreen` reads the `q` param back out via
/// `state.uri.queryParameters['q']` to seed [ExplorerProvider]'s query.
String explorerSearchPath(String query) {
  final q = query.trim();
  return q.isEmpty ? '/explorer' : '/explorer?q=${Uri.encodeQueryComponent(q)}';
}

/// Tracks the sequence of visited locations so [Breadcrumb]'s "UENR
/// Campus" can send the user back to whichever page they came from,
/// instead of a fixed target. This app only ever calls `context.go(...)`
/// (never `push`), so GoRouter's own Navigator stack is always a single
/// page deep — `context.pop()` has nothing to pop. Fed by a `redirect`
/// hook on the root [GoRouter] in app.dart, which runs on every
/// navigation.
class RouteHistory {
  RouteHistory._();
  static final List<String> _visited = [];

  static void record(String location) {
    if (_visited.isNotEmpty && _visited.last == location) return;
    _visited.add(location);
    if (_visited.length > 20) _visited.removeAt(0);
  }

  /// The location visited immediately before the current one, or null if
  /// this is the first page seen this session.
  static String? get previous =>
      _visited.length >= 2 ? _visited[_visited.length - 2] : null;

  /// Forgets all recorded history — for tests (this is static/global state
  /// that otherwise persists across widget tests) or any future flow that
  /// wants a clean slate. Not currently called by "reset my data": browsing
  /// history isn't part of a device's profile/achievements/scans, so
  /// wiping it there isn't obviously correct behavior.
  static void clear() => _visited.clear();
}
