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

    await _client.from('challenge_completions').insert({
      'device_id': deviceId,
      'challenge_id': challengeId,
      'points_earned': points,
      'answer_given': answer,
      'is_correct': isCorrect,
      'time_taken_s': timeTakenSeconds,
    });

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
    if (dates.isEmpty) return 0;

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
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
}
