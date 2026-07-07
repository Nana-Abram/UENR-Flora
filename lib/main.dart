// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/supabase_client.dart';
import 'services/classifier_service.dart';
import 'services/tfjs_classifier_service.dart';
import 'services/species_repository.dart';
import 'services/identification_logger.dart';
import 'core/species_provider.dart';
import 'core/dashboard_provider.dart';
import 'core/learn_provider.dart';
import 'features/scan/scan_provider.dart';
import 'features/explorer/explorer_provider.dart';
import 'features/challenge/services/challenge_service.dart';
import 'features/challenge/providers/challenge_badge_provider.dart';
import 'features/profile/services/profile_service.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'services/learn_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
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

        // ── Classifier ────────────────────────────────────────
        Provider<ClassifierService>(
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
          create: (ctx) => LearnProvider(ctx.read<LearnRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ChallengeBadgeProvider(ctx.read<ChallengeService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ProfileProvider(ctx.read<ProfileService>(), ctx.read<NotificationService>()),
        ),
        // lazy: false — polling must start at app launch, not wait for the
        // first widget (e.g. the navbar bell) to read this provider.
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) => NotificationProvider(ctx.read<NotificationService>(), ctx.read<ChallengeService>()),
        ),

        // ── Screen state ──────────────────────────────────────
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => ExplorerProvider()),
      ],
      child: const PlantIdApp(),
    ),
  );
}
