// lib/features/profile/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/device_id.dart';
import '../models/achievement_model.dart';
import '../models/leaderboard_entry.dart';
import '../models/profile_model.dart';

/// One row from `identification_logs`, shaped for the Profile screen's
/// "Recent Activity" list and "Scan History" tab.
class RecentScan {
  final String? speciesId;
  final String speciesName;
  final String? scientificName;
  final String? imageUrl;
  final DateTime date;
  final bool matched;
  final double? confidence;
  final String? healthStatus; // 'healthy' | 'unhealthy' | 'unknown' | null
  const RecentScan({
    this.speciesId,
    required this.speciesName,
    this.scientificName,
    this.imageUrl,
    required this.date,
    required this.matched,
    this.confidence,
    this.healthStatus,
  });
}

class ProfileService {
  final SupabaseClient _client;
  ProfileService(this._client);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The atomic RPCs below (`record_*_atomic`) are declared to return a
  /// single `user_profiles` row, not `SETOF` — so if `device_id` doesn't
  /// match any row (the profile was deleted mid-request, e.g. by a
  /// concurrent [resetProfile]), PostgREST responds 200 with every column
  /// null rather than an error. Fail loudly here instead of letting that
  /// turn into an opaque cast exception inside [UserProfile.fromJson].
  UserProfile _profileFromRpcRow(Object? row, String rpcName) {
    final map = row as Map<String, dynamic>;
    if (map['device_id'] == null) {
      throw StateError('$rpcName found no matching user_profiles row — '
          'was the profile deleted mid-request?');
    }
    return UserProfile.fromJson(map);
  }

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
  ///
  /// The increment happens server-side in `record_scan_atomic` (see
  /// supabase/atomic_profile_updates.sql) rather than as a Dart
  /// read-modify-write, so two concurrent scans for the same device can't
  /// clobber each other's totals.
  Future<UserProfile> recordScan(String deviceId, String? speciesId, bool isCorrect) async {
    await getOrCreateProfile(deviceId);
    final row = await _client.rpc('record_scan_atomic', params: {
      'p_device_id': deviceId,
      'p_species_id': speciesId,
      'p_is_correct': isCorrect,
    });
    return _profileFromRpcRow(row, 'record_scan_atomic');
  }

  /// See [recordScan] — `record_article_read_atomic` is idempotent (it
  /// won't add a duplicate `articleId`), so there's no need to fetch the
  /// profile first just to check "have I already read this."
  Future<UserProfile> recordArticleRead(String deviceId, int articleId) async {
    await getOrCreateProfile(deviceId);
    final row = await _client.rpc('record_article_read_atomic', params: {
      'p_device_id': deviceId,
      'p_article_id': articleId,
    });
    return _profileFromRpcRow(row, 'record_article_read_atomic');
  }

  /// Not part of the original spec's method list, but without it
  /// `streak_days`/`longest_streak`/`total_challenges` would never move —
  /// call this from the Daily Challenge submit flow so streak-based
  /// achievements have something to check against.
  ///
  /// The streak/points math is done server-side in
  /// `record_challenge_completion_atomic` under a row lock — see [recordScan]
  /// for why (this was the read-modify-write most likely to race in
  /// practice, since points/streak are exactly what a double-submit or
  /// retried request would duplicate). Points are looked up server-side
  /// from `daily_challenges.points_reward` for [challengeId] rather than
  /// trusted as a raw client-supplied number — see
  /// supabase/harden_profile_writes.sql.
  Future<UserProfile> recordChallengeCompletion(
    String deviceId, {
    required String challengeId,
    required bool isCorrect,
  }) async {
    await getOrCreateProfile(deviceId);
    final row = await _client.rpc('record_challenge_completion_atomic', params: {
      'p_device_id': deviceId,
      'p_challenge_id': challengeId,
      'p_is_correct': isCorrect,
    });
    return _profileFromRpcRow(row, 'record_challenge_completion_atomic');
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

  /// [knownProfile], when passed, is used instead of fetching the profile
  /// again — callers that just did a mutating call (recordScan and friends)
  /// already have the fresh row back from that call's RPC response.
  Future<List<Achievement>> checkAndUnlockAchievements(
    String deviceId, {
    UserProfile? knownProfile,
  }) async {
    final profile = knownProfile ?? await getOrCreateProfile(deviceId);

    // These three only depend on deviceId/profile (already resolved above),
    // not on each other — start them together instead of awaiting one at a
    // time. Each future begins executing as soon as it's created, so
    // Future.wait below just waits for whichever finishes last.
    final unlockedFuture = getUnlockedAchievements(deviceId);
    final speciesFuture = profile.speciesFound.isNotEmpty
        ? _client
            .from('plant_species')
            .select('id, medicinal_uses, ecological_importance, environmental_benefits')
            .inFilter('id', profile.speciesFound)
        : Future.value(<Map<String, dynamic>>[]);
    final completionsFuture = _client
        .from('challenge_completions')
        .select('is_correct, completed_at, daily_challenges(challenge_date)')
        .eq('device_id', deviceId);
    await Future.wait([unlockedFuture, speciesFuture, completionsFuture]);

    final unlocked = (await unlockedFuture).toSet();
    final newlyUnlocked = <Achievement>[...profileOnlyUnlockedAchievements(profile, unlocked)];

    void maybeUnlock(String id, bool condition) {
      if (condition && !unlocked.contains(id)) {
        final a = achievementById(id);
        if (a != null) newlyUnlocked.add(a);
      }
    }

    if (profile.speciesFound.isNotEmpty) {
      final speciesRows = await speciesFuture;

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
    final completions = await completionsFuture;

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

  /// Full scan history for this device, newest first — powers the
  /// Profile screen's Overview "Recent Activity" list (first few), "My
  /// Scan Activity" chart, and the "Scan History" tab (all of them),
  /// fetched once by [ProfileProvider] rather than three separate queries.
  /// Capped rather than truly unbounded — this refetches on every scan
  /// (see ProfileProvider.recordScan), and a device's history only ever
  /// grows. 300 is generous for any realistic single-device scan count
  /// while keeping the query (and payload) bounded long-term.
  static const _maxScanHistoryRows = 300;

  Future<List<RecentScan>> getScanHistory(String deviceId) async {
    final rows = await _client
        .from('identification_logs')
        .select('created_at, predicted_species_id, confidence_score, health_status, '
            'plant_species(common_name, scientific_name, reference_image_url)')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(_maxScanHistoryRows);

    return rows.map((r) {
      final species = r['plant_species'] as Map<String, dynamic>?;
      return RecentScan(
        speciesId: r['predicted_species_id'] as String?,
        speciesName: (species?['common_name'] as String?) ?? 'Unidentified plant',
        scientificName: species?['scientific_name'] as String?,
        imageUrl: species?['reference_image_url'] as String?,
        date: DateTime.parse(r['created_at'] as String),
        matched: r['predicted_species_id'] != null,
        confidence: (r['confidence_score'] as num?)?.toDouble(),
        healthStatus: r['health_status'] as String?,
      );
    }).toList();
  }

  /// Wipes this device's profile and achievement rows and mints a fresh
  /// device id, so the app returns to a completely blank-slate state.
  ///
  /// Both deletes run inside one Postgres transaction via
  /// reset_profile_atomic (see supabase/reset_profile_atomic.sql), so a
  /// failure partway through can't leave achievements wiped with the
  /// profile row still intact.
  Future<void> resetProfile(String deviceId) async {
    await _client.rpc('reset_profile_atomic', params: {'p_device_id': deviceId});
    await DeviceId.reset();
  }

  /// Top [limit] opted-in devices by points. See supabase/leaderboard.sql —
  /// get_leaderboard() never returns a device_id, so there's nothing here
  /// for this method to accidentally expose either.
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20}) async {
    final rows = await _client.rpc('get_leaderboard', params: {'p_limit': limit});
    return (rows as List)
        .map((r) => LeaderboardEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// This device's own standing — works whether or not it's opted in (see
  /// [MyLeaderboardRank.optedIn]), so the Leaderboard screen can show
  /// either "you're #12 of 340" or a prompt to opt in from the same call.
  Future<MyLeaderboardRank> getMyLeaderboardRank(String deviceId) async {
    final rows = await _client
        .rpc('get_my_leaderboard_rank', params: {'p_device_id': deviceId});
    return MyLeaderboardRank.fromJson((rows as List).first as Map<String, dynamic>);
  }

  Future<void> setLeaderboardOptIn(String deviceId, bool optIn) async {
    await _client
        .from('user_profiles')
        .update({'leaderboard_opt_in': optIn})
        .eq('device_id', deviceId);
  }
}

/// The subset of [ProfileService.checkAndUnlockAchievements]'s conditions
/// that depend only on [profile] itself, pulled out so they're testable
/// without a Supabase round-trip. The remaining conditions (medicinal_five,
/// bat_sanctuary, night_owl, perfect_week) need extra fetched data —
/// species rows and challenge completions — and stay inline there.
List<Achievement> profileOnlyUnlockedAchievements(UserProfile profile, Set<String> alreadyUnlocked) {
  final newlyUnlocked = <Achievement>[];
  void maybeUnlock(String id, bool condition) {
    if (condition && !alreadyUnlocked.contains(id)) {
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
  return newlyUnlocked;
}
