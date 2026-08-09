// lib/features/notifications/providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/device_id.dart';
import '../../../core/push_config.dart';
import '../../../services/web_push_service.dart';
import '../../challenge/services/challenge_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/push_subscription_service.dart';

/// App-wide notification state — registered once in main.dart so the bell
/// badge in the nav bar and the notification screen share one source of
/// truth. Polls Supabase every 60s while the app is in the foreground.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final NotificationService _service;
  final ChallengeService _challengeService;
  final PushSubscriptionService _pushService;
  NotificationProvider(this._service, this._challengeService, this._pushService) {
    WidgetsBinding.instance.addObserver(this);
    loadNotifications();
    startPolling();
    unawaited(_checkDailyChallengeReminder());
    unawaited(_triggerDailyPushIfDue());
    unawaited(_refreshPushState());
  }

  bool get pushSupported => WebPushService.isSupported;
  String pushPermission = WebPushService.permissionState;
  bool pushSubscribed = false;
  bool pushBusy = false;

  /// Set when [enablePush]/[disablePush] fails, so the toggle can explain
  /// *why* nothing happened instead of silently staying put — most commonly
  /// because no service worker is registered (`flutter run` debug mode
  /// never serves one; see push.js's swReady() and flutter_bootstrap.js).
  String? pushError;

  /// Reads the browser's own PushManager state rather than trusting local
  /// app state — the source of truth for "is this device subscribed" is
  /// the browser/OS, not anything this app persists itself (a cleared
  /// site permission or an OS-level push revocation wouldn't otherwise be
  /// reflected here until the next subscribe/unsubscribe action).
  Future<void> _refreshPushState() async {
    if (!WebPushService.isSupported) return;
    try {
      final existing = await WebPushService.getExistingSubscription();
      pushSubscribed = existing != null;
      pushPermission = WebPushService.permissionState;
      notifyListeners();
    } catch (_) {
      // Best-effort — the toggle just falls back to its default (off).
    }
  }

  Future<void> enablePush() async {
    if (!WebPushService.isSupported || pushBusy) return;
    pushBusy = true;
    pushError = null;
    notifyListeners();
    try {
      final permission = await WebPushService.requestPermission();
      pushPermission = permission;
      if (permission != 'granted') return;

      final sub = await WebPushService.subscribe(kVapidPublicKey);
      if (sub == null) return;

      final id = deviceId ?? await DeviceId.get();
      deviceId = id;
      await _pushService.save(id, sub);
      pushSubscribed = true;
    } catch (e) {
      pushError = _describePushError(e);
    } finally {
      pushBusy = false;
      notifyListeners();
    }
  }

  Future<void> disablePush() async {
    if (pushBusy) return;
    pushBusy = true;
    pushError = null;
    notifyListeners();
    try {
      await WebPushService.unsubscribe();
      pushSubscribed = false;
      final id = deviceId;
      if (id != null) await _pushService.remove(id);
    } catch (e) {
      pushError = _describePushError(e);
    } finally {
      pushBusy = false;
      notifyListeners();
    }
  }

  /// `sw-unavailable` is push.js's swReady() timing out because no service
  /// worker is registered — overwhelmingly this means the app is running
  /// under `flutter run` (debug mode never serves a
  /// flutter_service_worker.js), not a real subscribe failure.
  String _describePushError(Object e) {
    if (e.toString().contains('sw-unavailable')) {
      return "Push notifications need a release build. Run `flutter build web --release` "
          "and serve that instead of `flutter run`, which doesn't register a service worker.";
    }
    return "Couldn't update push notifications. Please try again.";
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

  /// Nudges the server-side daily push send — separate from (and not
  /// gated by) this device's own reminder/completion state above, since
  /// it's meant to trigger delivery to *other* eligible devices too, not
  /// just this one. See PushSubscriptionService.triggerDailySend for why
  /// this needs to happen client-side at all.
  Future<void> _triggerDailyPushIfDue() async {
    if (DateTime.now().hour < 7) return;
    try {
      await _pushService.triggerDailySend();
    } catch (_) {
      // Best-effort — worst case, the next device to open the app after
      // 7am today (or this same device tomorrow) triggers it instead.
    }
  }

  // 150s rather than 60s — loadNotifications() is already called explicitly
  // right after every action that actually creates a notification (an
  // achievement unlocking, a streak milestone, the daily-challenge
  // reminder), so this poll is mostly a safety net for notifications
  // created by some other means, not the primary way updates arrive.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 150), (_) => loadNotifications());
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
