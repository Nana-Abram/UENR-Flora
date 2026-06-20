// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/supabase_client.dart';
import 'services/classifier_service.dart';
import 'services/mock_classifier_service.dart';
import 'services/species_repository.dart';
import 'services/identification_logger.dart';
import 'features/scan/scan_provider.dart';
import 'features/explorer/explorer_provider.dart';

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

        // ── Classifier ────────────────────────────────────────
        // SWAP THIS LINE when the real TensorFlow.js model is ready.
        // Replace MockClassifierService() with TfjsClassifierService().
        // No other file needs to change.
        Provider<ClassifierService>(
          create: (_) => MockClassifierService(),
        ),

        // ── Screen state ──────────────────────────────────────
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => ExplorerProvider()),
      ],
      child: const PlantIdApp(),
    ),
  );
}
