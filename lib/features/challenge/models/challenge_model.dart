// lib/features/challenge/models/challenge_model.dart
import 'package:flutter/foundation.dart';

enum ChallengeType {
  identifyPhoto,
  nameIt,
  findIt,
  trueFalse,
  familyMatch;

  static ChallengeType fromDb(String value) {
    switch (value) {
      case 'identify_photo':
        return ChallengeType.identifyPhoto;
      case 'name_it':
        return ChallengeType.nameIt;
      case 'find_it':
        return ChallengeType.findIt;
      case 'family_match':
        return ChallengeType.familyMatch;
      case 'true_false':
        return ChallengeType.trueFalse;
      default:
        // Falls back to trueFalse either way, but a typo'd/new
        // challenge_type value should be visible in debug builds rather
        // than silently rendering as "TRUE OR FALSE".
        debugPrint('ChallengeType.fromDb: unrecognized challenge_type "$value", '
            'defaulting to trueFalse');
        return ChallengeType.trueFalse;
    }
  }

  /// Short, uppercase pill label shown on the challenge card.
  String get label {
    switch (this) {
      case ChallengeType.identifyPhoto:
        return 'IDENTIFY PHOTO';
      case ChallengeType.nameIt:
        return 'NAME IT';
      case ChallengeType.findIt:
        return 'FIND IT';
      case ChallengeType.trueFalse:
        return 'TRUE OR FALSE';
      case ChallengeType.familyMatch:
        return 'FAMILY MATCH';
    }
  }
}

/// A single day's challenge, as stored in the `daily_challenges` table.
class DailyChallenge {
  final String id;
  final DateTime challengeDate;
  final ChallengeType type;
  final String title;
  final String description;
  final String? speciesId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int pointsReward;
  final String? funFact;

  const DailyChallenge({
    required this.id,
    required this.challengeDate,
    required this.type,
    required this.title,
    required this.description,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.pointsReward,
    this.speciesId,
    this.funFact,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'] as List<dynamic>? ?? const [];
    return DailyChallenge(
      id: json['id'] as String,
      challengeDate: DateTime.parse(json['challenge_date'] as String),
      type: ChallengeType.fromDb(json['challenge_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      speciesId: json['species_id'] as String?,
      question: json['question'] as String,
      options: optionsRaw.map((o) => o.toString()).toList(),
      correctAnswer: json['correct_answer'] as String,
      pointsReward: (json['points_reward'] as int?) ?? 50,
      funFact: json['fun_fact'] as String?,
    );
  }
}

/// A device's recorded attempt at a challenge, as stored in the
/// `challenge_completions` table.
class ChallengeCompletion {
  final String id;
  final String deviceId;
  final String challengeId;
  final DateTime completedAt;
  final int pointsEarned;
  final String? answerGiven;
  final bool isCorrect;
  final int? timeTakenS;

  const ChallengeCompletion({
    required this.id,
    required this.deviceId,
    required this.challengeId,
    required this.completedAt,
    required this.pointsEarned,
    required this.isCorrect,
    this.answerGiven,
    this.timeTakenS,
  });

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletion(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      challengeId: json['challenge_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      pointsEarned: (json['points_earned'] as int?) ?? 0,
      isCorrect: (json['is_correct'] as bool?) ?? false,
      answerGiven: json['answer_given'] as String?,
      timeTakenS: json['time_taken_s'] as int?,
    );
  }
}

/// Outcome of submitting an answer — returned by [ChallengeService.submitAnswer].
class ChallengeResult {
  final bool isCorrect;
  final int pointsEarned;
  final String correctAnswer;
  final String? funFact;

  const ChallengeResult({
    required this.isCorrect,
    required this.pointsEarned,
    required this.correctAnswer,
    this.funFact,
  });
}
