// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/navigation.dart';
import 'core/app_brightness.dart';
import 'core/theme.dart';
import 'core/theme_mode_provider.dart';
import 'features/shell/app_shell.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/results/results_screen.dart';
import 'features/results/unknown_plant_screen.dart';
import 'features/explorer/explorer_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/learn/article_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/leaderboard_screen.dart';
import 'features/challenge/screens/challenge_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'models/identification_result.dart';

final GoRouter _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    RouteHistory.record(state.uri.toString());
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      // Every route below uses pageBuilder + NoTransitionPage instead of the
      // plain `builder:` shorthand (which defaults to the platform's push
      // transition — a slide-with-parallax on iOS/CupertinoPageTransitionsBuilder).
      // This app's top nav (AppNavbar) behaves like a tab bar between
      // sibling pages, not a stack the user drills into, so a directional
      // push read as wrong even at full speed. It also measurably cost more
      // than a normal push: for the ~300ms of that animation, BOTH the
      // outgoing and incoming screen are on screen and painting every frame
      // — each one here is a full CustomScrollView with large hero images,
      // which is expensive under the web engine's CanvasKit renderer and
      // measurably worse on mobile Safari specifically. On a slow frame
      // rate that 300ms stretches out and the still-visible overlap of two
      // unrelated full screens reads as a multi-second glitch/ghosting
      // artifact (reported live: breadcrumbs and hero text from both pages
      // superimposed) rather than a clean transition. NoTransitionPage
      // swaps instantly — no animation to stretch out, so nothing to
      // glitch, and it matches how tab navigation reads everywhere else in
      // the app (bottom/side nav highlight just changes state instantly).
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/scan',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ScanScreen()),
        ),
        GoRoute(
          path: '/results',
          pageBuilder: (context, state) {
            final result = state.extra as IdentificationResult?;
            return NoTransitionPage(
              child: result == null ? const ScanScreen() : ResultsScreen(result: result),
            );
          },
        ),
        GoRoute(
          path: '/results/unknown',
          pageBuilder: (context, state) {
            final result = state.extra as UnknownPlantResult?;
            return NoTransitionPage(
              child: result == null ? const ScanScreen() : UnknownPlantScreen(result: result),
            );
          },
        ),
        GoRoute(
          path: '/explorer',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ExplorerScreen(
              initialQuery: state.uri.queryParameters['q'],
              initialSpeciesId: state.uri.queryParameters['species'],
            ),
          ),
        ),
        GoRoute(
          path: '/learn',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LearnScreen()),
        ),
        GoRoute(
          path: '/learn/article/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return NoTransitionPage(
              child: id == null ? const LearnScreen() : ArticleDetailScreen(articleId: id),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ProfileScreen(initialTab: state.uri.queryParameters['tab']),
          ),
        ),
        GoRoute(
          path: '/leaderboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LeaderboardScreen()),
        ),
        GoRoute(
          path: '/challenge',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ChallengeScreen()),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotificationScreen()),
        ),
      ],
    ),
  ],
);

class PlantIdApp extends StatelessWidget {
  const PlantIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Every custom widget in this app reads color tokens as plain top-level
    // getters (see theme.dart), not via Theme.of(context) — so a Provider
    // rebuild alone doesn't reach them: GoRouter caches each route's built
    // page, and const-instantiated screens (`const HomeScreen()` etc. in
    // app.dart's route builders) are skipped by Flutter's reconciliation on
    // an ancestor rebuild regardless. Verified live that watching
    // ThemeModeProvider here was NOT sufficient — only the one widget that
    // itself called context.watch actually repainted; the rest of the app,
    // including AppShell's own Scaffold background, stayed on the old
    // colors. Keying MaterialApp.router by the mode forces Flutter to tear
    // down and rebuild the entire app on toggle instead — heavier than a
    // targeted rebuild, but toggling theme is a rare, deliberate action, and
    // _router (a persistent top-level object, not tied to this Element's
    // lifecycle) keeps the current route/location across the rebuild, so
    // only in-page scroll position resets, not navigation.
    final themeMode = context.watch<ThemeModeProvider>().mode;
    // Keying on the *resolved* brightness, not themeMode directly — in
    // ThemeMode.system, the mode itself never changes when the OS flips
    // light/dark, only AppBrightness does (via
    // ThemeModeProvider.didChangePlatformBrightness), and that's what
    // needs to trigger the rebuild.
    return MaterialApp.router(
      key: ValueKey(AppBrightness.isDark),
      title: 'UENR Flora',
      theme: buildAppTheme(dark: false),
      darkTheme: buildAppTheme(dark: true),
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
