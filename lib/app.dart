// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation.dart';
import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/results/results_screen.dart';
import 'features/explorer/explorer_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/learn/article_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/challenge/screens/challenge_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'models/identification_result.dart';

final GoRouter _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
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
          builder: (context, state) => const ExplorerScreen(),
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
    return MaterialApp.router(
      title: 'UENR Flora',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
