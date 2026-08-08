import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plantid_app/features/results/unknown_plant_screen.dart';
import 'package:plantid_app/features/scan/services/ood_detector.dart';
import 'package:plantid_app/models/plant_species.dart';

const _species = PlantSpecies(
  id: 'sp-1',
  scientificName: 'Testus plantus',
  commonName: 'Test Plant',
  modelClassIndex: 3,
);

const _species2 = PlantSpecies(
  id: 'sp-2',
  scientificName: 'Secundus plantus',
  commonName: 'Runner-up Plant',
  modelClassIndex: 9,
);

const _oodResult = OodResult(
  zone: OodZone.outOfDistribution,
  score: 60.0,
  threshold: 44.0,
  closestClassIndex: 3,
  secondClosestClassIndex: 9,
);

const _diagnostics = {
  'decision': 'ood',
  'ood_distance': 60.0,
  'threshold': 44.0,
  'entropy': 0.5,
  'confidence': 0.42,
  'top3_probability': 0.6,
  'tta_agreement': 4,
  'closest_species': 'sp-1',
  'model_version': 'test-version',
  'claude_used': false,
  'claude_changed_prediction': false,
};

/// Deliberately invalid — Image.memory's errorBuilder (see
/// unknown_plant_screen.dart's _CapturedImage) handles this gracefully, so
/// tests don't need a real decodable image just to render the screen.
final _fakeImageBytes = Uint8List.fromList([1, 2, 3, 4]);

Widget _buildTestApp(UnknownPlantResult result) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => UnknownPlantScreen(result: result)),
      GoRoute(
          path: '/scan',
          builder: (c, s) => const Scaffold(body: Text('SCAN SCREEN'))),
      GoRoute(
          path: '/explorer',
          builder: (c, s) => const Scaffold(body: Text('EXPLORER SCREEN'))),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('UnknownPlantScreen', () {
    testWidgets('shows the required title, body, and buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.42,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      // Title must be exactly this — not "Plant Not In Our Database".
      expect(find.text('No Reliable Match Found'), findsOneWidget);
      expect(find.text('Plant Not In Our Database'), findsNothing);

      expect(
        find.textContaining(
            'This plant could not be confidently matched with any of the 76'),
        findsOneWidget,
      );
      expect(
        find.textContaining('undocumented campus species'),
        findsOneWidget,
      );

      expect(find.text('Browse All Species'), findsOneWidget);
      expect(find.text('Scan Again'), findsOneWidget);
      expect(find.text('Report Unknown Plant'), findsOneWidget);
    });

    testWidgets(
        'shows both closest matches with reduced opacity and ~confidence',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.4237,
        secondClosestSpecies: _species2,
        secondClosestSpeciesConfidence: 0.15,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Test Plant'), findsOneWidget);
      expect(find.text('Testus plantus'), findsOneWidget);
      expect(find.text('~42% approximate confidence'), findsOneWidget);
      expect(
        find.textContaining('CLOSEST DOCUMENTED SPECIES'),
        findsOneWidget,
      );

      expect(find.text('Runner-up Plant'), findsOneWidget);
      expect(find.text('Secundus plantus'), findsOneWidget);
      expect(find.text('~15% approximate confidence'), findsOneWidget);
      expect(find.textContaining('SECOND CLOSEST SPECIES'), findsOneWidget);

      expect(find.textContaining('POSSIBLE MATCH ONLY'), findsNWidgets(2));

      final opacity = tester.widget<Opacity>(find.ancestor(
        of: find.text('Test Plant'),
        matching: find.byType(Opacity),
      ));
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('falls back gracefully when no closest species resolved',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: null,
        closestSpeciesConfidence: 0.0,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      expect(find.text('No close match found'), findsOneWidget);
      expect(find.textContaining('approximate confidence'), findsNothing);
    });

    testWidgets('"Scan Again" navigates to /scan', (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.42,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Again'));
      await tester.pumpAndSettle();

      expect(find.text('SCAN SCREEN'), findsOneWidget);
    });

    testWidgets('"Browse All Species" navigates to /explorer', (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.42,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Browse All Species'));
      await tester.pumpAndSettle();

      expect(find.text('EXPLORER SCREEN'), findsOneWidget);
    });

    testWidgets('"Back to scanner" navigates to /scan', (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.42,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to scanner'));
      await tester.pumpAndSettle();

      expect(find.text('SCAN SCREEN'), findsOneWidget);
    });

    testWidgets(
        '"Report Unknown Plant" opens the location/notes form; Cancel '
        "dismisses it without submitting", (tester) async {
      await tester.pumpWidget(_buildTestApp(UnknownPlantResult(
        imageBytes: _fakeImageBytes,
        oodResult: _oodResult,
        closestSpecies: _species,
        closestSpeciesConfidence: 0.42,
        secondClosestSpecies: null,
        secondClosestSpeciesConfidence: 0.0,
        diagnostics: _diagnostics,
      )));
      await tester.pumpAndSettle();

      // No UnknownPlantReporter is wired into this test app on purpose —
      // if Cancel accidentally triggered a submit, context.read would
      // throw a ProviderNotFoundException and this test would fail loudly.
      //
      // ensureVisible first: at the default 800x600 test surface size, this
      // button sits below the fold of the page's CustomScrollView, so a
      // plain tap() misses it (tap() doesn't auto-scroll). An explicit
      // pumpAndSettle after ensureVisible is required on this layout (it
      // wasn't before the CustomScrollView/SliverFillRemaining switch —
      // see UnknownPlantScreen.build): ensureVisible's scroll-into-view
      // animation needs an extra frame to finish settling here, or the
      // subsequent tap's hit test still lands below the viewport.
      await tester.ensureVisible(find.text('Report Unknown Plant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Unknown Plant'));
      await tester.pumpAndSettle();

      expect(find.text('Where was this?'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Where was this?'), findsNothing);
      // Still idle — Cancel must not have sent anything.
      expect(find.text('Report Unknown Plant'), findsOneWidget);
      expect(find.text('Thanks — reported'), findsNothing);
    });
  });
}
