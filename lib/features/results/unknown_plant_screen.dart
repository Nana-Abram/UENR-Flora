// lib/features/results/unknown_plant_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/device_id.dart';
import '../../models/plant_species.dart';
import '../../widgets/app_footer.dart';
import '../scan/services/ood_detector.dart';
import '../scan/services/unknown_plant_reporter.dart';

/// Everything [UnknownPlantScreen] needs, built once by scan_screen.dart's
/// _runIdentification when [OodResult.isOutOfDistribution] is true —
/// analogous to IdentificationResult for the normal /results route, but
/// scoped to just this screen (nothing else consumes it) rather than
/// lib/models.
class UnknownPlantResult {
  /// The user's own captured photo (the first of however many were
  /// collected this attempt) — shown directly, unlike the normal results
  /// flow (which always shows a species' canonical reference photo, never
  /// the user's own capture): there's no confirmed species here to show a
  /// reference photo *of*.
  final Uint8List imageBytes;

  final OodResult oodResult;

  /// The species the classifier's own logits ranked highest (see
  /// [OodResult.closestClassIndex]) — null only if that class index doesn't
  /// resolve to a species row (a data gap, not expected in practice). Never
  /// presented as an actual identification — see the "possible match only"
  /// framing below.
  final PlantSpecies? closestSpecies;

  /// The local softmax probability for [closestSpecies]'s class — shown as
  /// an approximate ("~") figure. Deliberately not [OodResult.score]/
  /// [OodResult.threshold] themselves: a raw energy score means nothing to
  /// a user the way a familiar 0-100% figure does, even an explicitly
  /// hedged one.
  final double closestSpeciesConfidence;

  /// The classifier's runner-up guess (see [OodResult.secondClosestClassIndex])
  /// — shown as a second, equally-hedged "possible match only" card next to
  /// [closestSpecies] so the user sees the model's actual top-2 rather than
  /// just its single best (and still untrusted) guess. Same null-only-on-a-
  /// data-gap caveat as [closestSpecies].
  final PlantSpecies? secondClosestSpecies;

  /// The local softmax probability for [secondClosestSpecies]'s class — same
  /// "approximate" framing as [closestSpeciesConfidence].
  final double secondClosestSpeciesConfidence;

  /// The exact same map ScanDiagnostics.build produced for this scan's
  /// identification_logs.model_diagnostics entry — passed through so
  /// "Report Unknown Plant" (see [_ReportButton]) submits numbers that
  /// always agree with that automatic log, rather than recomputing them.
  final Map<String, dynamic> diagnostics;

  const UnknownPlantResult({
    required this.imageBytes,
    required this.oodResult,
    required this.closestSpecies,
    required this.closestSpeciesConfidence,
    required this.secondClosestSpecies,
    required this.secondClosestSpeciesConfidence,
    required this.diagnostics,
  });
}

/// Shown instead of the normal ResultsScreen only when OodDetector decided
/// a scan's feature vector doesn't resemble any of the 76 documented
/// species closely enough to trust (see OodDetector's own doc comment for
/// the algorithm, and BackgroundIdentifierService/scan_screen.dart's
/// _runIdentification for why Claude is never consulted on this path).
/// Every other outcome (confident, low-confidence-retry, borderline-then-
/// Claude-resolved) still lands on the unchanged normal ResultsScreen.
class UnknownPlantScreen extends StatelessWidget {
  final UnknownPlantResult result;
  const UnknownPlantScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // CustomScrollView + SliverFillRemaining (same pattern as scan_screen's
    // _ScanBody) rather than a plain SingleChildScrollView — a Column
    // footer only ever sits directly beneath the content, so on a short
    // "No Reliable Match Found" page (nothing to scroll) it floats in the
    // middle of the viewport instead of anchoring to the bottom edge. This
    // pins it to the bottom when content is short, while still scrolling
    // normally once content exceeds the viewport.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 16, kSp24, kSp36),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= kBreakpointMd;
                        final image = _CapturedImage(bytes: result.imageBytes);
                        final info = _UnknownInfo(result: result);
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 260, child: image),
                                  const SizedBox(width: 24),
                                  Expanded(child: info),
                                ],
                              )
                            : Column(
                                children: [image, const SizedBox(height: 20), info]);
                      },
                    ),
                  ),
                ],
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
                message:
                    'UENR Flora Environmental Learning Hub. Group 4 Final Year Project',
                elevated: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top bar: same "Back to scanner" link as ResultsScreen's own _TopBar, ──
// ── but without the health pill/read-aloud button — there's no confirmed ──
// ── species result here for either of those to describe. ──────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 18, kSp24, 0),
      child: TextButton.icon(
        onPressed: () => context.go('/scan'),
        style: TextButton.styleFrom(foregroundColor: kMu, padding: EdgeInsets.zero),
        icon: const Icon(Icons.arrow_back_outlined, size: 16),
        label: Text('Back to scanner', style: TextStyle(fontSize: 12, color: kMu)),
      ),
    );
  }
}

class _CapturedImage extends StatelessWidget {
  final Uint8List bytes;
  const _CapturedImage({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: kBRXl,
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: kLight,
            child: Center(child: Icon(Icons.eco_outlined, size: 56, color: kDeep)),
          ),
        ),
      ),
    );
  }
}

class _UnknownInfo extends StatelessWidget {
  final UnknownPlantResult result;
  const _UnknownInfo({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.help_outline, size: 26, color: kRetry),
            const SizedBox(width: 10),
            Expanded(
              child: Text('No Reliable Match Found',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600, color: kTx)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'This plant could not be confidently matched with any of the 76 '
          'documented species currently included in the UENR Flora database.',
          style: TextStyle(fontSize: 13.5, color: kMu, height: 1.6),
        ),
        const SizedBox(height: 8),
        Text(
          'It may represent an undocumented campus species, a cultivated '
          'ornamental, or the photograph may not contain enough identifying '
          'information.',
          style: TextStyle(fontSize: 13.5, color: kMu, height: 1.6),
        ),
        const SizedBox(height: 20),
        _ClosestMatchCards(result: result),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: kBRSm),
              elevation: 0,
            ),
            child: const Text('Scan Again',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/explorer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kTx,
              side: BorderSide(color: kBorder, width: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: kBRSm),
            ),
            child: const Text('Browse All Species', style: TextStyle(fontSize: 13.5)),
          ),
        ),
        const SizedBox(height: 10),
        _ReportButton(result: result),
      ],
    );
  }
}

// ── Faded "these are our best (unreliable) guesses" cards — the model's ──
// ── actual top-2, clearly subordinate to the "no match" verdict above. ───
// ── Side by side on wide screens, stacked on narrow ones. ─────────────────
class _ClosestMatchCards extends StatelessWidget {
  final UnknownPlantResult result;
  const _ClosestMatchCards({required this.result});

  @override
  Widget build(BuildContext context) {
    final first = _MatchCard(
      label: 'CLOSEST DOCUMENTED SPECIES · POSSIBLE MATCH ONLY',
      species: result.closestSpecies,
      confidence: result.closestSpeciesConfidence,
      fallbackText: 'No close match found',
    );
    // Only worth a second card when it actually resolved to a species row —
    // the fallback "No close match found" text only makes sense once, for
    // the first card, so a null second candidate is dropped rather than
    // duplicating that fallback.
    final second = result.secondClosestSpecies == null
        ? null
        : _MatchCard(
            label: 'SECOND CLOSEST SPECIES · POSSIBLE MATCH ONLY',
            species: result.secondClosestSpecies,
            confidence: result.secondClosestSpeciesConfidence,
            fallbackText: 'No close match found',
          );

    if (second == null) return first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kBreakpointMd;
        if (!isWide) {
          return Column(
              children: [first, const SizedBox(height: 10), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String label;
  final PlantSpecies? species;
  final double confidence;
  final String fallbackText;
  const _MatchCard({
    required this.label,
    required this.species,
    required this.confidence,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();

    return Opacity(
      opacity: 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: kBRLg,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kWhite),
              child: Icon(Icons.eco_outlined, size: 20, color: kDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: kMu)),
                  const SizedBox(height: 5),
                  Text(
                    species?.commonName ?? fallbackText,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
                  ),
                  if (species != null) ...[
                    const SizedBox(height: 1),
                    Text(species!.scientificName,
                        style: TextStyle(
                            fontSize: 12.5, fontStyle: FontStyle.italic, color: kMu)),
                    const SizedBox(height: 5),
                    Text('~$pct% approximate confidence',
                        style: TextStyle(fontSize: 12, color: kMu)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportState { idle, sending, sent }

/// User-initiated "yes, this really is unrecognized" signal — higher-signal
/// than OodDetector's own automatic rejection log (see
/// scan_screen.dart's _runIdentification, which logs every OOD verdict
/// regardless of whether this button is ever pressed) for later tuning of
/// OodDetector.lowerMargin/upperThreshold from real telemetry. Prompts for
/// optional location/notes (see [_ReportForm]) before uploading the photo
/// and submitting via [UnknownPlantReporter].
class _ReportButton extends StatefulWidget {
  final UnknownPlantResult result;
  const _ReportButton({required this.result});

  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<_ReportButton> {
  _ReportState _state = _ReportState.idle;

  Future<void> _report() async {
    final form = await showModalBottomSheet<_ReportFormResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl))),
      builder: (_) => const _ReportForm(),
    );
    // Null means the sheet was dismissed/cancelled rather than submitted —
    // leave the button exactly as it was, no report sent.
    if (form == null || !mounted) return;

    setState(() => _state = _ReportState.sending);
    final reporter = context.read<UnknownPlantReporter>();
    try {
      final deviceId = await DeviceId.get();
      await reporter.submit(
        imageBytes: widget.result.imageBytes,
        deviceId: deviceId,
        diagnostics: widget.result.diagnostics,
        locationDescription: form.locationDescription,
        notes: form.notes,
      );
      if (!mounted) return;
      setState(() => _state = _ReportState.sent);
    } catch (_) {
      if (!mounted) return;
      // Back to idle (not a separate "failed" state) so the button itself
      // is the retry action — no extra UI needed beyond the snackbar.
      setState(() => _state = _ReportState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send report — please try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _state == _ReportState.sent;
    final sending = _state == _ReportState.sending;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: sent || sending ? null : _report,
        style: TextButton.styleFrom(
          foregroundColor: sent ? kGreen : kMu,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: sending
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: kMu),
              )
            : Icon(sent ? Icons.check_circle_outline : Icons.flag_outlined, size: 15),
        label: Text(
          sent ? 'Thanks — reported' : 'Report Unknown Plant',
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }
}

class _ReportFormResult {
  final String? locationDescription;
  final String? notes;
  const _ReportFormResult({this.locationDescription, this.notes});
}

/// Optional location/notes prompt shown before a report actually submits —
/// both map straight to unknown_plant_reports.location_description/notes
/// (see supabase/unknown_plant_reports.sql). Owns its own TextEditingControllers
/// (disposed on close) since a bottom sheet's builder re-runs on every
/// rebuild of whatever's still on screen behind it.
class _ReportForm extends StatefulWidget {
  const _ReportForm();

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: kSp20,
        right: kSp20,
        top: kSp20,
        bottom: kSp20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Unknown Plant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTx)),
          const SizedBox(height: 6),
          Text(
            'Optional — helps with reviewing undocumented campus species later.',
            style: TextStyle(fontSize: 12, color: kMu, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Where was this?',
              hintText: 'e.g. near the Faculty of Engineering',
              border: OutlineInputBorder(borderRadius: kBRMd),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'Anything else worth mentioning',
              border: OutlineInputBorder(borderRadius: kBRMd),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kMu,
                    side: BorderSide(color: kBorder, width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: kBRSm),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _ReportFormResult(
                      locationDescription: _blankToNull(_locationController.text),
                      notes: _blankToNull(_notesController.text),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: kBRSm),
                    elevation: 0,
                  ),
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
