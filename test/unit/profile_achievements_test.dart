import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/profile/models/profile_model.dart';
import 'package:plantid_app/features/profile/services/profile_service.dart';

UserProfile _profile({
  int totalScans = 0,
  int longestStreak = 0,
  List<String> speciesFound = const [],
  List<int> articlesRead = const [],
}) {
  final now = DateTime(2026, 7, 27);
  return UserProfile(
    deviceId: 'test-device',
    displayName: 'Test',
    avatarEmoji: '🌱',
    totalPoints: 0,
    level: 1,
    streakDays: 0,
    longestStreak: longestStreak,
    totalScans: totalScans,
    totalCorrect: 0,
    totalChallenges: 0,
    speciesFound: speciesFound,
    articlesRead: articlesRead,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('profileOnlyUnlockedAchievements', () {
    test('unlocks nothing for a brand-new profile', () {
      expect(profileOnlyUnlockedAchievements(_profile(), {}), isEmpty);
    });

    test('unlocks first_scan at exactly 1 scan', () {
      final result = profileOnlyUnlockedAchievements(_profile(totalScans: 1), {});
      expect(result.map((a) => a.id), contains('first_scan'));
    });

    test('unlocks multiple scan-count achievements at once when thresholds are skipped', () {
      // e.g. a bulk import or a device that jumps straight to 50 scans
      // should still get credit for the 1/10/50 milestones it passed.
      final result = profileOnlyUnlockedAchievements(_profile(totalScans: 50), {});
      final ids = result.map((a) => a.id).toSet();
      expect(ids, {'first_scan', 'ten_scans', 'fifty_scans'});
    });

    test('does not re-unlock an achievement already recorded', () {
      final result = profileOnlyUnlockedAchievements(
        _profile(totalScans: 1),
        {'first_scan'},
      );
      expect(result, isEmpty);
    });

    test('unlocks streak achievements off longestStreak, not the current streak', () {
      final result = profileOnlyUnlockedAchievements(_profile(longestStreak: 7), {});
      final ids = result.map((a) => a.id).toSet();
      expect(ids, {'streak_3', 'streak_7'});
    });

    test('unlocks ten_species and articles_five off list lengths', () {
      final result = profileOnlyUnlockedAchievements(
        _profile(
          speciesFound: List.generate(10, (i) => 'species-$i'),
          articlesRead: List.generate(5, (i) => i),
        ),
        {},
      );
      final ids = result.map((a) => a.id).toSet();
      expect(ids, {'ten_species', 'articles_five'});
    });
  });
}
