// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/supabase_client.dart';
import 'services/classifier_service.dart';
import 'services/tfjs_classifier_service.dart';
import 'features/scan/services/background_identifier_service.dart';
import 'features/scan/services/image_upload_resizer.dart';
import 'features/scan/services/gate_classifier_service.dart';
import 'features/scan/services/ood_detector.dart';
import 'features/scan/services/unknown_plant_reporter.dart';
import 'services/species_repository.dart';
import 'services/identification_logger.dart';
import 'services/supabase_keep_alive.dart';
import 'services/edge_function_keep_alive.dart';
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
    EdgeFunctionKeepAlive(supabase).start();

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
      // lazy: false — these need to exist at app boot so _AppBootstrap
      // (below) can warm both up right after first frame, well before the
      // user reaches the Scan screen. Construction itself is cheap (no
      // network); the actual multi-megabyte model download/compile is
      // started by warmUp()/loadModel(), deliberately NOT called here — see
      // _AppBootstrap's comment for why kicking off ~18MB of model fetches
      // this early (before first paint) was slowing down app boot itself.
      Provider<ClassifierService>(
        lazy: false,
        create: (_) => TfjsClassifierService(),
      ),
      Provider<GateClassifierService>(
        lazy: false,
        create: (_) => GateClassifierService(),
      ),
      Provider<OodDetector>(
        lazy: false,
        create: (_) => OodDetector(),
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

      // ── Background accuracy layer ──────────────────────────
      // Default (lazy), unlike the classifiers above — there's no model
      // download/warm-up to front-load; the Claude call itself happens
      // entirely server-side (see the background-identify edge function),
      // and the first real use is inside _runIdentification on the user's
      // first scan. The closure re-reads SpeciesProvider.all at call time
      // (not now) since that list is reassigned on every reload.
      Provider<BackgroundIdentifierService>(
        create: (ctx) => BackgroundIdentifierService(
          supabase,
          () => ctx.read<SpeciesProvider>().all,
          resizeImageForUpload,
        ),
      ),
      // "Report Unknown Plant" — also lazy, same reasoning as
      // BackgroundIdentifierService: no warm-up, first use is deep inside
      // UnknownPlantScreen, which only exists after an OOD scan result.
      Provider<UnknownPlantReporter>(
        create: (_) => UnknownPlantReporter(supabase),
      ),

      // ── Screen state ──────────────────────────────────────
      ChangeNotifierProvider(create: (_) => ScanProvider()),
      ChangeNotifierProvider(create: (_) => ExplorerProvider()),
    ],
    child: const _AppBootstrap(child: PlantIdApp()),
  );
}

/// Starts the species/gate classifier model downloads (~18MB combined)
/// right after the first frame paints, instead of at Provider-construction
/// time (before first paint). Those two downloads used to start racing
/// CanvasKit and main.dart.js for bandwidth during the app's own boot —
/// on a slow connection that meant the splash screen stayed up until the
/// model fetches let go of enough bandwidth for CanvasKit to finish, not
/// until the app itself was actually ready to paint. Deferring them here
/// costs nothing: the Scan screen already gates on ClassifierService.ready
/// / GateClassifierService.ready with its own "Preparing scanner..." state
/// (see scan_screen.dart), and classify() calls still load the model
/// themselves on demand if warmUp() hasn't finished yet.
class _AppBootstrap extends StatefulWidget {
  final Widget child;
  const _AppBootstrap({required this.child});

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassifierService>().warmUp();
      context.read<GateClassifierService>().loadModel();
      // Unlike the two calls above, OodDetector.ready does NOT swallow a
      // load failure (see that getter's own doc comment — this data is
      // required, not a best-effort perf warm-up) — it's genuinely
      // memoized. This catchError just attaches an early listener so a
      // real failure doesn't get logged as an "unhandled exception" before
      // _ScannerReadinessGate ever awaits the same future; the error itself
      // still surfaces there (and to _runIdentification's try/catch) once
      // scanning is actually attempted.
      unawaited(context.read<OodDetector>().ready.catchError((_) {}));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
