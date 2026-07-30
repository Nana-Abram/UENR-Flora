import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/challenge/services/challenge_service.dart';

void main() {
  final today = DateTime(2026, 7, 27);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('streakFromDates', () {
    test('returns 0 for no completions at all', () {
      expect(streakFromDates({}, now: today), 0);
    });

    test('counts 1 when only today was completed', () {
      expect(streakFromDates({daysAgo(0)}, now: today), 1);
    });

    test('still counts from yesterday when today has not been attempted yet', () {
      // e.g. it's morning and the device hasn't done today's challenge —
      // the streak shouldn't already look broken before the day is over.
      expect(streakFromDates({daysAgo(1)}, now: today), 1);
    });

    test('counts consecutive days ending today', () {
      expect(streakFromDates({daysAgo(0), daysAgo(1), daysAgo(2)}, now: today), 3);
    });

    test('counts consecutive days ending yesterday when today is missing', () {
      expect(streakFromDates({daysAgo(1), daysAgo(2)}, now: today), 2);
    });

    test('stops at a gap instead of counting through it', () {
      // 4 days ago is completed but 3 days ago is not — the streak should
      // stop at the gap, not skip over it.
      expect(streakFromDates({daysAgo(0), daysAgo(1), daysAgo(4)}, now: today), 2);
    });

    test('returns 0 when the most recent completion is older than yesterday', () {
      expect(streakFromDates({daysAgo(3)}, now: today), 0);
    });
  });
}
