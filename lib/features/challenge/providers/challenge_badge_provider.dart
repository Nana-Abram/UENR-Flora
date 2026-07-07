// lib/features/challenge/providers/challenge_badge_provider.dart
import 'package:flutter/foundation.dart';
import '../services/challenge_service.dart';

/// Lightweight app-wide state powering the badge dot on the nav bar's
/// Challenge icon — true whenever today's challenge exists and hasn't been
/// completed by this device yet.
class ChallengeBadgeProvider extends ChangeNotifier {
  final ChallengeService _service;
  ChallengeBadgeProvider(this._service) {
    refresh();
  }

  bool showBadge = false;

  Future<void> refresh() async {
    try {
      final challenge = await _service.getTodaysChallenge();
      if (challenge == null) {
        showBadge = false;
      } else {
        final deviceId = await _service.getDeviceId();
        showBadge = !await _service.hasCompletedToday(deviceId);
      }
    } catch (_) {
      showBadge = false;
    }
    notifyListeners();
  }
}
