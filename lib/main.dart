// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/supabase_client.dart';
import 'services/classifier_service.dart';
import 'services/tfjs_classifier_service.dart';
import 'services/species_repository.dart';
import 'services/identification_logger.dart';
import 'services/supabase_keep_alive.dart';
import 'core/species_provider.dart';
import 'core/dashboard_provider.dart';
import 'core/favorites_provider.dart';
import 'core/connectivity_provider.dart';
import 'core/theme_mode_provider.dart';
import 'core/learn_provider.dart';
import 'features/scan/scan_provider.dart';
import 'features/scan/offline_scan_queue.dart';
import 'features/explorer/explorer_provider.dart';
import 'features/challenge/services/challenge_service.dart';
import 'features/challenge/providers/challenge_badge_provider.dart';
import 'features/profile/services/profile_service.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/push_subscription_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'services/learn_repository.dart';

void main() {
  // Wrapping bootstrap in runZonedGuarded means a failure here (bad/missing
  // .env, unreachable Supabase project, etc.) surfaces as a real error
  // screen instead of a blank white page with a silent exception in the
  // console — see _BootstrapErrorApp below.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await SupabaseConfig.initialize();
    } catch (error, stackTrace) {
      debugPrint('App bootstrap failed: $error\n$stackTrace');
      runApp(_BootstrapErrorApp(error: error));
      return;
    }

    SupabaseKeepAlive(supabase).start();

    runApp(_buildApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught zone error: $error\n$stackTrace');
  });
}

Widget _buildApp() {
  return MultiProvider(
    providers: [
      // ── Services ──────────────────────────────────────────
      Provider<SpeciesRepository>(
        create: (_) => SpeciesRepository(supabase),
      ),
      Provider<IdentificationLogger>(
        create: (_) => IdentificationLogger(supabase),
      ),
      Provider<LearnRepository>(
        create: (_) => LearnRepository(supabase),
      ),
      Provider<ChallengeService>(
        create: (_) => ChallengeService(supabase),
      ),
      Provider<ProfileService>(
        create: (_) => ProfileService(supabase),
      ),
      Provider<NotificationService>(
        create: (_) => NotificationService(supabase),
      ),
      Provider<PushSubscriptionService>(
        create: (_) => PushSubscriptionService(supabase),
      ),

      // ── Classifier ────────────────────────────────────────
      // lazy: false — TfjsClassifierService's constructor kicks off the
      // model download/compile in the background; that only starts early
      // enough to matter (i.e. before the user reaches the Scan screen) if
      // this provider is built at app boot instead of on first read.
      Provider<ClassifierService>(
        lazy: false,
        create: (_) => TfjsClassifierService(),
      ),

      // ── Shared species data ───────────────────────────────
      ChangeNotifierProvider(
        create: (ctx) => SpeciesProvider(ctx.read<SpeciesRepository>()),
      ),
      ChangeNotifierProvider(
        create: (ctx) => DashboardProvider(ctx.read<SpeciesRepository>()),
      ),
      ChangeNotifierProvider(
        create: (_) => FavoritesProvider(),
      ),
      // lazy: false — the offline banner must appear immediately on a cold
      // load with no connectivity, not wait for some screen to read this.
      ChangeNotifierProvider(
        lazy: false,
        create: (_) => ConnectivityProvider(),
      ),
      // lazy: false — PlantIdApp reads this on the very first build to pick
      // light/dark/system, so it must exist (and have already resolved
      // AppBrightness synchronously in its constructor) before that runs.
      ChangeNotifierProvider(
        lazy: false,
        create: (_) => ThemeModeProvider(),
      ),
      ChangeNotifierProvider(
        create: (ctx) => LearnProvider(ctx.read<LearnRepository>()),
      ),
      ChangeNotifierProvider(
        create: (ctx) => ChallengeBadgeProvider(ctx.read<ChallengeService>()),
      ),
      ChangeNotifierProvider(
        create: (ctx) => ProfileProvider(
            ctx.read<ProfileService>(), ctx.read<NotificationService>()),
      ),
      // lazy: false — a leftover queue from a previous offline session
      // should start flushing (if already back online) at launch, not
      // wait for the Scan screen to be visited.
      ChangeNotifierProvider(
        lazy: false,
        create: (ctx) => OfflineScanQueue(ctx.read<IdentificationLogger>(),
            ctx.read<ProfileProvider>(), ctx.read<DashboardProvider>()),
      ),
      // lazy: false — polling must start at app launch, not wait for the
      // first widget (e.g. the navbar bell) to read this provider.
      ChangeNotifierProvider(
        lazy: false,
        create: (ctx) => NotificationProvider(ctx.read<NotificationService>(),
            ctx.read<ChallengeService>(), ctx.read<PushSubscriptionService>()),
      ),

      // ── Screen state ──────────────────────────────────────
      ChangeNotifierProvider(create: (_) => ScanProvider()),
      ChangeNotifierProvider(create: (_) => ExplorerProvider()),
    ],
    child: const PlantIdApp(),
  );
}

/// Shown instead of the real app when [SupabaseConfig.initialize] throws —
/// otherwise a bad/missing .env or an unreachable Supabase project just
/// produces a blank white page with no explanation.
class _BootstrapErrorApp extends StatelessWidget {
  final Object error;
  const _BootstrapErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFBF9F4),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFB3261E)),
                const SizedBox(height: 16),
                const Text(
                  "UENR Flora couldn't start",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Something went wrong while connecting to our servers. '
                  'Please refresh the page. If this keeps happening, '
                  'let us know.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
