// lib/features/challenge/providers/challenge_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeService _service;
  ChallengeProvider(this._service);

  DailyChallenge? currentChallenge;
  ChallengeCompletion? completion;
  String? deviceId;

  bool isLoading = true;
  bool hasCompleted = false;
  int streakDays = 0;
  String? error;

  String? selectedAnswer;
  bool isSubmitted = false;
  bool isCorrect = false;
  int pointsEarned = 0;
  String? correctAnswer;
  String? funFact;

  int timeElapsed = 0;
  Timer? _ticker;

  // The Challenge screen can be navigated away from (disposing this
  // provider) while the 1s ticker or an in-flight service call is still
  // pending — `_ticker?.cancel()` alone doesn't close that race, since a
  // tick or an await can already be resolving in the same event-loop turn
  // dispose() runs in. Every notifyListeners() call below is guarded on
  // this flag so a late timer/future can never touch a disposed
  // ChangeNotifier.
  bool _disposed = false;

  Future<void> loadTodaysChallenge() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      deviceId = await _service.getDeviceId();
      currentChallenge = await _service.getTodaysChallenge();

      if (currentChallenge != null) {
        hasCompleted = await _service.hasCompletedToday(deviceId!);
        if (hasCompleted) {
          completion = await _service.getCompletion(deviceId!, currentChallenge!.id);
        } else {
          _startTimer();
        }
      }
      streakDays = await _service.getCompletionStreak(deviceId!);
    } catch (_) {
      error = "Couldn't load today's challenge. Please try again.";
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void selectAnswer(String answer) {
    if (isSubmitted) return;
    selectedAnswer = answer;
    notifyListeners();
  }

  void _startTimer() {
    _ticker?.cancel();
    timeElapsed = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      timeElapsed++;
      notifyListeners();
    });
  }

  Future<void> submitAnswer() async {
    if (selectedAnswer == null || isSubmitted) return;
    final challenge = currentChallenge;
    final device = deviceId;
    if (challenge == null || device == null) return;

    _ticker?.cancel();
    final elapsed = timeElapsed;

    try {
      final result = await _service.submitAnswer(device, challenge.id, selectedAnswer!, elapsed);
      isCorrect = result.isCorrect;
      pointsEarned = result.pointsEarned;
      correctAnswer = result.correctAnswer;
      funFact = result.funFact;
      isSubmitted = true;
      if (isCorrect) {
        streakDays = await _service.getCompletionStreak(device);
      }
    } catch (_) {
      error = "Couldn't submit your answer. Please try again.";
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
