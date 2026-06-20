// lib/features/scan/scan_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/identification_result.dart';
import '../../services/classifier_service.dart';
import '../../services/species_repository.dart';
import '../../services/identification_logger.dart';
import 'scan_provider.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanProvider(),
      child: const _ScanBody(),
    );
  }
}

class _ScanBody extends StatelessWidget {
  const _ScanBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark green header — always visible
        Container(
          width: double.infinity,
          color: kDeep,
          padding: const EdgeInsets.fromLTRB(kSp24, 28, kSp24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: kBRPill,
                ),
                child: const Text('AI identification',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500, color: kMint)),
              ),
              const SizedBox(height: 12),
              const Text('Plant scanner',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500,
                      color: Colors.white)),
              const SizedBox(height: 5),
              const Text(
                  'Upload a leaf photo — inference runs locally in your browser',
                  style: TextStyle(fontSize: 13, color: kMint)),
            ],
          ),
        ),

        // Scrollable body — switches between states
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Consumer<ScanProvider>(
                  builder: (context, provider, _) {
                    switch (provider.state) {
                      case ScanState.idle:
                        return _IdleView(errorMessage: provider.errorMessage);
                      case ScanState.preview:
                        return _PreviewView(bytes: provider.imageBytes!);
                      case ScanState.analyzing:
                        return const _AnalyzingView();
                    }
                  },
                ),
              ),
            ),
          ),
        ),

        // Footer
        Container(
          color: kDark,
          padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 18),
          child: const Center(
            child: Text(
              'All inference runs in-browser · no image is sent to any server',
              style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 1 — IDLE
// ─────────────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final String? errorMessage;
  const _IdleView({this.errorMessage});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) context.read<ScanProvider>().setPreview(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kSp24),
      child: Column(
        children: [
          if (errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: kUnhealthyBg,
                border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
                borderRadius: kBRLg,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 17, color: kUnhealthyTx),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(errorMessage!,
                        style: const TextStyle(fontSize: 12, color: kUnhealthyTx)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= kBreakpointMd;
              final left = _DropZone(onPick: (src) => _pick(context, src));
              const right = _TipsAndSteps();
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 14, child: left),
                        const SizedBox(width: 20),
                        Expanded(flex: 10, child: right),
                      ],
                    )
                  : Column(children: [left, const SizedBox(height: 20), right]);
            },
          ),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  final void Function(ImageSource) onPick;
  const _DropZone({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPick(ImageSource.gallery),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBR2xl,
          border: Border.all(color: kBorder, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: kLight),
              child: const Icon(Icons.camera_alt_outlined, size: 28, color: kDeep),
            ),
            const SizedBox(height: 14),
            const Text('Drop your leaf image here',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 5),
            const Text('or use the buttons below',
                style: TextStyle(fontSize: 12, color: kMu)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 9, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onPick(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDeep, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: kBRSm),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 14),
                  label: const Text('Camera',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTx,
                    side: const BorderSide(color: kBorder, width: 0.5),
                    backgroundColor: kBg,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: kBRSm),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 14),
                  label: const Text('Gallery',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsAndSteps extends StatelessWidget {
  const _TipsAndSteps();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tips card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kWhite,
            border: Border.all(color: kBorder, width: 0.5),
            borderRadius: kBRXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Capture tips',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
              const SizedBox(height: 12),
              ...[
                (Icons.wb_sunny_outlined,   kAmber,                  'Natural daylight, avoid flash'),
                (Icons.center_focus_strong, kGreen,                  'Fill 60–80% of frame with leaf'),
                (Icons.contrast,            kDeep,                   'Plain or neutral background'),
                (Icons.flip_camera_ios,     const Color(0xFF534AB7), 'Capture both sides of leaf'),
              ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                          color: t.$2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7)),
                      child: Icon(t.$1, size: 14, color: t.$2),
                    ),
                    const SizedBox(width: 10),
                    Text(t.$3,
                        style: const TextStyle(fontSize: 12, color: kMu)),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // How it works card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kLight,
            border: Border.all(color: kMint, width: 0.5),
            borderRadius: kBRLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How the model works',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: kDeep)),
              const SizedBox(height: 9),
              ...[
                'Image resized to 224×224 and normalised',
                'MobileNetV2 runs inference via TensorFlow.js',
                'Species + health results retrieved from Supabase',
              ].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 19, height: 19,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: kDeep),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 11, color: kDeep, height: 1.5)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 2 — PREVIEW
// ─────────────────────────────────────────────────────────────
class _PreviewView extends StatelessWidget {
  final Uint8List bytes;
  const _PreviewView({required this.bytes});

  Future<void> _identify(BuildContext context) async {
    final provider = context.read<ScanProvider>();
    final classifier = context.read<ClassifierService>();
    final repository = context.read<SpeciesRepository>();
    final logger = context.read<IdentificationLogger>();
    // Captured before startAnalyzing() swaps this widget out of the tree —
    // the router outlives the context, so it stays valid after the await.
    final router = GoRouter.of(context);
    provider.startAnalyzing();

    try {
      final output = await classifier.classify(bytes);

      final species = output.confidence >= kConfidenceThreshold
          ? await repository.getByClassIndex(output.classIndex)
          : null;

      // Logging is analytics, not the critical path — a write failure
      // (e.g. an RLS policy blocking the insert) must not stop the user
      // from seeing their result.
      try {
        await logger.log(classification: output, species: species);
      } catch (_) {}

      // Build an IdentificationResult with the Supabase species
      // wrapped in PlantSpeciesSimple for the ResultsScreen.
      final simple = species == null
          ? null
          : PlantSpeciesSimple(
              id:                    species.id,
              commonName:            species.commonName,
              scientificName:        species.scientificName,
              localNameTwi:          species.localNameTwi,
              familyName:            species.familyName,
              growthHabit:           species.growthHabit,
              leafType:              species.leafType,
              floweringSeason:       species.floweringSeason,
              origin:                species.origin,
              ecologicalImportance:  species.ecologicalImportance,
              environmentalBenefits: species.environmentalBenefits,
              medicinalUses:         species.medicinalUses,
              economicImportance:    species.economicImportance,
              waterRequirements:     species.waterRequirements,
              sunlightRequirements:  species.sunlightRequirements,
              soilPreference:        species.soilPreference,
              modelClassIndex:       species.modelClassIndex,
              didYouKnowFacts:       species.didYouKnowFacts,
            );

      router.go('/results', extra: IdentificationResult(
        classification: output,
        species:        simple,
        imagePath:      'in-memory',
      ));
    } catch (e) {
      provider.setError('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kSp24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kBreakpointMd;
          final left = Column(
            children: [
              // Image preview
              ClipRRect(
                borderRadius: kBR2xl,
                child: Container(
                  height: 230, width: double.infinity,
                  color: const Color(0xFFFAC775),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.yard_outlined, size: 64, color: Color(0xFF633806)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Quality check notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: kLight,
                  border: Border.all(color: kMint, width: 0.5),
                  borderRadius: kBRLg,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 17, color: kDeep),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text('Good quality — leaf is well-lit and in focus',
                          style: TextStyle(fontSize: 12, color: kDeep)),
                    ),
                  ],
                ),
              ),
            ],
          );

          final right = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kWhite,
              border: Border.all(color: kBorder, width: 0.5),
              borderRadius: kBRXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ready to identify',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
                const SizedBox(height: 5),
                const Text(
                  'The model compares your leaf against 30 campus species. '
                  'Results below 70% confidence prompt a retake.',
                  style: TextStyle(fontSize: 12, color: kMu, height: 1.6),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _identify(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAmber, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: kBRSm),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.search_outlined, size: 16),
                    label: const Text('Identify plant',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<ScanProvider>().reset(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kMu,
                      side: const BorderSide(color: kBorder, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: kBRSm),
                    ),
                    child: const Text('Use a different image',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          );

          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 14, child: left),
                    const SizedBox(width: 20),
                    Expanded(flex: 10, child: right),
                  ],
                )
              : Column(children: [left, const SizedBox(height: 20), right]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 3 — ANALYZING
// ─────────────────────────────────────────────────────────────
class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFAC775), borderRadius: kBR2xl,
              ),
              child: const Icon(Icons.yard_outlined,
                  size: 60, color: Color(0xFF633806)),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
              color: kDeep,
              backgroundColor: kLight,
              strokeWidth: 3,
            ),
            const SizedBox(height: 18),
            const Text('Analysing your leaf...',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 6),
            const Text(
              'Comparing features against 30 campus species',
              style: TextStyle(fontSize: 13, color: kMu),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
