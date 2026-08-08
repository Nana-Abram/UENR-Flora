// lib/features/profile/models/profile_model.dart
import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';

class LevelInfo {
  final int level;
  final String name;
  final IconData icon;
  final int threshold;
  const LevelInfo(this.level, this.name, this.icon, this.threshold);
}

const List<LevelInfo> kLevels = [
  LevelInfo(1, 'Seedling', kIconSpa, 0),
  LevelInfo(2, 'Sprout', kIconGrass, 200),
  LevelInfo(3, 'Sapling', kIconTree, 500),
  LevelInfo(4, 'Tree', kIconForest, 1000),
  LevelInfo(5, 'Elder Tree', kIconCrown, 2000),
];

LevelInfo levelForPoints(int points) {
  var current = kLevels.first;
  for (final l in kLevels) {
    if (points >= l.threshold) current = l;
  }
  return current;
}

/// Null once the device has reached the highest level.
LevelInfo? nextLevelAfter(int level) {
  final idx = kLevels.indexWhere((l) => l.level == level);
  if (idx == -1 || idx == kLevels.length - 1) return null;
  return kLevels[idx + 1];
}

class UserProfile {
  final String deviceId;
  final String displayName;
  final String avatarEmoji;
  final int totalPoints;
  final int level;
  final int streakDays;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalScans;
  final int totalCorrect;
  final int totalChallenges;
  final List<String> speciesFound;
  final List<int> articlesRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.deviceId,
    required this.displayName,
    required this.avatarEmoji,
    required this.totalPoints,
    required this.level,
    required this.streakDays,
    required this.longestStreak,
    required this.totalScans,
    required this.totalCorrect,
    required this.totalChallenges,
    required this.speciesFound,
    required this.articlesRead,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveDate,
  });

  LevelInfo get levelInfo => levelForPoints(totalPoints);
  LevelInfo? get nextLevelInfo => nextLevelAfter(levelInfo.level);

  UserProfile copyWith({String? displayName, String? avatarEmoji}) => UserProfile(
        deviceId: deviceId,
        displayName: displayName ?? this.displayName,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        totalPoints: totalPoints,
        level: level,
        streakDays: streakDays,
        longestStreak: longestStreak,
        lastActiveDate: lastActiveDate,
        totalScans: totalScans,
        totalCorrect: totalCorrect,
        totalChallenges: totalChallenges,
        speciesFound: speciesFound,
        articlesRead: articlesRead,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final speciesRaw = json['species_found'] as List<dynamic>? ?? const [];
    final articlesRaw = json['articles_read'] as List<dynamic>? ?? const [];
    return UserProfile(
      deviceId: json['device_id'] as String,
      displayName: (json['display_name'] as String?) ?? 'Plant Explorer',
      avatarEmoji: (json['avatar_emoji'] as String?) ?? '🌱',
      totalPoints: (json['total_points'] as int?) ?? 0,
      level: (json['level'] as int?) ?? 1,
      streakDays: (json['streak_days'] as int?) ?? 0,
      longestStreak: (json['longest_streak'] as int?) ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      totalScans: (json['total_scans'] as int?) ?? 0,
      totalCorrect: (json['total_correct'] as int?) ?? 0,
      totalChallenges: (json['total_challenges'] as int?) ?? 0,
      speciesFound: speciesRaw.map((s) => s.toString()).toList(),
      // jsonb arrays don't guarantee element type on the wire — a num
      // (e.g. a double) here would throw with a hard `as int` cast, unlike
      // speciesFound's `.toString()` above which tolerates any type.
      articlesRead: articlesRaw.map((a) => (a as num).toInt()).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'display_name': displayName,
        'avatar_emoji': avatarEmoji,
        'total_points': totalPoints,
        'level': level,
        'streak_days': streakDays,
        'longest_streak': longestStreak,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'total_scans': totalScans,
        'total_correct': totalCorrect,
        'total_challenges': totalChallenges,
        'species_found': speciesFound,
        'articles_read': articlesRead,
      };
}
