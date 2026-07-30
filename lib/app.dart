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
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: '/results',
          builder: (context, state) {
            final result = state.extra as IdentificationResult?;
            if (result == null) return const ScanScreen();
            return ResultsScreen(result: result);
          },
        ),
        GoRoute(
          path: '/explorer',
          builder: (context, state) => ExplorerScreen(
            initialQuery: state.uri.queryParameters['q'],
            initialSpeciesId: state.uri.queryParameters['species'],
          ),
        ),
        GoRoute(
          path: '/learn',
          builder: (context, state) => const LearnScreen(),
        ),
        GoRoute(
          path: '/learn/article/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return const LearnScreen();
            return ArticleDetailScreen(articleId: id);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/challenge',
          builder: (context, state) => const ChallengeScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
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
