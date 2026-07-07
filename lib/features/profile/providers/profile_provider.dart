// lib/features/profile/providers/profile_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/device_id.dart';
import '../../../core/navigation.dart';
import '../../challenge/providers/challenge_provider.dart';
import '../../notifications/services/notification_service.dart';
import '../models/achievement_model.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/achievement_toast.dart';

const _kStreakMilestones = {3, 7, 30};

/// App-wide profile/achievement state — registered once in main.dart (not
/// screen-scoped) since scan, learn, and daily-challenge flows all need to
/// report activity into it, and achievement toasts must be able to appear
/// over whatever screen the device is currently on.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;
  final NotificationService _notificationService;
  ProfileProvider(this._service, this._notificationService) {
    loadProfile();
  }

  UserProfile? profile;
  List<String> unlockedAchievements = [];
  Map<String, DateTime> unlockedAt = {};
  bool isLoading = true;
  List<Achievement> newlyUnlocked = [];
  String? deviceId;
  String? error;

  ChallengeProvider? _challenge;
  bool _challengeWasSubmitted = false;

  /// Subscribes to a (screen-scoped) [ChallengeProvider] so points get
  /// awarded the moment a challenge is submitted, without the Challenge
  /// screen having to know about ProfileProvider at all. Safe to call
  /// repeatedly with the same instance — a no-op after the first call.
  void listenToChallenge(ChallengeProvider challenge) {
    if (identical(_challenge, challenge)) return;
    if (_challenge != null) _challenge!.removeListener(_onChallengeChanged);
    _challenge = challenge;
    _challengeWasSubmitted = challenge.isSubmitted;
    challenge.addListener(_onChallengeChanged);
  }

  /// Unsubscribes — call when the Challenge screen (and its
  /// ChallengeProvider) is disposed, so this doesn't hold a dangling
  /// listener on a disposed ChangeNotifier.
  void stopListeningToChallenge(ChallengeProvider challenge) {
    challenge.removeListener(_onChallengeChanged);
    if (identical(_challenge, challenge)) _challenge = null;
  }

  void _onChallengeChanged() {
    final c = _challenge;
    if (c == null) return;
    if (!c.isSubmitted) {
      _challengeWasSubmitted = false;
      return;
    }
    if (_challengeWasSubmitted) return; // already handled this submission
    _challengeWasSubmitted = true;

    recordChallengeCompletion(isCorrect: c.isCorrect, pointsEarned: c.pointsEarned);

    final id = c.deviceId;
    if (c.isCorrect && id != null && _kStreakMilestones.contains(c.streakDays)) {
      final streak = c.streakDays;
      unawaited(_notificationService.createNotification(
        deviceId: id,
        title: '🔥 $streak-Day Streak!',
        body: 'Amazing consistency! Keep coming back daily.',
        type: 'streak_warning',
        iconEmoji: '🔥',
        actionRoute: '/challenge',
      ));
    }
  }

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      deviceId = await DeviceId.get();
      profile = await _service.getOrCreateProfile(deviceId!);
      unlockedAchievements = await _service.getUnlockedAchievements(deviceId!);
      unlockedAt = await _service.getUnlockDates(deviceId!);
    } catch (_) {
      error = "Couldn't load your profile. Please try again.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    unawaited(_checkAchievements());
  }

  Future<void> editName(String name) async {
    final id = deviceId;
    if (id == null || name.trim().isEmpty) return;
    profile = await _service.updateProfile(id, name: name.trim());
    notifyListeners();
  }

  Future<void> editAvatar(String emoji) async {
    final id = deviceId;
    if (id == null) return;
    profile = await _service.updateProfile(id, emoji: emoji);
    notifyListeners();
  }

  Future<void> recordScan(String? speciesId, bool isCorrect) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    profile = await _service.recordScan(id, speciesId, isCorrect);
    notifyListeners();
    await _checkAchievements();
  }

  Future<void> recordArticleRead(int articleId) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    profile = await _service.recordArticleRead(id, articleId);
    notifyListeners();
    await _checkAchievements();
  }

  Future<void> recordChallengeCompletion({required bool isCorrect, required int pointsEarned}) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    profile = await _service.recordChallengeCompletion(id, isCorrect: isCorrect, pointsEarned: pointsEarned);
    notifyListeners();
    await _checkAchievements();
  }

  Future<void> resetData() async {
    final id = deviceId;
    if (id != null) {
      await _service.resetProfile(id);
    }
    profile = null;
    unlockedAchievements = [];
    unlockedAt = {};
    deviceId = null;
    await loadProfile();
  }

  Future<void> _checkAchievements() async {
    final id = deviceId;
    if (id == null) return;
    try {
      final unlocked = await _service.checkAndUnlockAchievements(id);
      if (unlocked.isEmpty) return;
      newlyUnlocked = unlocked;
      final now = DateTime.now();
      unlockedAchievements = {...unlockedAchievements, ...unlocked.map((a) => a.id)}.toList();
      for (final a in unlocked) {
        unlockedAt[a.id] = now;
      }
      notifyListeners();
      for (final a in unlocked) {
        unawaited(_notificationService.createNotification(
          deviceId: id,
          title: 'Achievement Unlocked: ${a.title}',
          body: '${a.description} You earned ${a.points} points!',
          type: 'achievement',
          iconEmoji: a.emoji,
          actionRoute: '/profile',
        ));
        // Awaits the toast's full on-screen lifecycle before showing the
        // next one — multiple simultaneous unlocks used to all render at
        // the same fixed position and pile up on top of each other.
        await showAchievementToast(a);
      }
    } catch (_) {
      // Achievement evaluation is best-effort — a failure here shouldn't
      // interrupt whatever action (scan, article, challenge) triggered it.
    }
  }

  /// Shows the toast and resolves once it has fully dismissed itself, so
  /// callers can serialize multiple toasts instead of stacking them.
  Future<void> showAchievementToast(Achievement achievement) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return Future.value();
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AchievementToast(
        achievement: achievement,
        onDismiss: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }

  @override
  void dispose() {
    if (_challenge != null) _challenge!.removeListener(_onChallengeChanged);
    super.dispose();
  }
}
