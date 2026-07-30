// lib/features/notifications/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Matches DeviceId's UUID v4 format exactly (lowercase hex + hyphens only).
final _uuidPattern =
    RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

class NotificationService {
  final SupabaseClient _client;
  NotificationService(this._client);

  /// [deviceId] gets interpolated directly into a PostgREST `.or()` filter
  /// string below — always a well-formed UUID from [DeviceId] in practice,
  /// but a comma or parenthesis in an unchecked value would alter the
  /// filter's meaning. Validating the shape first closes that off.
  static void _requireValidDeviceId(String deviceId) {
    if (!_uuidPattern.hasMatch(deviceId)) {
      throw ArgumentError.value(deviceId, 'deviceId', 'must be a UUID');
    }
  }

  /// Device-specific notifications plus broadcast ones (device_id IS NULL),
  /// newest first, with expired rows filtered out client-side (simpler and
  /// more portable than relying on chained PostgREST `or()` filters).
  Future<List<AppNotification>> getNotifications(String deviceId) async {
    _requireValidDeviceId(deviceId);
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
    _requireValidDeviceId(deviceId);
    await _client
        .from('notifications')
        .update({'is_read': true})
        .or('device_id.eq.$deviceId,device_id.is.null')
        .eq('is_read', false);
  }

  Future<int> getUnreadCount(String deviceId) async {
    _requireValidDeviceId(deviceId);
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
