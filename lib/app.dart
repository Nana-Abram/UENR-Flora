// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/results/results_screen.dart';
import 'features/explorer/explorer_screen.dart';
import 'features/learn/learn_screen.dart';
import 'models/identification_result.dart';

final GoRouter _router = GoRouter(
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
            final result = state.extra as IdentificationResult;
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
