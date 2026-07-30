// lib/features/challenge/services/challenge_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/device_id.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  final SupabaseClient _client;
  ChallengeService(this._client);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The app-wide device identity — see [DeviceId].
  Future<String> getDeviceId() => DeviceId.get();

  Future<DailyChallenge?> getTodaysChallenge() async {
    // The server-side pg_cron job that's supposed to create today's row at
    // midnight isn't reliably firing on this project (verified via
    // cron.job_run_details — see supabase/challenge_client_ensure.sql for
    // the full story), so don't just trust it ran. This RPC is idempotent
    // and cheap — a no-op after the first caller each day — so calling it
    // unconditionally here is the actual fix, not a workaround around a
    // workaround. Best-effort: if it fails (e.g. offline), fall through to
    // the plain select below, which still works for any day it already ran.
    try {
      await _client.rpc('client_ensure_todays_challenge');
    } catch (_) {}

    final row = await _client
        .from('daily_challenges')
        .select()
        .eq('challenge_date', _dateKey(DateTime.now()))
        .maybeSingle();
    return row != null ? DailyChallenge.fromJson(row) : null;
  }

  Future<bool> hasCompletedToday(String deviceId) async {
    final challenge = await getTodaysChallenge();
    if (challenge == null) return false;
    final row = await _client
        .from('challenge_completions')
        .select('id')
        .eq('device_id', deviceId)
        .eq('challenge_id', challenge.id)
        .maybeSingle();
    return row != null;
  }

  /// Returns the device's completion record for a given challenge, or null
  /// if it hasn't been attempted yet.
  Future<ChallengeCompletion?> getCompletion(String deviceId, String challengeId) async {
    final row = await _client
        .from('challenge_completions')
        .select()
        .eq('device_id', deviceId)
        .eq('challenge_id', challengeId)
        .maybeSingle();
    return row != null ? ChallengeCompletion.fromJson(row) : null;
  }

  Future<ChallengeResult> submitAnswer(
    String deviceId,
    String challengeId,
    String answer,
    int timeTakenSeconds,
  ) async {
    final row = await _client.from('daily_challenges').select().eq('id', challengeId).single();
    final challenge = DailyChallenge.fromJson(row);
    final isCorrect = answer == challenge.correctAnswer;
    final points = isCorrect ? challenge.pointsReward : 0;

    try {
      await _client.from('challenge_completions').insert({
        'device_id': deviceId,
        'challenge_id': challengeId,
        'points_earned': points,
        'answer_given': answer,
        'is_correct': isCorrect,
        'time_taken_s': timeTakenSeconds,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on (device_id, challenge_id) — a
      // double-click or a request retried after a timeout landed twice.
      // The first insert already went through, so return its result
      // instead of erroring (and instead of silently inserting a second
      // row and awarding points again).
      if (e.code == '23505') {
        final existing = await getCompletion(deviceId, challengeId);
        if (existing != null) {
          return ChallengeResult(
            isCorrect: existing.isCorrect,
            pointsEarned: existing.pointsEarned,
            correctAnswer: challenge.correctAnswer,
            funFact: challenge.funFact,
          );
        }
      }
      rethrow;
    }

    return ChallengeResult(
      isCorrect: isCorrect,
      pointsEarned: points,
      correctAnswer: challenge.correctAnswer,
      funFact: challenge.funFact,
    );
  }

  /// Number of consecutive days (ending today or yesterday, so the streak
  /// doesn't drop to zero before today's challenge has been attempted) the
  /// device has answered a daily challenge correctly.
  Future<int> getCompletionStreak(String deviceId) async {
    final rows = await _client
        .from('challenge_completions')
        .select('is_correct, daily_challenges(challenge_date)')
        .eq('device_id', deviceId)
        .eq('is_correct', true);

    final dates = <DateTime>{};
    for (final row in rows) {
      final joined = row['daily_challenges'] as Map<String, dynamic>?;
      final raw = joined?['challenge_date'] as String?;
      if (raw == null) continue;
      final d = DateTime.parse(raw);
      dates.add(DateTime(d.year, d.month, d.day));
    }
    return streakFromDates(dates);
  }
}

/// Pure streak-counting logic pulled out of [ChallengeService.getCompletionStreak]
/// so it's testable without a Supabase round-trip — [dates] is the set of
/// calendar days (already truncated to y/m/d) the device answered correctly.
/// [now] defaults to the real clock; tests pass a fixed value instead.
int streakFromDates(Set<DateTime> dates, {DateTime? now}) {
  if (dates.isEmpty) return 0;

  final today = now ?? DateTime.now();
  var cursor = DateTime(today.year, today.month, today.day);
  if (!dates.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!dates.contains(cursor)) return 0;
  }
  var streak = 0;
  while (dates.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
