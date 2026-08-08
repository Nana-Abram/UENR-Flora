// lib/features/scan/services/background_identifier_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/json_utils.dart';
import '../../../models/identification_result.dart';
import '../../../models/plant_species.dart';
import 'rejection_gate.dart';

/// One of the local model's top-5 candidates for a scan, as sent to the
/// `background-identify` edge function and matched back by
/// [candidateNumber] — never by name string, since species names aren't
/// guaranteed unique/stable the way an index into this exact list is.
/// Candidate 1 is always the local top-1 prediction by construction (see
/// BackgroundIdentifierService._buildCandidates, which sorts by local
/// probability descending) — there is no separate "local prediction"
/// type; candidates.first IS it.
class SpeciesMetadata {
  final int candidateNumber;
  final int classIndex;
  final String speciesId;
  final String scientificName;
  final String commonName;
  final String? familyName;
  final String? leafType;
  final String? growthHabit;
  final String? growthType;
  final String? origin;
  // ── Morphology fields (see PlantSpecies' own doc comment) — richer text
  // for Claude to compare a photo against than leafType/familyName alone.
  // Nullable everywhere: populated by a one-time research backfill, not
  // guaranteed present for every one of the 76 species.
  final String? leafArrangement;
  final String? leafMargin;
  final String? venation;
  final String? leafShape;
  final String? leafTexture;
  final String? flowerDescription;
  final String? fruitDescription;
  final String? barkDescription;
  final double localProbability;

  /// Public Supabase Storage URLs of this species' gallery photos (up to 3,
  /// same set shown on its detail page — see PlantSpecies.galleryImageUrls),
  /// passed straight through to the edge function, which attaches them (by
  /// URL, not fetched/re-encoded here) as extra images for however many
  /// top candidates the local model's own confidence margin says need a
  /// visual check (see the edge function's referenceCandidateCount). Empty
  /// for a species with no gallery photos on file; the edge function skips
  /// those rather than failing the whole call. None of the 3 are tagged by
  /// content (no "this one's the leaf close-up" label exists in the
  /// database) — all 3 are sent together so Claude's own vision can do
  /// that distinguishing itself, same as it does with the user's own
  /// multi-angle photos.
  final List<String> referenceImageUrls;

  const SpeciesMetadata({
    required this.candidateNumber,
    required this.classIndex,
    required this.speciesId,
    required this.scientificName,
    required this.commonName,
    required this.localProbability,
    this.familyName,
    this.leafType,
    this.growthHabit,
    this.growthType,
    this.origin,
    this.leafArrangement,
    this.leafMargin,
    this.venation,
    this.leafShape,
    this.leafTexture,
    this.flowerDescription,
    this.fruitDescription,
    this.barkDescription,
    this.referenceImageUrls = const [],
  });

  /// Only the fields useful for the vision model's reasoning — deliberately omits
  /// [speciesId]/[classIndex] (internal matching keys the model has no
  /// reason to see or echo back as free text; it only ever answers with
  /// [candidateNumber]).
  Map<String, dynamic> toPromptJson() => {
        'candidate_number': candidateNumber,
        'scientific_name': scientificName,
        'common_name': commonName,
        if (familyName != null) 'family_name': familyName,
        if (leafType != null) 'leaf_type': leafType,
        if (growthHabit != null) 'growth_habit': growthHabit,
        if (growthType != null) 'growth_type': growthType,
        if (origin != null) 'origin': origin,
        if (leafArrangement != null) 'leaf_arrangement': leafArrangement,
        if (leafMargin != null) 'leaf_margin': leafMargin,
        if (venation != null) 'venation': venation,
        if (leafShape != null) 'leaf_shape': leafShape,
        if (leafTexture != null) 'leaf_texture': leafTexture,
        if (flowerDescription != null) 'flower': flowerDescription,
        if (fruitDescription != null) 'fruit': fruitDescription,
        if (barkDescription != null) 'bark': barkDescription,
        if (referenceImageUrls.isNotEmpty) 'reference_image_urls': referenceImageUrls,
        'local_model_confidence': localProbability,
      };
}

/// Verdict from one background Claude "second opinion" call. Internal
/// only — never constructed from anything but [BackgroundIdentificationResult.failure]
/// or [BackgroundIdentificationResult.fromJson] (itself always wrapped in
/// a try/catch by the caller), and never read by any UI widget.
class BackgroundIdentificationResult {
  final bool success;
  final String? errorMessage;

  final bool agreesWithLocalPrediction;
  final bool replacementRecommended;
  final bool isDatabaseSpecies;

  final String? suggestedSpecies; // commonName — logging only
  final String? scientificName; // logging only

  /// Raw `suggested_candidate_number` straight off the wire (1-N, or an
  /// out-of-range/missing value) — deliberately kept separate from
  /// [suggestedClassIndex] below, which is a different number (the real
  /// PlantSpecies.modelClassIndex) only ever filled in AFTER this raw
  /// value has been validated against the actual candidate list. Internal
  /// to the fromJson → _resolveVerdict pipeline; not meant to be read by
  /// callers of [analysePrediction].
  final int? suggestedCandidateNumber;

  /// Raw `suggested_species_id` straight off the wire — only ever
  /// meaningful when [suggestedCandidateNumber] is 0, meaning Claude
  /// rejected all 5 numbered candidates but recognised the plant as a
  /// DIFFERENT species from the full UENR Flora database list it was also
  /// given (see [BackgroundIdentifierService._buildFullSpeciesList]).
  /// Never trusted directly — [BackgroundIdentifierService._resolveVerdict]
  /// re-resolves it against the client's own species list before it can
  /// end up in [suggestedSpeciesId] below.
  final String? outsideSpeciesId;

  /// The next three are only ever populated by
  /// [BackgroundIdentifierService._resolveVerdict] resolving
  /// [suggestedCandidateNumber] (or [outsideSpeciesId]) against the
  /// client's own candidate/species lists — never trusted directly off
  /// the network. See that method for why.
  final String? suggestedSpeciesId;
  final int? suggestedClassIndex;
  final double? suggestedLocalProbability;

  /// The vision model's own self-reported confidence. Logged verbatim (see
  /// [toLogJson]) and, when [BackgroundIdentifierService.applyResult]
  /// actually replaces the local prediction with this verdict's candidate,
  /// this IS the confidence value shown to the user from that point on —
  /// see that method's own doc comment for why (once Claude's pick has
  /// overridden the local model, the displayed number should reflect how
  /// sure the thing that made the call actually was). Otherwise unused —
  /// keeping the local model's own confidence exactly as computed.
  final double confidenceScore;

  /// Short internal note — persisted to ai_analysis for QA, never shown
  /// in any UI.
  final String? reasoning;

  const BackgroundIdentificationResult({
    required this.success,
    this.errorMessage,
    this.agreesWithLocalPrediction = false,
    this.replacementRecommended = false,
    this.isDatabaseSpecies = false,
    this.suggestedSpecies,
    this.scientificName,
    this.suggestedCandidateNumber,
    this.outsideSpeciesId,
    this.suggestedSpeciesId,
    this.suggestedClassIndex,
    this.suggestedLocalProbability,
    this.confidenceScore = 0,
    this.reasoning,
  });

  factory BackgroundIdentificationResult.failure(String message) =>
      BackgroundIdentificationResult(success: false, errorMessage: message);

  /// Parses the edge function's raw JSON body. Only ever called from
  /// inside [BackgroundIdentifierService.analysePrediction]'s try/catch —
  /// a malformed success:true payload throws FormatException (via
  /// [requireField]), which that caller converts to [failure] rather than
  /// letting it propagate. Does NOT resolve `suggested_candidate_number`/
  /// `suggested_species_id` into an actual species — that cross-check
  /// against the real candidate/full-species lists happens afterward in
  /// `_resolveVerdict`.
  factory BackgroundIdentificationResult.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      return BackgroundIdentificationResult.failure(
          (json['error_message'] as String?) ?? 'unknown edge function error');
    }
    const table = 'background-identify response';
    return BackgroundIdentificationResult(
      success: true,
      agreesWithLocalPrediction:
          requireField<bool>(json, 'agrees_with_local', table: table),
      replacementRecommended:
          requireField<bool>(json, 'replacement_recommended', table: table),
      isDatabaseSpecies:
          requireField<bool>(json, 'is_database_species', table: table),
      suggestedSpecies: json['suggested_species_common_name'] as String?,
      scientificName: json['suggested_species_scientific_name'] as String?,
      suggestedCandidateNumber:
          (json['suggested_candidate_number'] as num?)?.toInt(),
      // Only ever present on the wire when suggested_candidate_number is 0
      // AND Claude picked a species outside the 5 numbered candidates —
      // see outsideSpeciesId's own doc comment.
      outsideSpeciesId: json['suggested_species_id'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] as String?,
    );
  }

  /// JSONB payload for `identification_logs.ai_analysis` — server-side QA
  /// data only, never read back by the app, never rendered in any UI.
  Map<String, dynamic> toLogJson() => {
        'success': success,
        if (!success) 'error': errorMessage,
        if (success) ...{
          'agrees_with_local': agreesWithLocalPrediction,
          'replacement_recommended': replacementRecommended,
          'is_database_species': isDatabaseSpecies,
          'suggested_species_id': suggestedSpeciesId,
          'suggested_class_index': suggestedClassIndex,
          'suggested_local_probability': suggestedLocalProbability,
          'ai_confidence': confidenceScore,
          'reasoning': reasoning,
        },
      };
}

typedef _EdgeFunctionInvoker = Future<FunctionResponse> Function(
  String name, {
  required Map<String, dynamic> body,
});

typedef _ImageResizer = Future<Uint8List> Function(Uint8List bytes);

/// Default resizer for [BackgroundIdentifierService.testable] — a no-op
/// passthrough, since unit tests supply their own [Uint8List] fixtures
/// and don't exercise the real web/image_resize.js path at all.
Future<Uint8List> _passthroughResize(Uint8List bytes) async => bytes;

/// Hidden background "second opinion" layer, consulted only when the
/// local MobileNetV2 classifier's own result is ambiguous (see
/// [shouldActivate]). Proxies through the `background-identify` Supabase
/// Edge Function rather than calling Claude directly — the API key never
/// ships inside the public Flutter web bundle. Never visible in any UI:
/// no badge, no "verified" text, no separate loading state. Every public
/// method here either returns a plain value/result object or is called
/// from a context that already tolerates any outcome (see
/// [analysePrediction] — it never throws).
class BackgroundIdentifierService {
  final _EdgeFunctionInvoker _invoke;
  // A closure, not a captured List — SpeciesProvider.all is reassigned on
  // every reload, so this must re-read at call time, not once at
  // construction time (main.dart wires this as `() => ctx.read<SpeciesProvider>().all`).
  final List<PlantSpecies> Function() _allSpecies;
  // Injected rather than imported directly — see
  // lib/features/scan/services/image_upload_resizer.dart's own comment
  // for why this file can't import dart:js_interop itself.
  final _ImageResizer _resizeForUpload;

  BackgroundIdentifierService(
    SupabaseClient client,
    this._allSpecies,
    this._resizeForUpload,
  ) : _invoke = ((name, {required body}) =>
            client.functions.invoke(name, body: body));

  /// Test-only seam — bypasses the real Supabase client entirely, letting
  /// unit tests supply a fake invoker without any mocking package (this
  /// codebase has none — see test/unit/rejection_gate_test.dart's style).
  @visibleForTesting
  BackgroundIdentifierService.testable(
    this._invoke,
    this._allSpecies, [
    this._resizeForUpload = _passthroughResize,
  ]);

  // ── Activation thresholds ──────────────────────────────────────────
  // Was 0.95 — lowered to 0.85 to fire on fewer scans (only genuinely
  // more uncertain ones), reducing Claude call volume/quota pressure now
  // that real usage data is coming in, at the cost of catching a
  // narrower band of ambiguous cases than before. Reused by Rule 1 below.
  static const double _confidenceCeiling = 0.85;

  /// The 16 species with per-class accuracy below 80% on the held-out test
  /// split (15% of all images, stratified, never seen during training —
  /// see training_guide.py Cell 5's split and Cell 14's
  /// classification_report). Values are [PlantSpecies.modelClassIndex] —
  /// see class_names.json for the index↔folder-name mapping this was
  /// translated from — not folder-name strings, since that's what
  /// [ClassificationOutput.classIndex]/[probabilities] are actually indexed
  /// by. Species with very few test images (Moringa n=9, Silktree n=7)
  /// carry more variance in their measured percentage; that uncertainty is
  /// itself the reason they're kept in this set rather than dropped —
  /// erring toward a Claude check costs an API call, erring the other way
  /// costs a silently wrong answer.
  ///
  /// Narrowed 2026-08-07 from a purely confidence-based trigger (fired on
  /// ~65% of scans, including species the local model already handles
  /// well) to this species-aware one. Expected to fire on ~15-20% of
  /// scans: the 46 species above 90% test accuracy will almost never
  /// trigger [shouldActivate] now; these 16 still get verification when
  /// genuinely uncertain (Rule 1); any species below 60% raw confidence
  /// still gets Claude as a safety net regardless of which one it is
  /// (Rule 2).
  static const Set<int> _weakSpeciesClassIndices = {
    2, // African_Tulip_Tree   75.0%    8 test images
    4, // Alchornea            72.7%   11 test images
    8, // Avocado              77.5%   40 test images
    23, // Croton               71.4%   14 test images
    27, // Flamboyant           65.0%   20 test images
    31, // Gmelina              78.9%   19 test images
    33, // Golden_Dewdrop       68.0%   25 test images
    39, // Madagascar_Almond    69.2%   13 test images
    41, // Mango                78.6%   56 test images
    46, // Moringa              55.6%    9 test images
    55, // Pawpaw               76.7%   30 test images
    60, // Rose_Apple           77.8%   18 test images
    63, // Silktree             71.4%    7 test images
    67, // Teak                 77.3%   22 test images
    70, // Tropical_Almond      50.0%   10 test images
    74, // Womans_Tongue        55.6%   18 test images
  };

  /// Below this, Claude is consulted regardless of species (Rule 2) — the
  /// model is lost enough that even a strong species isn't worth trusting
  /// alone.
  static const double _lowConfidenceSafetyNet = 0.60;

  /// Below this, the top-2 margin counts as "narrow" for Rule 3 — the
  /// species head couldn't cleanly separate its top two candidates.
  static const double _narrowMarginThreshold = 0.15;
  // Was 30s under Gemini (measured ~25s real round trips there, driven by
  // that model generation's mandatory, non-disableable "thinking" mode —
  // see the background-identify edge function's own comment). Switched to
  // Claude specifically to remove that tax (extended thinking is opt-in
  // there and deliberately left off for this call), paired with the edge
  // function's own 15s internal budget — this leaves 5s of headroom above
  // that for function cold start + network, not a measured Claude ceiling
  // yet. Tighten further once real ai_analysis telemetry comes in.
  static const Duration _timeout = Duration(seconds: 20);
  static const int _candidateCount = 5;

  // How sure Claude has to be, in its own self-reported terms, before its
  // verdict is trusted enough to end the photo-retry loop early — see
  // [isStronglyConfident]. 0.80, not measured, a starting point like every
  // other threshold here; tune from ai_analysis telemetry once this ships.
  static const double _aiResolveThreshold = 0.80;

  // Claude's own self-reported confidence must clear this before its pick
  // is trusted enough to actually REPLACE the local model's prediction —
  // see [applyResult]. Below it, a replacement recommendation is treated
  // the same as "Claude agrees" (rule 1 there): keep the local result
  // unchanged rather than swap in a guess Claude itself wasn't sure about.
  //
  // Added 2026-08-07 after a review of a reported high wrong-species rate:
  // [applyResult] previously overrode the local prediction on ANY
  // replacement_recommended:true verdict from the edge function, with
  // nothing checking how confident Claude actually said it was — the edge
  // function sets that flag for any picked candidate regardless of its own
  // confidence_score. Combined with shouldActivate firing on the majority
  // of scans (see _confidenceCeiling), this meant a large share of results
  // could be silently replaced by a low-certainty Claude guess. Same value
  // as kConfidenceThreshold (lib/core/constants.dart) — the bar the rest of
  // the app already uses to call a result "confident enough to show",
  // applied here to the thing about to make the actual decision.
  static const double _replacementConfidenceFloor = kConfidenceThreshold;

  /// No warm-up needed (unlike the TFJS classifiers — there's no model to
  /// download/compile client-side; the actual model call happens entirely
  /// server-side). Kept only so main.dart's provider wiring has something
  /// symmetrical to call if it ever wants to; safe to never call at all.
  Future<void> initialise() async {}

  /// Pure, synchronous, no I/O — a clean/confident scan of a species the
  /// local model handles well never triggers a network call. Species-aware
  /// as of 2026-08-07 (see [_weakSpeciesClassIndices]) rather than the
  /// purely confidence-based rule this replaced — three rules, any one of
  /// which fires:
  ///   1. The predicted species is one of the 16 measured-weak ones AND
  ///      confidence is below [_confidenceCeiling] — a weak species with
  ///      any meaningful uncertainty is exactly the case Claude adds real
  ///      value on.
  ///   2. Confidence is below [_lowConfidenceSafetyNet] regardless of
  ///      species — the model is genuinely lost, not just unsure about a
  ///      historically-tricky one.
  ///   3. The top two candidates are within [_narrowMarginThreshold] of
  ///      each other AND both are weak species — if the model is torn
  ///      between two species it's historically bad at, that's worth a
  ///      second opinion; if it's torn between two species it's normally
  ///      good at, it's probably right anyway.
  ///
  ///      NOTE: as specified (implemented faithfully below), Rule 3 can
  ///      never actually change this method's return value — it's
  ///      mathematically unreachable, not just usually redundant. A margin
  ///      below 0.15 forces confidence(top1) < ~0.575 (from
  ///      top1 + top2 ≤ 1 and top1 − top2 < 0.15), which is already below
  ///      [_lowConfidenceSafetyNet] (0.60), so Rule 2 always returns true
  ///      first regardless of either candidate's species. Kept exactly as
  ///      specified rather than removed; flagging here so a future reader
  ///      doesn't mistake the dead branch for a bug and "fix" it into
  ///      doing something unintended.
  ///
  /// [gate]/[brightness]/[variance] are no longer used by any rule here
  /// (the old entropy/margin/image-quality-based triggers were dropped,
  /// not folded into the species-aware rules above) — kept as parameters
  /// purely so the call site (scan_screen.dart) doesn't need to change;
  /// safe to pass or omit either way.
  static bool shouldActivate({
    required ClassificationOutput output,
    required RejectionGate gate,
    double? brightness,
    double? variance,
  }) {
    final confidence = output.confidence;
    final species = output.classIndex;

    // Rule 1 — weak species with any meaningful uncertainty.
    if (_weakSpeciesClassIndices.contains(species) &&
        confidence < _confidenceCeiling) {
      return true;
    }

    // Rule 2 — any species, very low confidence.
    if (confidence < _lowConfidenceSafetyNet) return true;

    // Rule 3 — model torn between two candidates that are both weak
    // species.
    if (output.probabilities.length >= 2) {
      final indices = List<int>.generate(output.probabilities.length, (i) => i)
        ..sort((a, b) => output.probabilities[b].compareTo(output.probabilities[a]));
      final top2Index = indices[1];
      final top2Margin =
          output.probabilities[indices[0]] - output.probabilities[top2Index];
      if (top2Margin < _narrowMarginThreshold &&
          _weakSpeciesClassIndices.contains(species) &&
          _weakSpeciesClassIndices.contains(top2Index)) {
        return true;
      }
    }

    return false;
  }

  /// True when a completed [analysePrediction] call came back confident
  /// enough (by Claude's own self-reported [BackgroundIdentificationResult.confidenceScore],
  /// whether it agreed with the local top pick or recommended a
  /// replacement) that another photo probably won't change the answer.
  ///
  /// Deliberately does NOT change what confidence number ever gets shown
  /// to the user — [applyResult] still only ever displays the chosen
  /// candidate's own local probability, exactly as before. This only
  /// answers a different question: whether to keep asking for more
  /// photos. The caller (scan_screen.dart) uses this to end the retry
  /// loop early — same "show the best guess, with the low-confidence
  /// banner if it's still below threshold" treatment the app already
  /// gives a scan that ran out of attempts, just reached sooner instead
  /// of burning 1-2 more photos Claude has already effectively resolved.
  static bool isStronglyConfident(BackgroundIdentificationResult result) =>
      result.success && result.confidenceScore > _aiResolveThreshold;

  /// Sorted-by-local-probability top 5, resolved against the in-memory
  /// species list (already fully loaded at app startup by SpeciesProvider
  /// — zero extra Supabase queries here). Skips any class index with no
  /// matching row rather than crashing the scan over a data gap that
  /// shouldn't happen in practice.
  List<SpeciesMetadata> _buildCandidates(ClassificationOutput output) {
    final species = _allSpecies();
    final probs = output.probabilities;
    final indices = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final result = <SpeciesMetadata>[];
    for (final i in indices.take(_candidateCount)) {
      PlantSpecies? match;
      for (final s in species) {
        if (s.modelClassIndex == i) {
          match = s;
          break;
        }
      }
      if (match == null) continue;
      result.add(SpeciesMetadata(
        candidateNumber: result.length + 1,
        classIndex: i,
        speciesId: match.id,
        scientificName: match.scientificName,
        commonName: match.commonName,
        familyName: match.familyName,
        leafType: match.leafType,
        growthHabit: match.growthHabit,
        growthType: match.growthType,
        origin: match.origin,
        leafArrangement: match.leafArrangement,
        leafMargin: match.leafMargin,
        venation: match.venation,
        leafShape: match.leafShape,
        leafTexture: match.leafTexture,
        flowerDescription: match.flowerDescription,
        fruitDescription: match.fruitDescription,
        barkDescription: match.barkDescription,
        localProbability: probs[i],
        referenceImageUrls: match.galleryImageUrls,
      ));
    }
    return result;
  }

  /// Every species in the database, reduced to just the fields Claude
  /// needs to name one it wasn't offered as a numbered candidate — sent
  /// alongside (not instead of) the top-5 [SpeciesMetadata] list, so a
  /// photo the local model ranked outside its own top 5 can still resolve
  /// correctly instead of always falling through to "uncertain, try
  /// another angle" once none of the 5 numbered candidates fit. Deliberately
  /// text-only (no reference photos, no other metadata) — this list exists
  /// to be searched by name/id, not visually compared, and keeping it to
  /// three short strings per row keeps the extra payload to a few KB
  /// regardless of database size, unlike the per-candidate reference
  /// images (which do add real latency — see MAX_REFERENCE_IMAGES in the
  /// edge function).
  List<Map<String, dynamic>> _buildFullSpeciesList() => _allSpecies()
      .map((s) => {
            'species_id': s.id,
            'scientific_name': s.scientificName,
            'common_name': s.commonName,
          })
      .toList();

  /// Calls the `background-identify` edge function. [images] is every
  /// photo collected so far in this scan session (not just the newest
  /// one) — on a 2nd/3rd attempt, Claude sees exactly the same set of
  /// angles the local model's own combined-average [output] was computed
  /// from, instead of judging from a single photo while reasoning about a
  /// multi-photo confidence number. Never throws — every failure mode (no
  /// candidates resolved, network error, timeout, FunctionException,
  /// malformed/non-Map response body, malformed success:true JSON)
  /// degrades to a `success: false` result, per the "the app must always
  /// work even when this layer is unavailable" contract.
  ///
  /// [oodBorderline] — true when scan_screen.dart's OodDetector call placed
  /// this scan in [OodZone.borderline] (see that enum), which always routes
  /// here regardless of [shouldActivate]. Forwarded to the edge function as
  /// `ood_borderline` in the request body, which appends an extra prompt
  /// instruction telling Claude the local feature signal suggests this
  /// might not be one of the 76 documented species at all — Claude's
  /// existing candidate-0 ("none of these") response already covers that
  /// outcome; this just makes it more likely to actually pick it when
  /// warranted, instead of defaulting to its closest (still-wrong) numbered
  /// candidate.
  Future<BackgroundIdentificationResult> analysePrediction({
    required List<Uint8List> images,
    required ClassificationOutput output,
    bool oodBorderline = false,
  }) async {
    try {
      if (images.isEmpty) {
        return BackgroundIdentificationResult.failure('no images to analyse');
      }
      final candidates = _buildCandidates(output);
      if (candidates.isEmpty) {
        return BackgroundIdentificationResult.failure(
            'no candidate species resolved');
      }

      // Downscaled/recompressed specifically for this upload — this call
      // already sends each image over the network twice (browser → edge
      // function → vision model), and the model is only picking among 5
      // already-known candidates, not doing fine-grained taxonomy from a
      // full-resolution capture. Falls back to the original bytes
      // internally on any failure (see web/image_resize.js), so this can
      // never be the reason the call doesn't go out. Resized in parallel,
      // not sequentially — each is an independent canvas round-trip.
      final uploadImages = await Future.wait(images.map(_resizeForUpload));

      final response = await _invoke('background-identify', body: {
        'images': uploadImages
            .map((bytes) => {
                  'data': base64Encode(bytes),
                  'mime_type': _sniffMimeType(bytes),
                })
            .toList(),
        'candidates': candidates.map((c) => c.toPromptJson()).toList(),
        'all_species': _buildFullSpeciesList(),
        if (oodBorderline) 'ood_borderline': true,
      }).timeout(_timeout);

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return BackgroundIdentificationResult.failure(
            'malformed response shape');
      }
      final parsed = BackgroundIdentificationResult.fromJson(data);
      return _resolveVerdict(parsed, candidates, output);
    } on TimeoutException {
      return BackgroundIdentificationResult.failure('timeout');
    } on FunctionException catch (e) {
      return BackgroundIdentificationResult.failure('function error: $e');
    } catch (e) {
      return BackgroundIdentificationResult.failure('unexpected error: $e');
    }
  }

  /// Defense against the edge function (or the model inside it) claiming a
  /// replacement that isn't actually one of the species we told it about —
  /// independent of the equivalent check the edge function itself performs
  /// server-side (defense in depth, not redundant trust). This is also
  /// where [BackgroundIdentificationResult.suggestedSpeciesId]/
  /// [suggestedClassIndex]/[suggestedLocalProbability] actually get filled
  /// in — never from anything the wire response says beyond a candidate
  /// number / species id.
  ///
  /// Two ways a replacement resolves:
  ///  1. `suggestedCandidateNumber` 1-N → matched by
  ///     [SpeciesMetadata.candidateNumber] against [candidates], never by
  ///     name string (same as before this method grew a second case).
  ///  2. `suggestedCandidateNumber` 0 with [BackgroundIdentificationResult.outsideSpeciesId]
  ///     set → Claude rejected all N numbered candidates but named a
  ///     DIFFERENT database species from the full list it was also given.
  ///     Matched by id against [_allSpecies], and — since that species was
  ///     never one of [output]'s top candidates — its local probability is
  ///     looked up directly from [output.probabilities] by class index,
  ///     the same source every other displayed confidence in the app comes
  ///     from. A photo the local model ranked outside its own top 5 can
  ///     still end up shown, but only ever at that class's own true local
  ///     probability — same "never force a prediction" guarantee as case 1.
  ///
  /// Anything that doesn't resolve either way (out-of-range number, or an
  /// outside id that doesn't match any known species) downgrades to "no
  /// replacement" rather than trust an unverifiable pick.
  BackgroundIdentificationResult _resolveVerdict(
    BackgroundIdentificationResult result,
    List<SpeciesMetadata> candidates,
    ClassificationOutput output,
  ) {
    if (!result.success || !result.replacementRecommended) return result;

    final number = result.suggestedCandidateNumber;

    if (number != null && number >= 1) {
      SpeciesMetadata? match;
      for (final c in candidates) {
        if (c.candidateNumber == number) {
          match = c;
          break;
        }
      }
      if (match != null) {
        return BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpecies: match.commonName,
          scientificName: match.scientificName,
          suggestedSpeciesId: match.speciesId,
          suggestedClassIndex: match.classIndex,
          suggestedLocalProbability: match.localProbability,
          confidenceScore: result.confidenceScore,
          reasoning: result.reasoning,
        );
      }
    } else if (number == 0 && result.outsideSpeciesId != null) {
      PlantSpecies? match;
      for (final s in _allSpecies()) {
        if (s.id == result.outsideSpeciesId) {
          match = s;
          break;
        }
      }
      if (match != null) {
        final classIndex = match.modelClassIndex;
        final probability = classIndex >= 0 && classIndex < output.probabilities.length
            ? output.probabilities[classIndex]
            : 0.0;
        return BackgroundIdentificationResult(
          success: true,
          agreesWithLocalPrediction: false,
          replacementRecommended: true,
          isDatabaseSpecies: true,
          suggestedSpecies: match.commonName,
          scientificName: match.scientificName,
          suggestedSpeciesId: match.id,
          suggestedClassIndex: classIndex,
          suggestedLocalProbability: probability,
          confidenceScore: result.confidenceScore,
          reasoning: result.reasoning,
        );
      }
    }

    // Unverifiable pick — downgrade to "no replacement" rather than trust
    // a candidate number / species id that doesn't correspond to anything
    // we actually sent.
    return BackgroundIdentificationResult(
      success: true,
      agreesWithLocalPrediction: result.agreesWithLocalPrediction,
      replacementRecommended: false,
      isDatabaseSpecies: false,
      confidenceScore: result.confidenceScore,
      reasoning: result.reasoning,
    );
  }

  /// Applies a prior [analysePrediction] result to [localOutput]. Pure,
  /// synchronous. Implements the 3 decision priorities:
  ///   1. Claude agrees, never ran, the call failed, or Claude DID
  ///      recommend a replacement but its own confidence_score falls below
  ///      [_replacementConfidenceFloor] → keep [localOutput] exactly as-is.
  ///      That last case is deliberate, not an oversight: the edge function
  ///      sets replacement_recommended purely from WHICH candidate Claude
  ///      picked, never from how sure it said it was — without this floor,
  ///      a low-certainty Claude guess overrode the local prediction just
  ///      as readily as a confident one (see _replacementConfidenceFloor's
  ///      own doc comment for the production data that surfaced this).
  ///   2. A replacement Claude was actually confident about → swap
  ///      classIndex/confidence to that candidate, using Claude's OWN
  ///      self-reported [BackgroundIdentificationResult.confidenceScore]
  ///      as the displayed confidence (not the candidate's local
  ///      probability) — deliberate product choice: once Claude has
  ///      overridden the local model's pick, the number shown should
  ///      reflect how sure the thing that actually made the call is, not
  ///      the local model's opinion of a candidate it originally ranked
  ///      lower. [suggestedLocalProbability] is still resolved and logged
  ///      (see [toLogJson]) for QA comparison, just no longer displayed.
  ///   3. Claude itself is uncertain → same as rule 1, keep [localOutput]
  ///      and let the existing needsMoreImages/best-guess flow continue
  ///      exactly as it would have without this feature.
  ///
  /// [ClassificationOutput.isReliable] is recomputed automatically from
  /// whatever this returns — no new threshold logic needed.
  ClassificationOutput applyResult({
    required ClassificationOutput localOutput,
    required BackgroundIdentificationResult bgResult,
  }) {
    if (!bgResult.success ||
        !bgResult.replacementRecommended ||
        bgResult.confidenceScore < _replacementConfidenceFloor) {
      return localOutput;
    }
    return ClassificationOutput(
      classIndex: bgResult.suggestedClassIndex!,
      confidence: bgResult.confidenceScore,
      healthStatus: localOutput.healthStatus,
      healthConfidence: localOutput.healthConfidence,
      probabilities: localOutput.probabilities,
      ttaAgreement: localOutput.ttaAgreement,
      logits: localOutput.logits,
    );
  }

  /// PNG magic-number sniff; everything else defaults to image/jpeg (the
  /// only other format this app's camera/gallery capture ever produces).
  String _sniffMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }
}
