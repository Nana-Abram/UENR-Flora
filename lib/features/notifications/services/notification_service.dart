// lib/features/notifications/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client;
  NotificationService(this._client);

  /// Device-specific notifications plus broadcast ones (device_id IS NULL),
  /// newest first, with expired rows filtered out client-side (simpler and
  /// more portable than relying on chained PostgREST `or()` filters).
  Future<List<AppNotification>> getNotifications(String deviceId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .or('device_id.eq.$deviceId,device_id.is.null')
        .order('created_at', ascending: false);

    return rows
        .map((r) => AppNotification.fromJson(r))
        .where((n) => !n.isExpired)
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String deviceId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .or('device_id.eq.$deviceId,device_id.is.null')
        .eq('is_read', false);
  }

  Future<int> getUnreadCount(String deviceId) async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .or('device_id.eq.$deviceId,device_id.is.null')
        .eq('is_read', false);
    return rows.length;
  }

  /// Called internally when achievements unlock, streaks hit milestones,
  /// or the daily-challenge reminder fires.
  Future<void> createNotification({
    required String deviceId,
    required String title,
    required String body,
    required String type,
    String? iconEmoji,
    String? actionRoute,
  }) async {
    await _client.from('notifications').insert({
      'device_id': deviceId,
      'title': title,
      'body': body,
      'type': type,
      'icon_emoji': iconEmoji ?? '🔔',
      'action_route': actionRoute,
    });
  }

  /// True if a notification of [type] was already created for this device
  /// today — used to avoid spamming the daily challenge_ready reminder.
  Future<bool> hasNotificationToday(String deviceId, String type) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('device_id', deviceId)
        .eq('type', type)
        .gte('created_at', startOfDay)
        .limit(1);
    return rows.isNotEmpty;
  }
}
