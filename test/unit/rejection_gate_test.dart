import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/scan/services/rejection_gate.dart';

/// Builds a 76-class probability vector: [named] are the top few classes'
/// exact probabilities, and everything left over is spread evenly across
/// the remaining classes — mirrors how a real softmax output looks (a
/// handful of standout classes plus a long, roughly-flat tail).
List<double> _vector(List<double> named, {int totalClasses = RejectionGate.numClasses}) {
  final remainingCount = totalClasses - named.length;
  final remainingTotal = 1.0 - named.fold(0.0, (a, b) => a + b);
  final tail = remainingCount > 0 ? remainingTotal / remainingCount : 0.0;
  return [...named, ...List.filled(remainingCount, tail)];
}

void main() {
  group('RejectionGate.diagnose', () {
    test('1 — solid white image (89.9% on one class): confident (known false negative)', () {
      // This is the exact case that motivated the top-k signal in the first
      // place (see rejection_gate.dart's KNOWN LIMITATION note) — a solid
      // white test image scored 89.9% on a real species live. Low entropy
      // + high top-3 concentration both say "this looks like a real,
      // unambiguous plant call", because from the softmax's point of view,
      // it genuinely does. Neither entropy nor top-k concentration can
      // catch a confidently-wrong single-class call — only a dedicated
      // plant/not-plant pre-screen model could (documented as future work).
      final probs = _vector([0.899]);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 1 (solid white)      : $d');
      expect(d['rejectionLevel'], 'confident');
    });

    test('2 — uniform distribution (maximum confusion): definitelyNotPlant', () {
      final probs = List.filled(RejectionGate.numClasses, 1 / RejectionGate.numClasses);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 2 (uniform)           : $d');
      expect(d['rejectionLevel'], 'definitelyNotPlant');
    });

    test('3 — realistic confident plant scan: confident', () {
      final probs = _vector([0.82, 0.07, 0.04]);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 3 (realistic confident): $d');
      expect(d['rejectionLevel'], 'confident');
    });

    test('4 — low confidence but real plant: lowConfidencePlant', () {
      final probs = _vector([0.55, 0.22, 0.12]);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 4 (low confidence plant): $d');
      expect(d['rejectionLevel'], 'lowConfidencePlant');
    });

    test('5 — spread garbage (person photo): lands on lowConfidencePlant, '
        'NOT probablyNotPlant — documents a real gap between the two signals', () {
      // The brief for this case ("top class ~0.45, next ~10 classes each
      // 0.04-0.06, top-3 concentration ~0.55") was expected to land on
      // probablyNotPlant. It doesn't, and can't, with the exact thresholds
      // given (entropyReject: 0.70, topKConcentrationMin: 0.50):
      //
      //   - top-3 = 0.55 is comfortably above topKConcentrationMin (0.50),
      //     so the top-k signal never fires.
      //   - Given top-3 fixed at 0.55, the *maximum possible* normalised
      //     entropy (spreading the remaining 0.45 as evenly as possible
      //     across the other 73 classes — the single best case for
      //     tripping this signal) is ~0.68, still short of entropyReject
      //     (0.70). Verified below with that exact maximally-spread tail.
      //
      // So a distribution with top-3 in roughly the 0.50-0.68 range and a
      // sub-threshold top-1 falls all the way through to lowConfidencePlant
      // (treated as "maybe a real, blurry plant photo — ask for another
      // angle") instead of being flagged as suspicious. Left as-is rather
      // than silently retuned — see the deploy notes for the concrete
      // options (nudge topKConcentrationMin up, or entropyReject down).
      final probs = _vector([0.45, 0.05, 0.05]); // max-even tail — the
      // most-favorable case for tripping entropyReject; still doesn't.
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 5 (spread garbage)    : $d');
      expect(d['top3Conc'], closeTo(0.55, 0.001));
      expect(d['normEntropy'], lessThan(RejectionGate.entropyReject));
      expect(d['rejectionLevel'], 'lowConfidencePlant');
    });
  });
}
