// lib/features/scan/services/ood_detector.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Which of the three bands [OodDetector.evaluate] placed a scan's [OodResult.score] in.
enum OodZone {
  /// Comfortably below the loaded threshold minus [OodDetector.lowerMargin]
  /// — the classifier's prediction can be trusted at face value.
  known,

  /// Between the two boundaries — plausible, but not confidently in- or
  /// out-of-distribution. Always routed to the background Claude verifier
  /// regardless of [BackgroundIdentifierService.shouldActivate] (see that
  /// class and scan_screen.dart's OOD branch) — the elevated score is
  /// itself a reason to ask for a second opinion.
  borderline,

  /// Above the loaded threshold (see [OodResult.threshold]) — the photo
  /// probably isn't one of the 76 documented species, regardless of how
  /// confident the softmax head's own prediction looks. Claude is skipped
  /// entirely for this zone.
  outOfDistribution,
}

/// Verdict from [OodDetector.evaluate] for one scan's averaged logit vector.
class OodResult {
  /// Which of the three bands [score] landed in.
  final OodZone zone;

  bool get isKnown => zone == OodZone.known;
  bool get isBorderline => zone == OodZone.borderline;
  bool get isOutOfDistribution => zone == OodZone.outOfDistribution;

  /// The energy-based OOD score (see [OodDetector] for the formula) —
  /// larger means less like any of the 76 trained species. NOT a
  /// Euclidean/Mahalanobis distance despite the name of the
  /// `identification_logs.model_diagnostics`/`unknown_plant_reports`
  /// column this ends up logged under (`ood_distance`, kept unchanged for
  /// continuity with rows logged before 2026-08-07's switch to logit-based
  /// scoring — see [OodDetector]'s own doc comment for why that switch
  /// happened). Can be negative; has no natural upper or lower bound.
  final double score;

  /// The upper threshold [score] was compared against — the boundary
  /// between [OodZone.borderline] and [OodZone.outOfDistribution]. Logged
  /// under the legacy `threshold` key for the same continuity reason as
  /// [score]/`ood_distance` above.
  final double threshold;

  /// argmax of the logit vector [evaluate] was given — the species the
  /// classifier itself considers the best match, independent of whether
  /// that match was actually confident enough to trust. Shown as "closest
  /// documented species" on UnknownPlantScreen when [isOutOfDistribution].
  final int closestClassIndex;

  /// Index of the second-highest logit — the classifier's runner-up guess.
  /// Shown alongside [closestClassIndex] on UnknownPlantScreen so a user
  /// sees two candidates, not one, when nothing cleared the OOD bar.
  final int secondClosestClassIndex;

  const OodResult({
    required this.zone,
    required this.score,
    required this.threshold,
    required this.closestClassIndex,
    required this.secondClosestClassIndex,
  });

  @override
  String toString() => 'OodResult(zone: $zone, '
      'score: ${score.toStringAsFixed(4)}, '
      'threshold: ${threshold.toStringAsFixed(4)}, '
      'closestClassIndex: $closestClassIndex, '
      'secondClosestClassIndex: $secondClosestClassIndex)';
}

/// Parsed contents of a .npy file: the flat little-endian float64 payload
/// plus its declared shape, exactly as numpy wrote it. Only understands
/// enough of the format (see [OodDetector.parseNpyForTesting]) to read the
/// single scalar this detector needs — not a general-purpose numpy reader.
class _NpyArray {
  final List<int> shape;
  final Float64List data;
  const _NpyArray(this.shape, this.data);
}

/// Out-of-distribution (OOD) detector for the 76-class UENR Flora species
/// classifier.
///
/// A softmax classifier always outputs a confident-looking distribution
/// over its 76 trained classes, even for a photo of a species it has never
/// seen — RejectionGate's entropy/top-k signals catch some of that, but not
/// a confidently-wrong single-class call (see that class's KNOWN LIMITATION
/// note).
///
/// HISTORY — why this is logit-based, not embedding-based
/// ========================================================
/// The original version of this class (through 2026-08-07) measured
/// Mahalanobis distance from a scan's 1280-dim penultimate-layer feature
/// vector to the nearest of 76 per-species centroids. Real held-out
/// validation (centroids built from ~20 reference photos/species, tested
/// against photos those centroids never saw) showed that embedding space
/// doesn't separate species well enough for this to work reliably: a
/// held-out photo's OWN species' centroid was farther away than some
/// OTHER species' centroid roughly 40% of the time. Root cause: the
/// MobileNetV2 backbone was mostly frozen during training (see
/// training_guide.py's build_model/Phase 1/Phase 2), so that pooled
/// embedding is closer to generic ImageNet-style visual similarity than
/// something trained to discriminate these 76 species — the actual
/// species discrimination lives in the trained Dense head's weights,
/// which the embedding-distance approach never used.
///
/// This version uses those weights instead, via an energy score on the
/// species head's raw logits (see ALGORITHM below) — the same signal that
/// lets the classifier itself get most species right >90% of the time.
/// Known limitation, carried over from the embedding-based version: this
/// still can't reliably catch a case where the model is confidently WRONG
/// (a large winning logit for the wrong species) — only cases where the
/// model is appropriately unsure. That failure mode needs either an
/// explicit "unknown" training class or a genuinely different model, not a
/// post-hoc score on this model's own outputs.
///
/// ALGORITHM
/// =========
/// For a 76-dim logit vector `logits` (the species Dense head's raw
/// pre-softmax output — see web/classifier.js's LOGITS_TENSOR_NAME):
///
/// ```
/// score(logits) = -logSumExp(logits)
///               = -log( Σ exp(logits[i]) )
/// ```
///
/// This is the negative "Helmholtz free energy" of Liu et al.,
/// "Energy-based Out-of-distribution Detection" (NeurIPS 2020) — unlike
/// the softmax probabilities, it isn't normalised to sum to 1, so it keeps
/// the *magnitude* information softmax throws away: a photo the model
/// recognises confidently produces a large positive logit somewhere,
/// making `score` very negative; a photo that doesn't match any trained
/// class well produces smaller logits across the board even when one is
/// still technically the largest, making `score` larger (less negative).
/// Computed via the standard log-sum-exp-with-max-subtraction trick for
/// numerical stability, not that this model's logit range is large enough
/// to need it in practice.
///
/// [evaluate] classifies `score` against two boundaries — the loaded
/// threshold itself, and that threshold minus [lowerMargin] — into an
/// [OodZone].
class OodDetector {
  /// Bundled asset path for the trained upper threshold.
  static const String thresholdAssetPath = 'assets/models/ood_threshold.npy';

  /// Length of the logit vector this detector operates on — the width of
  /// the species Dense head's raw output (same as [numClasses]; kept as a
  /// separate name because it describes [evaluate]'s expected input length,
  /// not a species count).
  static const int logitLength = 76;

  /// Number of documented UENR Flora species.
  static const int numClasses = 76;

  /// The value loaded from [thresholdAssetPath] is the UPPER
  /// (known/borderline → outOfDistribution) boundary directly — see
  /// [evaluate]. [lowerMargin] below is then subtracted from it (not
  /// multiplied — energy scores can be negative, so a multiplicative band
  /// like the old embedding-based detector used would flip which bound is
  /// larger whenever the stored value is negative) to get the
  /// known/borderline boundary.
  ///
  /// `score < upperThreshold - lowerMargin` → [OodZone.known].
  ///
  /// Calibrated 2026-08-07 from ~1900 real campus photos (25/species,
  /// sampled from the actual training dataset, run through this exact
  /// pipeline — not a synthetic estimate) split 80/20 per species into a
  /// centroid/held-out set. Against the held-out 20% (380 photos the
  /// calibration never saw): correctly-classified photos scored a mean
  /// energy of -17.8 (p99 -8.35); misclassified photos scored a
  /// meaningfully worse mean of -12.2 — a real, measured gap, unlike the
  /// retired embedding-based detector's centroid distances, which barely
  /// differed between a photo's own species and its nearest wrong one (see
  /// class doc's HISTORY section). With these numbers, only 2/354 (0.6%)
  /// of correct held-out predictions land in [OodZone.outOfDistribution]
  /// (a hard reject), while 18.9% land in [OodZone.borderline] (routed to
  /// Claude, not rejected). Deliberately generous relative to what a pure
  /// "tightest gap" choice would give: once [OodZone.borderline] means
  /// "always get a second opinion from Claude" rather than "reject
  /// outright" (see scan_screen.dart), casting a wider borderline net
  /// costs an extra API call, not a wrongly-rejected real species.
  static const double lowerMargin = 5.0;

  /// `score > upperThreshold` → [OodZone.outOfDistribution]. Between
  /// `upperThreshold - lowerMargin` and this is [OodZone.borderline]. This
  /// boundary gates the hard "No Reliable Match Found" screen, which is
  /// costly to get wrong on a real species, so [lowerMargin] is kept wide
  /// enough that this only fires when the score is unambiguously past what
  /// real photos of documented species produce. The value stored in
  /// [thresholdAssetPath] as of the 2026-08-07 calibration described on
  /// [lowerMargin] is -8.0 (the 99th percentile of energy scores across all
  /// 380 held-out real photos, correctly classified or not).

  double? _threshold;

  Future<void>? _loadFuture;

  /// Default constructor — the asset is not read until [ready] is first
  /// accessed. See [OodDetector.fromThreshold] for the test-only
  /// alternative that skips asset I/O entirely.
  OodDetector();

  /// Test-only seam — builds an already-loaded detector directly from a
  /// threshold value, bypassing asset I/O entirely. Lets [evaluate]'s pure
  /// math be unit tested without exercising rootBundle (see
  /// test/unit/ood_detector_test.dart), the same seam pattern
  /// BackgroundIdentifierService.testable uses for the same reason.
  @visibleForTesting
  OodDetector.fromThreshold(double threshold) {
    _threshold = threshold;
  }

  /// True once the threshold is loaded and [evaluate] can be called.
  bool get isLoaded => _threshold != null;

  /// Loads and parses the threshold asset, exactly once. Safe to access
  /// from multiple places (e.g. app boot AND a defensive check before the
  /// first scan) — every access after the first awaits the same in-flight
  /// (or already-completed) load rather than re-reading the asset. Unlike
  /// TfjsClassifierService.warmUp/GateClassifierService.loadModel, a
  /// failure here is NOT swallowed: this data is required for [evaluate]
  /// to mean anything, so a load error propagates to every caller
  /// awaiting [ready] instead of silently leaving the detector unusable.
  Future<void> get ready => _loadFuture ??= _load();

  Future<void> _load() async {
    final byteData = await rootBundle.load(thresholdAssetPath);
    final parsed = _parseNpy(byteData, thresholdAssetPath);
    if (parsed.data.isEmpty) {
      throw StateError('$thresholdAssetPath has no data');
    }
    _threshold = parsed.data[0];
  }

  /// Computes the energy score (see class doc's ALGORITHM section) for
  /// [logits] and classifies it into an [OodZone]. Pure and synchronous —
  /// must not be called before [ready] completes (throws [StateError] if
  /// so), which keeps this hot per-scan path free of any awaiting or asset
  /// I/O.
  ///
  /// [logits] must have exactly [logitLength] elements — the species Dense
  /// head's raw pre-softmax output for one scan (see class doc's ALGORITHM
  /// section). Throws [ArgumentError] otherwise, the same "fail loud on a
  /// caller bug" convention as TfjsClassifierService.classify's empty-list
  /// check.
  OodResult evaluate(List<double> logits) {
    final threshold = _threshold;
    if (threshold == null) {
      throw StateError('OodDetector.evaluate called before ready completed');
    }
    if (logits.length != logitLength) {
      throw ArgumentError.value(
        logits.length,
        'logits.length',
        'must equal $logitLength',
      );
    }

    var maxLogit = logits[0];
    var closestClassIndex = 0;
    var secondLogit = double.negativeInfinity;
    var secondClosestClassIndex = 0;
    for (var i = 1; i < logits.length; i++) {
      final logit = logits[i];
      if (logit > maxLogit) {
        secondLogit = maxLogit;
        secondClosestClassIndex = closestClassIndex;
        maxLogit = logit;
        closestClassIndex = i;
      } else if (logit > secondLogit) {
        secondLogit = logit;
        secondClosestClassIndex = i;
      }
    }

    // log-sum-exp with max-subtraction: sum(exp(logits[i] - maxLogit)) is
    // guaranteed <= logits.length (the max term contributes exactly 1),
    // so this can't overflow the way summing raw exp(logits[i]) could for
    // an unusually large logit.
    var sumExp = 0.0;
    for (final logit in logits) {
      sumExp += exp(logit - maxLogit);
    }
    final logSumExp = maxLogit + log(sumExp);
    final score = -logSumExp;

    final lowerCeiling = threshold - lowerMargin;
    final zone = score < lowerCeiling
        ? OodZone.known
        : score <= threshold
            ? OodZone.borderline
            : OodZone.outOfDistribution;

    return OodResult(
      zone: zone,
      score: score,
      threshold: threshold,
      closestClassIndex: closestClassIndex,
      secondClosestClassIndex: secondClosestClassIndex,
    );
  }

  static const List<int> _magic = [0x93, 0x4E, 0x55, 0x4D, 0x50, 0x59]; // \x93NUMPY

  /// Test-only entry point into the .npy parser — see [_parseNpy]. Exposed
  /// so test/unit/ood_detector_test.dart can verify header/shape/dtype
  /// parsing directly against hand-built byte fixtures, without needing a
  /// real asset bundle. Returns a record rather than [_NpyArray] itself
  /// (a private type) so this public-facing signature stays valid.
  @visibleForTesting
  static ({List<int> shape, Float64List data}) parseNpyForTesting(
      ByteData bytes, String label) {
    final parsed = _parseNpy(bytes, label);
    return (shape: parsed.shape, data: parsed.data);
  }

  /// Parses the numpy .npy binary format: a 6-byte magic string, a 2-byte
  /// (v1.0) or 4-byte (v2.0+) little-endian header length, an ASCII
  /// dict-literal header describing dtype/shape/order, then the raw data.
  ///
  /// Supports little-endian float32 (`<f4`) and float64 (`<f8`) C-order
  /// arrays only — the only dtypes/layout numpy's default `np.save`
  /// produces for this asset. Hand-rolled rather than a package
  /// dependency: this is the entire surface this app needs to read, and
  /// the format itself is simple enough that a dependency would cost more
  /// (bundle size, an unaudited transitive dependency) than it saves.
  static _NpyArray _parseNpy(ByteData bytes, String label) {
    for (var i = 0; i < _magic.length; i++) {
      if (bytes.getUint8(i) != _magic[i]) {
        throw FormatException('$label: not a valid .npy file (bad magic)');
      }
    }
    final majorVersion = bytes.getUint8(6);
    var offset = 8;
    int headerLength;
    if (majorVersion == 1) {
      headerLength = bytes.getUint16(offset, Endian.little);
      offset += 2;
    } else {
      headerLength = bytes.getUint32(offset, Endian.little);
      offset += 4;
    }

    final headerBytes = Uint8List.sublistView(bytes, offset, offset + headerLength);
    // The header dict is pure ASCII in practice (dtype code, True/False,
    // integers, punctuation) regardless of declared .npy version, so
    // latin1 (a strict superset) decodes it correctly either way without
    // needing to branch on majorVersion here.
    final header = latin1.decode(headerBytes);
    offset += headerLength;

    final fortranMatch =
        RegExp(r"'fortran_order'\s*:\s*(True|False)").firstMatch(header);
    if (fortranMatch != null && fortranMatch.group(1) == 'True') {
      throw FormatException('$label: fortran-order arrays are not supported');
    }

    final descrMatch = RegExp(r"'descr'\s*:\s*'([^']+)'").firstMatch(header);
    final shapeMatch = RegExp(r"'shape'\s*:\s*\(([^)]*)\)").firstMatch(header);
    if (descrMatch == null || shapeMatch == null) {
      throw FormatException('$label: could not parse .npy header: $header');
    }
    final descr = descrMatch.group(1)!;
    final shape = shapeMatch
        .group(1)!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList(growable: false);

    final elementCount =
        shape.isEmpty ? 1 : shape.reduce((a, b) => a * b);
    final data = Float64List(elementCount);
    final dataBytes = ByteData.sublistView(bytes, offset);

    switch (descr) {
      case '<f4':
        for (var i = 0; i < elementCount; i++) {
          data[i] = dataBytes.getFloat32(i * 4, Endian.little);
        }
        break;
      case '<f8':
        for (var i = 0; i < elementCount; i++) {
          data[i] = dataBytes.getFloat64(i * 8, Endian.little);
        }
        break;
      default:
        throw FormatException(
            '$label: unsupported dtype "$descr" — expected <f4 or <f8');
    }

    return _NpyArray(shape, data);
  }
}
