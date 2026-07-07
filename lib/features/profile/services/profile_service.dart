// lib/features/profile/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/device_id.dart';
import '../models/achievement_model.dart';
import '../models/profile_model.dart';

/// One row from `identification_logs`, shaped for the Profile screen's
/// "Recent Activity" list.
class RecentScan {
  final String speciesName;
  final DateTime date;
  final bool matched;
  const RecentScan({required this.speciesName, required this.date, required this.matched});
}

class ProfileService {
  final SupabaseClient _client;
  ProfileService(this._client);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<UserProfile> getOrCreateProfile(String deviceId) async {
    final existing =
        await _client.from('user_profiles').select().eq('device_id', deviceId).maybeSingle();
    if (existing != null) return UserProfile.fromJson(existing);

    final inserted = await _client
        .from('user_profiles')
        .insert({'device_id': deviceId})
        .select()
        .single();
    return UserProfile.fromJson(inserted);
  }

  Future<UserProfile> updateProfile(String deviceId, {String? name, String? emoji}) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['display_name'] = name;
    if (emoji != null) updates['avatar_emoji'] = emoji;
    final row = await _client
        .from('user_profiles')
        .update(updates)
        .eq('device_id', deviceId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  Future<UserProfile> addPoints(String deviceId, int points) async {
    final profile = await getOrCreateProfile(deviceId);
    final newPoints = profile.totalPoints + points;
    final row = await _client
        .from('user_profiles')
        .update({
          'total_points': newPoints,
          'level': levelForPoints(newPoints).level,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('device_id', deviceId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  /// [speciesId] is null when the scan didn't confidently match a species —
  /// it still counts toward `total_scans` but not toward `species_found`.
  /// (`total_correct` is reserved for daily-challenge accuracy — see
  /// [recordChallengeCompletion] — since Section C's "X% accuracy" figure
  /// is defined as total_correct / total_challenges.)
  Future<UserProfile> recordScan(String deviceId, String? speciesId, bool isCorrect) async {
    final profile = await getOrCreateProfile(deviceId);
    final species = (isCorrect && speciesId != null)
        ? {...profile.speciesFound, speciesId}.toList()
        : profile.speciesFound;
    final row = await _client
        .from('user_profiles')
        .update({
          'total_scans': profile.totalScans + 1,
          'species_found': species,
          'last_active_date': _dateKey(DateTime.now()),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('device_id', deviceId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  Future<UserProfile> recordArticleRead(String deviceId, int articleId) async {
    final profile = await getOrCreateProfile(deviceId);
    if (profile.articlesRead.contains(articleId)) return profile;
    final articles = [...profile.articlesRead, articleId];
    final row = await _client
        .from('user_profiles')
        .update({
          'articles_read': articles,
          'last_active_date': _dateKey(DateTime.now()),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('device_id', deviceId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  /// Not part of the original spec's method list, but without it
  /// `streak_days`/`longest_streak`/`total_challenges` would never move —
  /// call this from the Daily Challenge submit flow so streak-based
  /// achievements have something to check against.
  Future<UserProfile> recordChallengeCompletion(
    String deviceId, {
    required bool isCorrect,
    required int pointsEarned,
  }) async {
    final profile = await getOrCreateProfile(deviceId);
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    var streak = profile.streakDays;
    if (isCorrect) {
      final last = profile.lastActiveDate;
      if (last == null) {
        streak = 1;
      } else {
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        streak = diff == 1 ? streak + 1 : (diff == 0 ? streak : 1);
      }
    } else {
      streak = 0;
    }
    final longest = streak > profile.longestStreak ? streak : profile.longestStreak;
    final newPoints = profile.totalPoints + pointsEarned;

    final row = await _client
        .from('user_profiles')
        .update({
          'total_challenges': profile.totalChallenges + 1,
          'total_correct': profile.totalCorrect + (isCorrect ? 1 : 0),
          'total_points': newPoints,
          'level': levelForPoints(newPoints).level,
          'streak_days': streak,
          'longest_streak': longest,
          'last_active_date': todayKey,
          'updated_at': today.toIso8601String(),
        })
        .eq('device_id', deviceId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  Future<List<String>> getUnlockedAchievements(String deviceId) async {
    final rows = await _client
        .from('user_achievements')
        .select('achievement_id')
        .eq('device_id', deviceId);
    return rows.map((r) => r['achievement_id'] as String).toList();
  }

  /// achievement_id → unlocked_at, used to show the unlock date on the
  /// Achievements grid.
  Future<Map<String, DateTime>> getUnlockDates(String deviceId) async {
    final rows = await _client
        .from('user_achievements')
        .select('achievement_id, unlocked_at')
        .eq('device_id', deviceId);
    return {
      for (final r in rows)
        r['achievement_id'] as String: DateTime.parse(r['unlocked_at'] as String),
    };
  }

  Future<List<Achievement>> checkAndUnlockAchievements(String deviceId) async {
    final profile = await getOrCreateProfile(deviceId);
    final unlocked = (await getUnlockedAchievements(deviceId)).toSet();
    final newlyUnlocked = <Achievement>[];

    void maybeUnlock(String id, bool condition) {
      if (condition && !unlocked.contains(id)) {
        final a = achievementById(id);
        if (a != null) newlyUnlocked.add(a);
      }
    }

    maybeUnlock('first_scan', profile.totalScans >= 1);
    maybeUnlock('ten_scans', profile.totalScans >= 10);
    maybeUnlock('fifty_scans', profile.totalScans >= 50);
    maybeUnlock('ten_species', profile.speciesFound.length >= 10);
    maybeUnlock('articles_five', profile.articlesRead.length >= 5);
    maybeUnlock('streak_3', profile.longestStreak >= 3);
    maybeUnlock('streak_7', profile.longestStreak >= 7);
    maybeUnlock('streak_30', profile.longestStreak >= 30);

    if (profile.speciesFound.isNotEmpty) {
      final speciesRows = await _client
          .from('plant_species')
          .select('id, medicinal_uses, ecological_importance, environmental_benefits')
          .inFilter('id', profile.speciesFound);

      final medicinalCount = speciesRows
          .where((r) => ((r['medicinal_uses'] as String?) ?? '').trim().isNotEmpty)
          .length;
      maybeUnlock('medicinal_five', medicinalCount >= 5);

      // No structured "bat sanctuary" flag exists on plant_species — best
      // effort match against the free-text ecological fields.
      final hasBatSanctuary = speciesRows.any((r) {
        final text =
            '${r['ecological_importance'] ?? ''} ${r['environmental_benefits'] ?? ''}'
                .toLowerCase();
        return text.contains('bat sanctuary');
      });
      maybeUnlock('bat_sanctuary', hasBatSanctuary);
    }

    // perfect_week / night_owl read straight from challenge_completions
    // rather than user_profiles, since neither is derivable from the
    // aggregate profile fields alone.
    final completions = await _client
        .from('challenge_completions')
        .select('is_correct, completed_at, daily_challenges(challenge_date)')
        .eq('device_id', deviceId);

    final hasNightOwl = completions.any((r) {
      final ts = r['completed_at'] as String?;
      if (ts == null) return false;
      return DateTime.parse(ts).toLocal().hour >= 22;
    });
    maybeUnlock('night_owl', hasNightOwl);

    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => _dateKey(now.subtract(Duration(days: i)))).toSet();
    final correctDatesInWindow = <String>{};
    for (final r in completions) {
      final joined = r['daily_challenges'] as Map<String, dynamic>?;
      final dateStr = joined?['challenge_date'] as String?;
      if (dateStr == null || !last7Days.contains(dateStr)) continue;
      if (r['is_correct'] == true) correctDatesInWindow.add(dateStr);
    }
    maybeUnlock('perfect_week', correctDatesInWindow.length == 7);

    if (newlyUnlocked.isEmpty) return [];

    await _client.from('user_achievements').insert(
          newlyUnlocked.map((a) => {'device_id': deviceId, 'achievement_id': a.id}).toList(),
        );
    return newlyUnlocked;
  }

  Future<List<RecentScan>> getRecentScans(String deviceId, {int limit = 5}) async {
    final rows = await _client
        .from('identification_logs')
        .select('created_at, predicted_species_id, plant_species(common_name)')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((r) {
      final species = r['plant_species'] as Map<String, dynamic>?;
      return RecentScan(
        speciesName: (species?['common_name'] as String?) ?? 'Unidentified plant',
        date: DateTime.parse(r['created_at'] as String),
        matched: r['predicted_species_id'] != null,
      );
    }).toList();
  }

  /// Wipes this device's profile and achievement rows and mints a fresh
  /// device id, so the app returns to a completely blank-slate state.
  Future<void> resetProfile(String deviceId) async {
    await _client.from('user_achievements').delete().eq('device_id', deviceId);
    await _client.from('user_profiles').delete().eq('device_id', deviceId);
    await DeviceId.reset();
  }
}
