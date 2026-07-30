import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/profile/models/profile_model.dart';

void main() {
  group('levelForPoints', () {
    test('returns Seedling for 0 and just-below-next-threshold points', () {
      expect(levelForPoints(0).level, 1);
      expect(levelForPoints(199).level, 1);
    });

    test('returns the exact level whose threshold is met', () {
      expect(levelForPoints(200).level, 2);
      expect(levelForPoints(500).level, 3);
      expect(levelForPoints(1000).level, 4);
      expect(levelForPoints(2000).level, 5);
    });

    test('caps at the highest level for points beyond it', () {
      expect(levelForPoints(999999).level, 5);
    });

    test('never returns a level below 1 for negative input', () {
      expect(levelForPoints(-50).level, 1);
    });
  });

  group('nextLevelAfter', () {
    test('returns the following level for a mid-range level', () {
      expect(nextLevelAfter(2)?.level, 3);
    });

    test('returns null once at the highest level', () {
      expect(nextLevelAfter(5), isNull);
    });

    test('returns null for an unrecognised level number', () {
      expect(nextLevelAfter(99), isNull);
    });
  });
}
