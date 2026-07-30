// lib/features/scan/services/rejection_gate.dart
import 'dart:math';

/// How confidently a single classification looks like a real plant photo,
/// from most to least trustworthy. Distinct from "is the species right" —
/// this is about whether the *image itself* looks like a plant at all,
/// which the raw softmax output can't tell you from confidence alone (a
/// photo of a wall can still land 90%+ on some class if that's the closest
/// match among 76 options — entropy across the whole distribution is what
/// actually separates "confidently the wrong plant" from "not a plant").
enum RejectionLevel {
  confident, // confidence >= threshold, distribution isn't spread out
  lowConfidencePlant, // below threshold but plausible — ask for another angle
  probablyNotPlant, // high entropy or very low confidence
  definitelyNotPlant, // both at once — reject outright
}

/// Screens a single photo's raw probability vector for "this doesn't look
/// like a plant at all" before it's allowed to contribute to the
/// multi-photo weighted average (see TfjsClassifierService.classify) —
/// otherwise a photo of, say, a hand or a wall gets treated exactly like a
/// blurry plant photo and silently drags the combined confidence around.
class RejectionGate {
  static const double confidenceThreshold = 0.70;
  static const double hardRejectConfidence = 0.20;
  static const double entropyReject = 0.85;
  static const double entropyHardReject = 0.90;
  static const int numClasses = 76;

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

  /// Evaluated most-severe-first: by the time a distribution reaches the
  /// [confidenceThreshold] check at the bottom, it's already known to have
  /// entropy under [entropyReject] (any higher and one of the two reject
  /// branches above would have already caught it) — so "confident" here
  /// always implies both high confidence AND low entropy, without needing
  /// a separate redundant entropy check on that branch.
  RejectionLevel evaluate(List<double> probs) {
    final maxProb = probs.isEmpty ? 0.0 : probs.reduce(max);
    final entropy = computeEntropy(probs);

    if (entropy >= entropyHardReject && maxProb <= hardRejectConfidence) {
      return RejectionLevel.definitelyNotPlant;
    }
    if (entropy >= entropyReject || maxProb <= hardRejectConfidence) {
      return RejectionLevel.probablyNotPlant;
    }
    if (maxProb >= confidenceThreshold) {
      return RejectionLevel.confident;
    }
    return RejectionLevel.lowConfidencePlant;
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
}
