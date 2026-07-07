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
      notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
