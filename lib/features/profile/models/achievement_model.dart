// lib/features/profile/models/achievement_model.dart
import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';

/// 'common' | 'rare' | 'legendary'
typedef Rarity = String;

class Achievement {
  final String id;
  final String title;
  final String description;
  /// Kept for the notification feed, which stores it as free text — the
  /// Profile screen and achievement toast render [icon] instead.
  final String emoji;
  final IconData icon;
  final int points;
  final Rarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.points,
    required this.rarity,
  });
}

/// Definitions only — the database just records which [id]s a device has
/// unlocked (see [UserAchievement]).
const List<Achievement> kAchievements = [
  Achievement(
      id: 'first_scan',
      title: 'First Steps',
      description: 'Complete your first plant scan',
      emoji: '📸',
      icon: kIconCamera,
      points: 50,
      rarity: 'common'),
  Achievement(
      id: 'ten_scans',
      title: 'Field Researcher',
      description: 'Complete 10 plant scans',
      emoji: '🔬',
      icon: kIconScience,
      points: 100,
      rarity: 'common'),
  Achievement(
      id: 'fifty_scans',
      title: 'Campus Botanist',
      description: 'Complete 50 plant scans',
      emoji: '🌿',
      icon: kIconLeaf,
      points: 250,
      rarity: 'rare'),
  Achievement(
      id: 'medicinal_five',
      title: 'Herbalist',
      description: 'Scan 5 medicinal species',
      emoji: '💊',
      icon: kIconMedical,
      points: 150,
      rarity: 'rare'),
  Achievement(
      id: 'bat_sanctuary',
      title: 'Sanctuary Explorer',
      description: 'Scan a species from the bat sanctuary',
      emoji: '🦇',
      icon: kIconPets,
      points: 100,
      rarity: 'common'),
  Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Complete 3 daily challenges in a row',
      emoji: '🔥',
      icon: kIconStreak,
      points: 75,
      rarity: 'common'),
  Achievement(
      id: 'streak_7',
      title: 'On Fire',
      description: 'Complete 7 daily challenges in a row',
      emoji: '⚡',
      icon: kIconBolt,
      points: 200,
      rarity: 'rare'),
  Achievement(
      id: 'streak_30',
      title: 'Dedicated Naturalist',
      description: 'Complete 30 daily challenges in a row',
      emoji: '🏆',
      icon: kIconTrophy,
      points: 500,
      rarity: 'legendary'),
  Achievement(
      id: 'articles_five',
      title: 'Scholar',
      description: 'Read 5 Learn articles',
      emoji: '📚',
      icon: kIconLearn,
      points: 100,
      rarity: 'common'),
  Achievement(
      id: 'ten_species',
      title: 'Species Hunter',
      description: 'Identify 10 different species',
      emoji: '🎯',
      icon: kIconTarget,
      points: 150,
      rarity: 'common'),
  Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Answer all 7 challenges correctly in one week',
      emoji: '⭐',
      icon: kIconStar,
      points: 300,
      rarity: 'legendary'),
  Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Complete a challenge after 10pm',
      emoji: '🦉',
      icon: kIconNight,
      points: 75,
      rarity: 'rare'),
];

Achievement? achievementById(String id) {
  for (final a in kAchievements) {
    if (a.id == id) return a;
  }
  return null;
}

/// A device's unlocked achievement, as stored in `user_achievements`.
class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;

  const UserAchievement({required this.achievementId, required this.unlockedAt});

  factory UserAchievement.fromJson(Map<String, dynamic> json) => UserAchievement(
        achievementId: json['achievement_id'] as String,
        unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      );
}
