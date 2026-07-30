import 'package:flutter_test/flutter_test.dart';
import 'package:plantid_app/features/profile/models/achievement_model.dart';

void main() {
  group('achievementById', () {
    test('finds a known achievement by id', () {
      final a = achievementById('first_scan');
      expect(a, isNotNull);
      expect(a!.title, 'First Steps');
    });

    test('returns null for an unknown id', () {
      expect(achievementById('does_not_exist'), isNull);
    });

    test('every achievement id in kAchievements is unique', () {
      final ids = kAchievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
