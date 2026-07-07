// lib/features/notifications/models/notification_model.dart
import 'package:flutter/material.dart';

enum NotificationType {
  challengeReady('challenge_ready'),
  streakWarning('streak_warning'),
  achievement('achievement'),
  newArticle('new_article'),
  newSpecies('new_species'),
  tip('tip'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromValue(String value) {
    for (final t in NotificationType.values) {
      if (t.value == value) return t;
    }
    return NotificationType.system;
  }
}

class AppNotification {
  final String id;
  final String? deviceId;
  final String title;
  final String body;
  final NotificationType type;
  final String iconEmoji;
  final String? actionRoute;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.body,
    required this.type,
    required this.iconEmoji,
    required this.actionRoute,
    required this.isRead,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        deviceId: json['device_id'] as String?,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.fromValue(json['type'] as String),
        iconEmoji: (json['icon_emoji'] as String?) ?? '🔔',
        actionRoute: json['action_route'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      );

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Distinct accent colour per type, matched to the tinted emoji-circle
  /// backgrounds used on the notification cards.
  Color get typeColor {
    switch (type) {
      case NotificationType.challengeReady:
      case NotificationType.streakWarning:
        return const Color(0xFFB0530C); // warm orange
      case NotificationType.achievement:
        return const Color(0xFFB8860B); // gold
      case NotificationType.newArticle:
        return const Color(0xFF1565C0); // blue
      case NotificationType.newSpecies:
        return const Color(0xFF2D6A4F); // green
      case NotificationType.tip:
      case NotificationType.system:
        return const Color(0xFF7B1FA2); // purple
    }
  }

  /// Tinted background for the emoji circle — per DESIGN REQUIREMENTS.
  Color get typeBg {
    switch (type) {
      case NotificationType.challengeReady:
      case NotificationType.streakWarning:
        return const Color(0xFFFFF3E0);
      case NotificationType.achievement:
        return const Color(0xFFFFF8E1);
      case NotificationType.newArticle:
        return const Color(0xFFE3F2FD);
      case NotificationType.newSpecies:
        return const Color(0xFFE8F5E9);
      case NotificationType.tip:
      case NotificationType.system:
        return const Color(0xFFF3E5F5);
    }
  }
}
