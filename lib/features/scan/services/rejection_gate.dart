// lib/features/scan/services/rejection_gate.dart
import 'dart:math';

// KNOWN LIMITATION: A softmax classifier trained on plant images will
// sometimes assign high confidence to a single non-plant image if that
// image visually resembles features the model learned (e.g. a red object
// resembling Flamboyant, a green wall resembling Bamboo). The entropy +
// top-k gate below catches spread-distribution garbage inputs but cannot
// reliably detect all confident misclassifications without a dedicated
// binary plant/not-plant pre-screening model.
//
// For a robust permanent fix, train a binary MobileNetV2 gate model
// (plant vs not_plant) and run it before the 76-class species classifier.
// This is documented as future work in Chapter 5.
//
// Current gate catches uniform-distribution and moderately-spread garbage
// inputs. Confidently wrong single-class predictions (e.g. a red object
// classified as Flamboyant at 89%) remain a known false-negative case
// requiring a dedicated binary pre-screening model to resolve.

/// How confidently a single classification looks like a real plant photo,
/// from most to least trustworthy. Distinct from "is the species right" —
/// this is about whether the *image itself* looks like a plant at all,
/// which the raw softmax output can't tell you from confidence alone (a
/// photo of a wall can still land 90%+ on some class if that's the closest
/// match among 76 options — entropy and top-k concentration across the
/// whole distribution are what actually separate "confidently the wrong
/// plant" from "not a plant", most of the time — see the limitation above).
enum RejectionLevel {
  confident, // confidence >= threshold, distribution isn't spread out
  lowConfidencePlant, // below threshold but plausible — ask for another angle
  probablyNotPlant, // high entropy or low top-k concentration
  definitelyNotPlant, // both at once — reject outright
}

/// Screens a single photo's raw probability vector for "this doesn't look
/// like a plant at all" before it's allowed to contribute to the
/// multi-photo weighted average (see TfjsClassifierService.classify) —
/// otherwise a photo of, say, a hand or a wall gets treated exactly like a
/// blurry plant photo and silently drags the combined confidence around.
class RejectionGate {
  static const double confidenceThreshold = 0.70;
  static const double entropyReject = 0.70;
  static const double entropyHardReject = 0.80;
  static const int numClasses = 76;

  /// A real plant photo tends to have its probability mass concentrated in
  /// a handful of visually-similar species (the top few candidates), even
  /// when the model isn't sure which one — a garbage photo spreads mass
  /// much more evenly across many unrelated species instead. Below this,
  /// even a distribution with a deceptively high top-1 confidence is
  /// treated as suspect (see the top-k check in [evaluate]).
  ///
  /// Raised from 0.50 to 0.55 — the 0.50 floor let a "spread but not too
  /// spread" garbage read (top-3 concentration sitting right around 0.55)
  /// fall through as a plausible low-confidence plant photo instead of
  /// getting flagged, since it wasn't low enough to trip the old floor and
  /// its entropy fell short of [entropyReject] too (that ceiling is
  /// unchanged — see test/unit/rejection_gate_test.dart for why). 0.55
  /// catches exactly that ambiguous band without pulling in genuine
  /// low-confidence plant scans, whose top-3 concentration tends to run
  /// well above it even in bad lighting (see Test 6).
  static const double topKConcentrationMin = 0.55;

  /// Shannon entropy of [probs], normalised to [0, 1] by dividing by the
  /// maximum possible entropy for [numClasses] classes (log2(numClasses) —
  /// the entropy of a uniform distribution, the least-confident case
  /// possible). 0 means the model put all its mass on one class; 1 means
  /// it's completely undecided across every class — the hallmark of an
  /// image that doesn't resemble any of the 76 trained species.
  double computeEntropy(List<double> probs) {
    if (probs.isEmpty) return 0.0;
    var sumBits = 0.0;
    for (final p in probs) {
      if (p <= 0) continue; // 0 * log2(0) is conventionally 0, not NaN
      sumBits -= p * (log(p) / ln2);
    }
    final maxBits = log(numClasses) / ln2;
    if (maxBits <= 0) return 0.0;
    return (sumBits / maxBits).clamp(0.0, 1.0);
  }

  /// Sum of the [k] largest probabilities — how much of the model's total
  /// "belief" sits with its top few candidates. High for a real plant photo
  /// (even an unsure one: the top few guesses are usually visually-similar
  /// species), low for a photo that doesn't resemble any trained species.
  double computeTopKConcentration(List<double> probs, {int k = 3}) {
    final sorted = List<double>.from(probs)..sort((a, b) => b.compareTo(a));
    return sorted.take(k).fold(0.0, (sum, p) => sum + p);
  }

  /// Combines three signals — confidence, normalised entropy, and top-3
  /// concentration — since confidence alone is unreliable on out-of-
  /// distribution input (see the KNOWN LIMITATION note at the top of this
  /// file): a garbage image can still land a deceptively high top-1 score,
  /// but it tends to spread the *rest* of its probability mass much more
  /// evenly across unrelated species than a real plant photo does, which
  /// entropy and top-k concentration both pick up on independently.
  RejectionLevel evaluate(List<double> probs) {
    final confidence = probs.isEmpty ? 0.0 : probs.reduce(max);
    final normEntropy = computeEntropy(probs);
    final topK = computeTopKConcentration(probs);

    // Hard reject: high entropy AND low top-3 concentration — both signals
    // agreeing the distribution is genuinely spread out, not just a single
    // ambiguous top-1 call.
    if (normEntropy > entropyHardReject && topK < topKConcentrationMin) {
      return RejectionLevel.definitelyNotPlant;
    }
    // Soft reject: either signal alone is bad enough to be suspicious.
    if (normEntropy > entropyReject || topK < topKConcentrationMin) {
      return RejectionLevel.probablyNotPlant;
    }
    if (confidence < confidenceThreshold) {
      return RejectionLevel.lowConfidencePlant;
    }
    return RejectionLevel.confident;
  }

  /// User-facing copy for a rejection. Returns null for [confident] and
  /// [lowConfidencePlant] — those are handled by the existing multi-scan
  /// retry flow (see ScanProvider/scan_screen.dart), not by this gate.
  String? getUserMessage(RejectionLevel level, String? speciesName) {
    switch (level) {
      case RejectionLevel.definitelyNotPlant:
        return 'No plant detected — point the camera directly at a leaf '
            'or branch and try again.';
      case RejectionLevel.probablyNotPlant:
        return "Cannot identify this image — make sure the plant fills "
            'most of the frame and try again.';
      case RejectionLevel.lowConfidencePlant:
      case RejectionLevel.confident:
        return null;
    }
  }

  /// Threshold-tuning helper — computes every signal [evaluate] uses plus
  /// the level it lands on, for one probability vector, without touching
  /// the classifier or the app. See test/unit/rejection_gate_test.dart for
  /// worked examples across all four levels.
  static Map<String, dynamic> diagnose(List<double> probs) {
    final gate = RejectionGate();
    final confidence = probs.isEmpty ? 0.0 : probs.reduce(max);
    final normEntropy = gate.computeEntropy(probs);
    final topK = gate.computeTopKConcentration(probs);
    final level = gate.evaluate(probs);

    return {
      'confidence': confidence,
      'normEntropy': normEntropy,
      'top3Conc': topK,
      'rejectionLevel': level.name,
    };
  }
}
