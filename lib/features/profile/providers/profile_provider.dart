// lib/features/profile/providers/profile_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/device_id.dart';
import '../../../core/navigation.dart';
import '../../challenge/providers/challenge_provider.dart';
import '../../notifications/services/notification_service.dart';
import '../models/achievement_model.dart';
import '../models/leaderboard_entry.dart';
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

  /// Full scan history for this device, newest first — shared by the
  /// Overview tab's "Recent Activity" list/chart and the Scan History tab,
  /// so they don't each run their own query.
  List<RecentScan> scans = [];
  bool scansLoading = true;

  List<LeaderboardEntry> leaderboard = [];
  MyLeaderboardRank? myRank;
  bool leaderboardLoading = false;

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

    final challengeId = c.currentChallenge?.id;
    if (challengeId != null) {
      recordChallengeCompletion(challengeId: challengeId, isCorrect: c.isCorrect);
    }

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
    unawaited(loadScans());
  }

  Future<void> loadScans() async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    scansLoading = true;
    notifyListeners();
    try {
      scans = await _service.getScanHistory(id);
    } catch (_) {
      scans = [];
    } finally {
      scansLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the public top-N list and this device's own standing
  /// together — the Leaderboard screen needs both regardless of whether
  /// this device is opted in (see [MyLeaderboardRank.optedIn]).
  Future<void> loadLeaderboard() async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    leaderboardLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getLeaderboard(),
        _service.getMyLeaderboardRank(id),
      ]);
      leaderboard = results[0] as List<LeaderboardEntry>;
      myRank = results[1] as MyLeaderboardRank;
    } catch (_) {
      // Best-effort — the screen falls back to whatever it last had (often
      // nothing, on first load), same as every other list here.
    } finally {
      leaderboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLeaderboardOptIn(bool optIn) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    try {
      await _service.setLeaderboardOptIn(id, optIn);
      await loadLeaderboard();
    } catch (_) {
      error = "Couldn't update your leaderboard setting. Please try again.";
      notifyListeners();
    }
  }

  /// Applies the new name to [profile] immediately (before the network
  /// round-trip resolves) and rolls back on failure — without this, the
  /// name/level header briefly (or, on a slow/failed request, seemingly
  /// permanently) re-renders with the pre-edit `profile.displayName` for
  /// as long as the request is in flight, since the editor widget flips
  /// out of edit mode as soon as this is called rather than once it
  /// resolves.
  Future<void> editName(String name) async {
    final id = deviceId;
    final trimmed = name.trim();
    final previous = profile;
    if (id == null || trimmed.isEmpty || previous == null) return;
    profile = previous.copyWith(displayName: trimmed);
    notifyListeners();
    try {
      profile = await _service.updateProfile(id, name: trimmed);
      error = null;
    } catch (_) {
      profile = previous;
      error = "Couldn't update your name. Please try again.";
    }
    notifyListeners();
  }

  /// See [editName] for why this updates [profile] optimistically instead
  /// of waiting for the request to resolve.
  Future<void> editAvatar(String emoji) async {
    final id = deviceId;
    final previous = profile;
    if (id == null || previous == null) return;
    profile = previous.copyWith(avatarEmoji: emoji);
    notifyListeners();
    try {
      profile = await _service.updateProfile(id, emoji: emoji);
      error = null;
    } catch (_) {
      profile = previous;
      error = "Couldn't update your avatar. Please try again.";
    }
    notifyListeners();
  }

  /// Unlike [loadProfile]/[loadScans], failures here are caught rather than
  /// left to propagate — this is often called un-awaited (e.g. from
  /// [_onChallengeChanged]), so an uncaught exception would otherwise
  /// become an unhandled async error with no user-facing feedback at all.
  Future<void> recordScan(String? speciesId, bool isCorrect) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    try {
      profile = await _service.recordScan(id, speciesId, isCorrect);
      error = null;
      notifyListeners();
      await _checkAchievements();
      unawaited(loadScans());
    } catch (_) {
      error = "Couldn't save your scan. Please try again.";
      notifyListeners();
    }
  }

  /// See [recordScan] for why this is wrapped — [recordArticleRead] is
  /// called un-awaited from the article screen.
  Future<void> recordArticleRead(int articleId) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    try {
      profile = await _service.recordArticleRead(id, articleId);
      error = null;
      notifyListeners();
      await _checkAchievements();
    } catch (_) {
      error = "Couldn't record that article as read.";
      notifyListeners();
    }
  }

  /// See [recordScan] for why this is wrapped — [_onChallengeChanged] calls
  /// this un-awaited, so a failed write here used to become an unhandled
  /// async exception with no feedback on the Challenge screen.
  Future<void> recordChallengeCompletion({required String challengeId, required bool isCorrect}) async {
    final id = deviceId ?? await DeviceId.get();
    deviceId = id;
    try {
      profile = await _service.recordChallengeCompletion(id, challengeId: challengeId, isCorrect: isCorrect);
      error = null;
      notifyListeners();
      await _checkAchievements();
    } catch (_) {
      error = "Couldn't save your challenge result. Please try again.";
      notifyListeners();
    }
  }

  Future<void> resetData() async {
    final id = deviceId;
    if (id != null) {
      await _service.resetProfile(id);
    }
    profile = null;
    unlockedAchievements = [];
    unlockedAt = {};
    scans = [];
    deviceId = null;
    await loadProfile();
  }

  /// Passes [profile] through to the service so it doesn't re-fetch a row
  /// we just got back from the mutation that called us (see
  /// ProfileService.checkAndUnlockAchievements) — every call site here
  /// already has an up-to-date [profile] by the time this runs.
  Future<void> _checkAchievements() async {
    final id = deviceId;
    if (id == null) return;
    try {
      final unlocked =
          await _service.checkAndUnlockAchievements(id, knownProfile: profile);
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
