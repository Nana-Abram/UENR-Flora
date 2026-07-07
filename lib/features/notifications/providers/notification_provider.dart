// lib/features/notifications/providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/device_id.dart';
import '../../challenge/services/challenge_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// App-wide notification state — registered once in main.dart so the bell
/// badge in the nav bar and the notification screen share one source of
/// truth. Polls Supabase every 60s while the app is in the foreground.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final NotificationService _service;
  final ChallengeService _challengeService;
  NotificationProvider(this._service, this._challengeService) {
    WidgetsBinding.instance.addObserver(this);
    loadNotifications();
    startPolling();
    unawaited(_checkDailyChallengeReminder());
  }

  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;
  String? deviceId;

  Timer? _pollTimer;

  bool get hasUnread => unreadCount > 0;

  Future<void> loadNotifications() async {
    try {
      final id = deviceId ?? await DeviceId.get();
      deviceId = id;
      notifications = await _service.getNotifications(id);
      unreadCount = notifications.where((n) => !n.isRead).length;
    } catch (_) {
      // Polling is best-effort — a failed refresh just keeps stale state.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Runs once on app launch (not on every poll tick, to avoid repeat
  /// queries): if today's challenge hasn't been completed yet and it's
  /// past 7am local time, nudge the device — but only if it hasn't
  /// already been nudged today.
  Future<void> _checkDailyChallengeReminder() async {
    try {
      final id = deviceId ?? await DeviceId.get();
      deviceId = id;
      if (DateTime.now().hour < 7) return;

      final challenge = await _challengeService.getTodaysChallenge();
      if (challenge == null) return;
      if (await _challengeService.hasCompletedToday(id)) return;
      if (await _service.hasNotificationToday(id, 'challenge_ready')) return;

      await _service.createNotification(
        deviceId: id,
        title: 'Daily Challenge Available',
        body: "Test your plant knowledge and earn points. Today's challenge is ready!",
        type: 'challenge_ready',
        iconEmoji: '🎯',
        actionRoute: '/challenge',
      );
      await loadNotifications();
    } catch (_) {
      // Best-effort reminder — a failure here shouldn't block app launch.
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => loadNotifications());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> markRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;
    final n = notifications[index];
    notifications[index] = AppNotification(
      id: n.id,
      deviceId: n.deviceId,
      title: n.title,
      body: n.body,
      type: n.type,
      iconEmoji: n.iconEmoji,
      actionRoute: n.actionRoute,
      isRead: true,
      createdAt: n.createdAt,
      expiresAt: n.expiresAt,
    );
    unreadCount = notifications.where((n) => !n.isRead).length;
    notifyListeners();
    await _service.markAsRead(id);
  }

  Future<void> markAllRead() async {
    final id = deviceId;
    if (id == null || unreadCount == 0) return;
    notifications = notifications
        .map((n) => AppNotification(
              id: n.id,
              deviceId: n.deviceId,
              title: n.title,
              body: n.body,
              type: n.type,
              iconEmoji: n.iconEmoji,
              actionRoute: n.actionRoute,
              isRead: true,
              createdAt: n.createdAt,
              expiresAt: n.expiresAt,
            ))
        .toList();
    unreadCount = 0;
    notifyListeners();
    await _service.markAllAsRead(id);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadNotifications();
      startPolling();
    } else {
      stopPolling();
    }
  }

  @override
  void dispose() {
    stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
