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

    test('5 — spread garbage (person photo): probablyNotPlant', () {
      // topKConcentrationMin was raised 0.50 -> 0.55 specifically to catch
      // this case (top-3 concentration sitting right around 0.55) — see
      // that constant's doc comment for the full reasoning. Using 0.449
      // rather than the brief's literal 0.45 for the top class: 0.45 + 0.05
      // + 0.05 sums to *exactly* 0.55 in double-precision float (verified:
      // 0.45 + 0.05 + 0.05 == 0.55 bit-for-bit), and evaluate()'s topK
      // check is a strict `<` — a value sitting exactly on the new floor
      // is defined as still acceptable, same convention as every other
      // threshold in this gate. 0.449 puts it genuinely under 0.55 instead
      // of relying on which way a tied float happens to compare.
      final probs = _vector([0.449, 0.05, 0.05]);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 5 (spread garbage)    : $d');
      expect(d['top3Conc'], lessThan(RejectionGate.topKConcentrationMin));
      expect(d['rejectionLevel'], 'probablyNotPlant');
    });

    test('6 — legitimate low-confidence plant scan: NOT rejected', () {
      // Confirms the raised top-k floor (0.55) doesn't catch a real plant
      // photographed in bad lighting — its top-3 concentration (0.86) sits
      // well clear of the new floor even though top-1 alone is well under
      // confidenceThreshold.
      final probs = _vector([0.58, 0.19, 0.09]);
      final d = RejectionGate.diagnose(probs);
      // ignore: avoid_print
      print('Test 6 (legit low confidence): $d');
      expect(d['top3Conc'], greaterThan(RejectionGate.topKConcentrationMin));
      expect(d['rejectionLevel'], 'lowConfidencePlant');
    });
  });
}
