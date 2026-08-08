// lib/features/scan/scan_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/dashboard_provider.dart';
import '../../core/device_id.dart';
import '../../core/species_provider.dart';
import '../../models/identification_result.dart';
import '../../models/plant_species.dart';
import '../../services/classifier_service.dart';
import '../../services/species_repository.dart';
import '../../services/identification_logger.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/breadcrumb.dart';
import '../profile/providers/profile_provider.dart';
import '../results/unknown_plant_screen.dart';
import 'offline_scan_queue.dart';
import 'pending_scan.dart';
import 'scan_provider.dart';
import 'services/background_identifier_service.dart';
import 'services/gate_classifier_service.dart';
import 'services/image_quality_checker.dart';
import 'services/ood_detector.dart';
import 'services/rejection_gate.dart';
import 'services/scan_diagnostics.dart';

final _rejectionGate = RejectionGate();
final _qualityChecker = ImageQualityChecker();

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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Breadcrumb(current: 'AI Scanner'),
                    const SizedBox(height: 16),
                    Text('AI Plant Scanner',
                        style: TextStyle(
                            fontFamily: kFontDisplay,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: kTx)),
                    const SizedBox(height: 6),
                    Text(
                        "Identify any plant instantly using our AI model trained on UENR's botanical database.",
                        style: TextStyle(fontSize: 14, color: kMu)),
                    const SizedBox(height: 24),
                    const _ScannerReadinessGate(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppFooter(
                message: 'All inference runs in-browser · no image is sent to any server',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STARTUP GATE — both models must be loaded before scanning is allowed
// ─────────────────────────────────────────────────────────────

/// Blocks the whole capture/scan UI behind a single "Preparing scanner..."
/// state until both the species classifier and the gate model are ready —
/// they load in parallel (see main.dart, which kicks off the gate model's
/// load immediately on construction, same as TfjsClassifierService's own
/// constructor-triggered preload). A StatefulWidget (not a plain
/// FutureBuilder in _ScanBody's build) so the combined future is created
/// once via the `late final` field below, not re-created — and therefore
/// re-awaited from scratch — on every rebuild.
class _ScannerReadinessGate extends StatefulWidget {
  const _ScannerReadinessGate();

  @override
  State<_ScannerReadinessGate> createState() => _ScannerReadinessGateState();
}

class _ScannerReadinessGateState extends State<_ScannerReadinessGate> {
  late final Future<void> _modelsReady = Future.wait([
    context.read<ClassifierService>().ready,
    context.read<GateClassifierService>().ready,
    context.read<OodDetector>().ready,
  ]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _modelsReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PreparingScannerView();
        }
        return Consumer<ScanProvider>(
          builder: (context, provider, _) {
            final Widget child = switch (provider.state) {
              ScanState.idle =>
                _IdleView(errorMessage: provider.errorMessage),
              ScanState.preview =>
                _PreviewView(bytes: provider.primaryImage!),
              ScanState.analyzing =>
                _AnalyzingView(bytes: provider.latestImage!),
              ScanState.needsMoreImages => const _NeedsMoreImagesView(),
              ScanState.rejected =>
                _RejectedView(level: provider.lastRejectionLevel!),
              ScanState.qualityRejected =>
                _QualityRejectedView(quality: provider.lastQualityIssue!),
              ScanState.gateRejected =>
                _GateRejectedView(result: provider.lastGateResult!),
            };
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              // Default AnimatedSwitcher layout stacks the outgoing and
              // incoming views on top of each other for the whole
              // crossfade — fine for two similarly-shaped widgets, but
              // these states swing from a two-column preview layout to a
              // centered analysing card (very different sizes/positions),
              // so the stock crossfade showed both screens ghosted on top
              // of one another for the transition's duration. Dropping
              // previousChildren here means only the incoming view ever
              // renders, so it simply fades in over the current background
              // instead of visibly overlapping the old screen.
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              child: KeyedSubtree(
                key: ValueKey(provider.state),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

class _PreparingScannerView extends StatelessWidget {
  const _PreparingScannerView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: kDeep,
              backgroundColor: kLight,
              strokeWidth: 3,
            ),
            const SizedBox(height: 18),
            Text('Preparing scanner...',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 6),
            Text(
              'Loading the on-device AI models — this only happens once.',
              style: TextStyle(fontSize: 13, color: kMu),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) context.read<ScanProvider>().setPreview(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Icon(Icons.error_outline, size: 17, color: kUnhealthyTx),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(errorMessage!,
                      style:
                          TextStyle(fontSize: 12, color: kUnhealthyTx)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kBreakpointMd;
            final left = _CapturePanel(onPick: (src) => _pick(context, src));
            const right = _ResultsPlaceholderPanel();
            if (!isWide) {
              return Column(
                  children: [left, const SizedBox(height: 20), right]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 20),
                  const Expanded(child: right),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CapturePanel extends StatelessWidget {
  final void Function(ImageSource) onPick;
  const _CapturePanel({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onPick(ImageSource.camera),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(color: kDeep, borderRadius: kBR2xl),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: kBRXl,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Icon(Icons.camera_alt_outlined,
                              size: 26, color: kMint),
                        ),
                        const SizedBox(height: 12),
                        Text('Click to capture',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: kBRSm),
                  elevation: 0,
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Capture Image',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTx,
                  side: BorderSide(color: kBorder, width: 0.5),
                  backgroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: kBRSm),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Upload from Gallery',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _TipsCard(),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const _tips = [
    'Ensure good lighting — natural daylight works best',
    'Capture the leaf clearly with stem if possible',
    'Include flower or fruit for higher accuracy',
    'Avoid blurry or heavily shadowed images',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border.all(color: kBorder, width: 0.5),
        borderRadius: kBRXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 15, color: kTx),
              const SizedBox(width: 8),
              Text('Tips for Best Results',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kTx)),
            ],
          ),
          const SizedBox(height: 10),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, right: 9),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: kGreen),
                    ),
                    Expanded(
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 12, color: kMu, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ResultsPlaceholderPanel extends StatelessWidget {
  const _ResultsPlaceholderPanel();

  @override
  Widget build(BuildContext context) {
    final totalScans = context.watch<DashboardProvider>().totalScans;
    final totalSpecies = context.watch<SpeciesProvider>().totalCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border.all(color: kBorder, width: 0.5),
        borderRadius: kBRXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration:
                      BoxDecoration(color: kLight, borderRadius: kBRLg),
                  child:
                      Icon(Icons.eco_outlined, size: 30, color: kGreen),
                ),
                const SizedBox(height: 16),
                Text('Results will appear here',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTx)),
                const SizedBox(height: 6),
                Text(
                    'Capture or upload a plant image to begin identification.',
                    style: TextStyle(fontSize: 12, color: kMu),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _StatTile(
                      value: totalSpecies > 0 ? '$totalSpecies spp.' : '—',
                      label: 'Database')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatTile(
                      value: '${(kConfidenceThreshold * 100).round()}%',
                      label: 'Confidence threshold')),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _StatTile(value: '$totalScans', label: 'Scans logged')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: kLight, borderRadius: kBRLg),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: kDeep)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: kMu),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 2 — PREVIEW
// ─────────────────────────────────────────────────────────────

/// Looks up the species with a given model class index from an
/// already-loaded in-memory list (see SpeciesProvider) rather than a
/// network round trip — used for OodResult.closestClassIndex, which every
/// scan resolves (for ScanDiagnostics) whether or not the result ends up
/// being shown to the user, so a Supabase query per scan just for this
/// would add latency/load nothing here actually needs.
PlantSpecies? _speciesByClassIndex(List<PlantSpecies> species, int classIndex) {
  for (final s in species) {
    if (s.modelClassIndex == classIndex) return s;
  }
  return null;
}

/// Runs classification over every photo collected so far. Shared by the
/// initial "Identify plant" button and the "add another photo" flow, since
/// both need to react the same way to a confident vs. low-confidence result.
Future<void> _runIdentification(BuildContext context) async {
  final provider = context.read<ScanProvider>();
  final classifier = context.read<ClassifierService>();
  final repository = context.read<SpeciesRepository>();
  final logger = context.read<IdentificationLogger>();
  final profileProvider = context.read<ProfileProvider>();
  final dashboardProvider = context.read<DashboardProvider>();
  final offlineQueue = context.read<OfflineScanQueue>();
  final allSpecies = context.read<SpeciesProvider>().all;
  // Captured before startAnalyzing() swaps this widget out of the tree —
  // the router outlives the context, so it stays valid after the await.
  final router = GoRouter.of(context);
  final images = List<Uint8List>.of(provider.images);
  provider.startAnalyzing();

  final gateClassifier = context.read<GateClassifierService>();
  final bgIdentifier = context.read<BackgroundIdentifierService>();
  final oodDetector = context.read<OodDetector>();

  try {
    final latest = images.last;

    // Layer 1 — cheap raw-pixel quality screen (too dark / too uniform),
    // before either model runs at all. Never joins the running average and
    // never counts as one of the 3 attempts — ScanProvider.rejectQuality()
    // removes it from `images`. checkDetailed (not check) so the raw
    // brightness/variance survive to the background-identify activation
    // check further down, without decoding the image a second time.
    final qualityResult = await _qualityChecker.checkDetailed(latest);
    if (qualityResult.quality != ImageQuality.good) {
      provider.rejectQuality(qualityResult.quality);
      return;
    }

    // Layer 2 — binary plant/not-plant gate model. Catches confidently-
    // wrong non-plant photos the species model's own entropy/top-k gate
    // (below) can miss — see rejection_gate.dart's KNOWN LIMITATION note.
    // Also never joins the running average / counts as an attempt.
    final gateResult = await gateClassifier.classify(latest);
    if (!gateResult.isPlant) {
      provider.rejectGate(gateResult);
      return;
    }

    // Layer 3 — screen the newest photo alone — before it's allowed
    // anywhere near the weighted average — for "this doesn't look like a
    // plant at all" via the species model's own entropy/top-k signal. A
    // single-image classify() call gives that photo's own, unaveraged
    // probability distribution (a weighted average of one item is just
    // itself), which is what RejectionGate needs to compute entropy over.
    final latestOutput = await classifier.classify([latest]);
    final rejectionLevel = _rejectionGate.evaluate(latestOutput.probabilities);

    if (rejectionLevel == RejectionLevel.probablyNotPlant ||
        rejectionLevel == RejectionLevel.definitelyNotPlant) {
      // Never joins the running average and never counts as one of the 3
      // attempts — ScanProvider.rejectLatest() removes it from `images`.
      unawaited(() async {
        try {
          final deviceId = await DeviceId.get();
          await logger.logRejection(deviceId: deviceId);
        } catch (_) {
          // Best-effort — a rejection not making it into analytics isn't
          // worth queueing/retrying the way a real scan's log is.
        }
      }());
      provider.rejectLatest(rejectionLevel);
      return;
    }

    // Redundant work avoided for the common case: with exactly one photo
    // collected so far, `latestOutput` above already *is* the full-batch
    // result (nothing else to average it with).
    final output =
        images.length == 1 ? latestOutput : await classifier.classify(images);

    // Layer 4 — energy-score OOD check (see OodDetector), evaluated on the
    // same combined multi-photo `output` the confidence decision below
    // uses. Guaranteed already loaded here — _ScannerReadinessGate awaits
    // OodDetector.ready before scanning is allowed at all, same as the two
    // TFJS models.
    final oodResult = oodDetector.evaluate(output.logits);

    if (oodResult.isOutOfDistribution) {
      // OOD outranks Claude: skip the background verifier entirely and
      // navigate straight to UnknownPlantScreen rather than let a
      // low-confidence-but-still-76-classes softmax result (or a
      // hypothetical Claude opinion) surface for a photo the feature space
      // says isn't any of the documented species. This is the only place
      // that guarantee needs enforcing — Claude is simply never called
      // below when this branch is taken.
      final closestSpecies =
          _speciesByClassIndex(allSpecies, oodResult.closestClassIndex);
      final closestConfidence =
          oodResult.closestClassIndex < output.probabilities.length
              ? output.probabilities[oodResult.closestClassIndex]
              : 0.0;
      final secondClosestSpecies =
          _speciesByClassIndex(allSpecies, oodResult.secondClosestClassIndex);
      final secondClosestConfidence =
          oodResult.secondClosestClassIndex < output.probabilities.length
              ? output.probabilities[oodResult.secondClosestClassIndex]
              : 0.0;

      // Claude never ran on this path (claudeUsed/claudeChangedPrediction
      // both false by construction) — see ScanDiagnostics.build's own doc
      // comment for why this and identification_logs.model_diagnostics
      // agree with unknown_plant_reports' numbers for the same scan.
      final diagnostics = ScanDiagnostics.build(
        decision: ScanDecision.ood,
        output: output,
        oodResult: oodResult,
        gate: _rejectionGate,
        closestSpecies: closestSpecies,
        claudeUsed: false,
        claudeChangedPrediction: false,
      );

      // Best-effort telemetry, same fire-and-forget/swallow-failure pattern
      // as Layer 3's rejection log above — every OOD verdict is logged
      // automatically here regardless of whether the user goes on to tap
      // "Report Unknown Plant" on the next screen (that button submits a
      // second, higher-signal, user-confirmed report into
      // unknown_plant_reports — see UnknownPlantScreen's own doc comment).
      // Both feed the same knownMultiplier/borderlineMultiplier tuning
      // OodDetector's own doc comment calls for.
      unawaited(() async {
        try {
          final deviceId = await DeviceId.get();
          await logger.logRejection(
            deviceId: deviceId,
            note: 'rejected: ood_unknown_species',
            modelDiagnostics: diagnostics,
          );
        } catch (_) {
          // Best-effort — same tolerance as every other rejection log.
        }
      }());

      router.go('/results/unknown',
          extra: UnknownPlantResult(
            imageBytes: images.first,
            oodResult: oodResult,
            closestSpecies: closestSpecies,
            closestSpeciesConfidence: closestConfidence,
            secondClosestSpecies: secondClosestSpecies,
            secondClosestSpeciesConfidence: secondClosestConfidence,
            diagnostics: diagnostics,
          ));
      return;
    }

    // Hidden background "second opinion" — consulted when the local result
    // is genuinely ambiguous (see shouldActivate) OR the OOD zone is
    // Borderline. Always awaited here, before anything is shown to the
    // user: the existing "Analysing..." state already covers this wait, so
    // there is no separate loading indicator and no risk of a result
    // appearing and then silently changing a moment later. Never visible in
    // the UI — see BackgroundIdentifierService's own doc comment.
    //
    // A borderline-triggers-Claude version of this WAS tried and reverted
    // on 2026-08-07 with the OLD embedding-based OodDetector, because that
    // detector's threshold was unvalidated AND applyResult had no
    // confidence floor at the time — the combination meant more scans got
    // exposed to a Claude override with nothing checking whether Claude was
    // actually sure. Both of those are fixed now: applyResult requires
    // Claude's own confidence_score >= _replacementConfidenceFloor before
    // it can override anything (added in that same review), and OodDetector
    // now scores the classifier's own logits (see its doc comment) instead
    // of an embedding space that real validation showed doesn't separate
    // species well. Re-enabled 2026-08-07 on that basis — see
    // BackgroundIdentifierService.analysePrediction's oodBorderline
    // parameter for what this actually changes about the Claude call.
    BackgroundIdentificationResult? bgResult;
    if (BackgroundIdentifierService.shouldActivate(
          output: output,
          gate: _rejectionGate,
          brightness: qualityResult.brightness,
          variance: qualityResult.variance,
        ) ||
        oodResult.isBorderline) {
      bgResult = await bgIdentifier.analysePrediction(
        images: images,
        output: output,
        oodBorderline: oodResult.isBorderline,
      );
    }
    final adjustedOutput = bgResult == null
        ? output
        : bgIdentifier.applyResult(localOutput: output, bgResult: bgResult);

    // Same diagnostics payload the OOD branch above builds (see
    // ScanDiagnostics.build) — populated for every decision, not just OOD,
    // per that class's own doc comment. decision is never `ood` here: this
    // code only runs once the isOutOfDistribution branch above has already
    // returned.
    final diagnostics = ScanDiagnostics.build(
      decision:
          oodResult.isBorderline ? ScanDecision.borderline : ScanDecision.known,
      output: output,
      oodResult: oodResult,
      gate: _rejectionGate,
      closestSpecies: _speciesByClassIndex(allSpecies, oodResult.closestClassIndex),
      claudeUsed: bgResult != null,
      claudeChangedPrediction:
          bgResult != null && adjustedOutput.classIndex != output.classIndex,
    );

    // isReliable, not just a raw confidence check — a high averaged
    // confidence can still hide the 5 TTA passes disagreeing among
    // themselves (see ClassificationOutput.isReliable).
    final confident = adjustedOutput.isReliable;
    final species =
        confident ? await repository.getByClassIndex(adjustedOutput.classIndex) : null;

    // Logging/profile tracking is analytics, not the critical path — a
    // write failure (most commonly the device being offline, but also
    // e.g. an RLS policy blocking the insert) must not stop the user from
    // seeing their result. This used to `await` both calls before
    // navigating despite this comment saying otherwise — that was the
    // actual cause of the "stuck analysing" complaint, not classifier
    // speed (measured: classify() ~0.4s once warmed, but these two
    // sequential Supabase round-trips were adding 10+ more seconds on top
    // before the user ever saw a result). Fire-and-forget instead.
    // Queueing on failure is what lets an offline scan still count once
    // back online — see OfflineScanQueue.
    unawaited(() async {
      try {
        final deviceId = await DeviceId.get();
        await logger.log(
          classification: adjustedOutput,
          speciesId: species?.id,
          deviceId: deviceId,
          aiAnalysis: bgResult?.toLogJson(),
          modelDiagnostics: diagnostics,
        );
        await profileProvider.recordScan(species?.id, species != null);
        // DashboardProvider is loaded once at app startup and otherwise never
        // refetches — without this, Home's Total Scans/Scans Today/Scan
        // Activity chart and the plant detail modal's "AI Confidence" line
        // stay frozen at whatever they were when the app booted. Uses the
        // provider reference captured up top, not context — by this point
        // (after an await) the widget that owned this context has already
        // been swapped out by startAnalyzing().
        unawaited(dashboardProvider.reload());
      } catch (_) {
        unawaited(offlineQueue.enqueue(PendingScan.fromClassification(
          classification: adjustedOutput,
          speciesId: species?.id,
          isCorrect: species != null,
        )));
      }
    }());

    if (!confident) {
      // Claude's own confidence, independent of the (still honest, never
      // inflated) local-probability number shown above — when it clears
      // BackgroundIdentifierService's own bar, another photo probably
      // won't change the answer, so the retry loop ends now instead of
      // burning a remaining attempt Claude has already effectively
      // resolved. See BackgroundIdentifierService.isStronglyConfident.
      final aiResolved =
          bgResult != null && BackgroundIdentifierService.isStronglyConfident(bgResult);
      if (provider.canAddMoreImages && !aiResolved) {
        provider.needsMoreImages(adjustedOutput);
      } else {
        // Out of attempts, or Claude is confident enough to end the retry
        // loop early — show the best guess with a low-confidence warning
        // rather than a dead-end "couldn't identify" page. This is a
        // separate lookup from `species` above (which stays confidence-
        // gated so logging/profile stats are unaffected) — display-only.
        final bestGuess = await repository.getByClassIndex(adjustedOutput.classIndex);
        router.go('/results',
            extra: IdentificationResult(
              classification: adjustedOutput,
              species: bestGuess,
              imagePath: 'in-memory',
              attemptCount: images.length,
            ));
      }
      return;
    }

    router.go('/results',
        extra: IdentificationResult(
          classification: adjustedOutput,
          species: species,
          imagePath: 'in-memory',
          attemptCount: images.length,
        ));
  } catch (e) {
    provider.setError('Something went wrong. Please try again.');
  }
}

class _PreviewView extends StatelessWidget {
  final Uint8List bytes;
  const _PreviewView({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kBreakpointMd;
        final totalSpecies = context.watch<SpeciesProvider>().totalCount;
        final left = Column(
          children: [
            // Image preview
            ClipRRect(
              borderRadius: kBR2xl,
              child: Container(
                height: 230,
                width: double.infinity,
                color: const Color(0xFFFAC775),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.yard_outlined,
                      size: 64, color: Color(0xFF633806)),
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
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 17, color: kDeep),
                  const SizedBox(width: 9),
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
              Text('Ready to identify',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
              const SizedBox(height: 5),
              Text(
                'The model compares your leaf against $totalSpecies campus species. '
                'Results below 70% confidence prompt a retake.',
                style: TextStyle(fontSize: 12, color: kMu, height: 1.6),
              ),
              const SizedBox(height: 16),
              // The TFjs model starts loading at app boot (see
              // TfjsClassifierService), so this is normally already resolved
              // by the time a user reaches this screen — this FutureBuilder
              // only shows anything on a slow connection's first visit.
              FutureBuilder<void>(
                future: context.read<ClassifierService>().ready,
                builder: (context, snapshot) {
                  final modelReady = snapshot.connectionState == ConnectionState.done;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: modelReady ? () => _runIdentification(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kGreen.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: kBRSm),
                        elevation: 0,
                      ),
                      icon: modelReady
                          ? const Icon(Icons.search_outlined, size: 16)
                          : const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                      label: Text(modelReady ? 'Identify plant' : 'Preparing model...',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.read<ScanProvider>().reset(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kMu,
                    side: BorderSide(color: kBorder, width: 0.5),
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
    );
  }
}


// ─────────────────────────────────────────────────────────────
// STATE 3 — ANALYZING
// ─────────────────────────────────────────────────────────────
class _AnalyzingView extends StatefulWidget {
  final Uint8List bytes;
  const _AnalyzingView({required this.bytes});

  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = context.watch<ScanProvider>().images.length;
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: kBR2xl,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(widget.bytes, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kMint, width: 2),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Align(
                        alignment: Alignment(0, -1 + 2 * _controller.value),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kMint.withValues(alpha: 0),
                                kMint,
                                kMint.withValues(alpha: 0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: kMint.withValues(alpha: 0.8),
                                  blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            CircularProgressIndicator(
              color: kDeep,
              backgroundColor: kLight,
              strokeWidth: 3,
            ),
            const SizedBox(height: 18),
            Text(
              photoCount > 1 ? 'Analysing $photoCount photos...' : 'Analysing your leaf...',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 6),
            Text(
              'Comparing features against '
              '${context.watch<SpeciesProvider>().totalCount} campus species',
              style: TextStyle(fontSize: 13, color: kMu),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 4 — NEEDS MORE IMAGES (low confidence)
// ─────────────────────────────────────────────────────────────
class _NeedsMoreImagesView extends StatelessWidget {
  const _NeedsMoreImagesView();

  Future<void> _addAnotherPhoto(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    context.read<ScanProvider>().addImage(bytes);
    if (!context.mounted) return;
    await _runIdentification(context);
  }

  void _pickSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: kBRXl),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture Image'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addAnotherPhoto(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addAnotherPhoto(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Skips straight to the results screen with the current best guess,
  /// instead of asking for another photo. A separate lookup from the
  /// confidence-gated one in [_runIdentification] — this is display-only
  /// and doesn't touch logging/profile stats.
  Future<void> _useAnyway(BuildContext context) async {
    final provider = context.read<ScanProvider>();
    final output = provider.lastClassification;
    if (output == null) return;
    final repository = context.read<SpeciesRepository>();
    final router = GoRouter.of(context);
    final attemptCount = provider.images.length;
    final species = await repository.getByClassIndex(output.classIndex);
    if (!context.mounted) return;
    router.go('/results',
        extra: IdentificationResult(
          classification: output,
          species: species,
          imagePath: 'in-memory',
          attemptCount: attemptCount,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final confidence = provider.lastConfidence ?? 0;
    final confidencePct = (confidence * 100).round();
    final completedAttempts = provider.images.length;
    final photosLeft = ScanProvider.maxImages - completedAttempts;
    // This view is only ever entered while a retry is still available (see
    // _runIdentification — once attempts run out it routes straight to
    // /results instead), so completedAttempts is always 1 or 2 here.
    final message = completedAttempts >= 2
        ? 'Almost there — one final angle'
        : 'Good start — one more angle will help';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kLight, borderRadius: kBRXl,
        border: Border.all(color: kMint, width: 0.5),
      ),
      child: Column(
        children: [
          _AttemptProgressDots(
              completed: completedAttempts, total: ScanProvider.maxImages),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'A different angle — the flower, bark, or a whole-plant shot — gives the '
            'model more to compare against your first photo.',
            style: TextStyle(fontSize: 12.5, color: kMu, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Thumbnail strip of photos collected so far
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: provider.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: kBRMd,
                child: Image.memory(provider.images[i],
                    width: 64, height: 64, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Combined confidence — accumulates across attempts rather than
          // resetting, since classify() re-runs on every collected photo
          // together (confidence-weighted average, see TfjsClassifierService).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combined confidence',
                  style: TextStyle(fontSize: 12, color: kMu)),
              Text('$confidencePct%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: confidencePct < 70 ? kRetry : kHealthyTx)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confidence.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                children: [
                  Container(height: 6, color: kBorder),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 6, color: kGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickSource(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRetry,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
                elevation: 0,
              ),
              icon: const Icon(Icons.rotate_left, size: 16),
              label: Text('Try Another Angle ($photosLeft left)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _useAnyway(context),
            style: TextButton.styleFrom(foregroundColor: kMu),
            child: const Text('Use this result anyway',
                style: TextStyle(fontSize: 12.5)),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<ScanProvider>().reset(),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMu,
                side: BorderSide(color: kBorder, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
              ),
              child: const Text('Start over', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 5 — REJECTED (RejectionGate decided this isn't a plant photo)
// ─────────────────────────────────────────────────────────────
const _scanTips = [
  'Point camera directly at the leaf',
  'Fill the frame with the plant',
  'Avoid shadows across the leaf',
  'Use natural daylight if possible',
];

class _RejectedView extends StatelessWidget {
  final RejectionLevel level;
  const _RejectedView({required this.level});

  Future<void> _retry(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final provider = context.read<ScanProvider>();
    // If earlier photos in this session were already accepted, keep them —
    // only the rejected photo itself was ever discarded (see
    // ScanProvider.rejectLatest) — and just add the new one on top.
    if (provider.images.isEmpty) {
      provider.setPreview(bytes);
    } else {
      provider.addImage(bytes);
    }
    if (!context.mounted) return;
    await _runIdentification(context);
  }

  void _pickSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: kBRXl),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture Image'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final definite = level == RejectionLevel.definitelyNotPlant;
    // Never null for these two levels — see RejectionGate.getUserMessage.
    final message = _rejectionGate.getUserMessage(level, null)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kUnhealthyBg,
        borderRadius: kBRXl,
        border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 42, color: kUnhealthyTx),
          const SizedBox(height: 14),
          Text(
            definite ? "That doesn't look like a plant" : "Couldn't identify a plant",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(fontSize: 12.5, color: kMu, height: 1.55),
              textAlign: TextAlign.center),
          if (definite) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: kBRLg,
                border: Border.all(color: kBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tips for a good scan:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTx)),
                  const SizedBox(height: 8),
                  ..._scanTips.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 6, right: 9),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen),
                            ),
                            Expanded(
                              child: Text(t,
                                  style: TextStyle(fontSize: 12, color: kMu, height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickSource(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kUnhealthyTx,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
                elevation: 0,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: Text(definite ? 'Scan Again' : 'Try Again',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<ScanProvider>().reset(),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMu,
                side: BorderSide(color: kBorder, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
              ),
              child: const Text('Start over', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 6 — QUALITY REJECTED (ImageQualityChecker caught it pre-inference)
// ─────────────────────────────────────────────────────────────
const _qualityTips = [
  'Move to a well-lit area — natural daylight works best',
  'Make sure the lens isn\'t covered or fogged',
  'Avoid pointing the camera at a blank wall or surface',
  'Hold the camera steady',
];

class _QualityRejectedView extends StatelessWidget {
  final ImageQuality quality;
  const _QualityRejectedView({required this.quality});

  Future<void> _retry(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final provider = context.read<ScanProvider>();
    // Same discard-only-the-rejected-photo behaviour as _RejectedView —
    // see ScanProvider.rejectQuality.
    if (provider.images.isEmpty) {
      provider.setPreview(bytes);
    } else {
      provider.addImage(bytes);
    }
    if (!context.mounted) return;
    await _runIdentification(context);
  }

  void _pickSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: kBRXl),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture Image'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = _qualityChecker.getMessage(quality);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kRetryBg,
        borderRadius: kBRXl,
        border: Border.all(color: kRetry.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 42, color: kRetry),
          const SizedBox(height: 14),
          Text('Image quality too low',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(fontSize: 12.5, color: kMu, height: 1.55),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: kBRLg,
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for a good scan:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTx)),
                const SizedBox(height: 8),
                ..._qualityTips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 9),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: kGreen),
                          ),
                          Expanded(
                            child: Text(t,
                                style: TextStyle(
                                    fontSize: 12, color: kMu, height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickSource(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRetry,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
                elevation: 0,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Try Again',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<ScanProvider>().reset(),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMu,
                side: BorderSide(color: kBorder, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
              ),
              child: const Text('Start over', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATE 7 — GATE REJECTED (binary gate model decided this isn't a plant)
// ─────────────────────────────────────────────────────────────
const _gateTips = [
  'Fill the frame with the plant leaf',
  'Get closer to the plant',
  'Use natural daylight',
  'Avoid photographing the whole tree from far away',
];

class _GateRejectedView extends StatelessWidget {
  final GateResult result;
  const _GateRejectedView({required this.result});

  Future<void> _retry(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final provider = context.read<ScanProvider>();
    // Same discard-only-the-rejected-photo behaviour as _RejectedView —
    // see ScanProvider.rejectGate.
    if (provider.images.isEmpty) {
      provider.setPreview(bytes);
    } else {
      provider.addImage(bytes);
    }
    if (!context.mounted) return;
    await _runIdentification(context);
  }

  void _pickSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: kBRXl),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture Image'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _retry(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kUnhealthyBg,
        borderRadius: kBRXl,
        border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 42, color: kUnhealthyTx),
          const SizedBox(height: 14),
          Text('No plant detected',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(result.message,
              style: TextStyle(fontSize: 12.5, color: kMu, height: 1.55),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: kBRLg,
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips for a good scan:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTx)),
                const SizedBox(height: 8),
                ..._gateTips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 9),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: kGreen),
                          ),
                          Expanded(
                            child: Text(t,
                                style: TextStyle(
                                    fontSize: 12, color: kMu, height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _pickSource(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kUnhealthyTx,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
                elevation: 0,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Scan Again',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<ScanProvider>().reset(),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMu,
                side: BorderSide(color: kBorder, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
              ),
              child: const Text('Start over', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3-dot attempt progress indicator — the just-completed dot bounces in ──
class _AttemptProgressDots extends StatelessWidget {
  final int completed;
  final int total;
  const _AttemptProgressDots({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i < completed;
        final justFilled = i == completed - 1;
        final dot = Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? kRetry : kBorder,
          ),
        );
        if (!justFilled) return dot;
        // Re-keying on `completed` restarts the bounce whenever a new dot
        // becomes the most-recently-filled one.
        return TweenAnimationBuilder<double>(
          key: ValueKey('dot-$i-$completed'),
          tween: Tween(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: dot,
        );
      }),
    );
  }
}
