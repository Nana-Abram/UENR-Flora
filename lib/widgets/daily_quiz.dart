// lib/widgets/daily_quiz.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/quiz_question.dart';

class DailyQuiz extends StatefulWidget {
  const DailyQuiz({super.key});

  @override
  State<DailyQuiz> createState() => _DailyQuizState();
}

class _DailyQuizState extends State<DailyQuiz> {
  late int _qIndex;
  late QuizQuestion _current;
  late List<String> _shuffled; // options shuffled for display
  String? _selected;           // which option the user tapped
  bool _submitted = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _qIndex = Random().nextInt(kQuizBank.length);
    _loadQuestion();
    _loadStreak();
  }

  void _loadQuestion() {
    _current  = kQuizBank[_qIndex % kQuizBank.length];
    _shuffled = List<String>.from(_current.options)..shuffle();
    _selected  = null;
    _submitted = false;
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _streak = prefs.getInt('quiz_streak') ?? 0);
  }

  Future<void> _saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_streak', _streak);
  }

  void _select(String option) {
    if (_submitted) return;
    setState(() => _selected = option);
  }

  void _submit() {
    if (_selected == null || _submitted) return;
    final correct = _selected == _current.answer;
    setState(() {
      _submitted = true;
      if (correct) _streak++;
    });
    if (correct) _saveStreak();
  }

  void _next() {
    setState(() {
      _qIndex++;
      _loadQuestion();
    });
  }

  // ── Option button colours ───────────────────────────────────
  Color _optionBg(String opt) {
    if (!_submitted) {
      return _selected == opt
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.06);
    }
    if (opt == _current.answer)       return kQuizCorrectBg;
    if (opt == _selected)             return kQuizWrongBg;
    return Colors.white.withValues(alpha: 0.06);
  }

  Color _optionBorder(String opt) {
    if (!_submitted) {
      return _selected == opt
          ? Colors.white.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.18);
    }
    if (opt == _current.answer) return kQuizCorrectBd;
    if (opt == _selected)       return kQuizWrongBd;
    return Colors.white.withValues(alpha: 0.18);
  }

  Color _optionText(String opt) {
    if (!_submitted) return Colors.white;
    if (opt == _current.answer) return const Color(0xFF95D5B2);
    if (opt == _selected)       return const Color(0xFFF09595);
    return Colors.white.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDeep,
      padding: const EdgeInsets.fromLTRB(kSp24, kSp36, kSp24, kSp36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= kBreakpointSm;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlantImage(190, 190),
                        const SizedBox(width: 18),
                        Expanded(child: _buildOptions()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildPlantImage(double.infinity, 160),
                        const SizedBox(height: 16),
                        _buildOptions(),
                      ],
                    );
            },
          ),
          if (_submitted) ...[
            const SizedBox(height: 20),
            _buildResult(),
          ],
        ],
      ),
    );
  }

  // ── Header row ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: kBRPill,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_outline, size: 12, color: Color(0xFFFAC775)),
                    SizedBox(width: 6),
                    Text('Daily challenge',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: Color(0xFFFAC775))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Can you identify this campus plant?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('One new plant every day — build your streak',
                  style: TextStyle(fontSize: 12, color: kMint)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Streak badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: kBRLg,
          ),
          child: Column(
            children: [
              Text('$_streak',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500,
                      color: Color(0xFFFAC775))),
              const Text('day streak',
                  style: TextStyle(fontSize: 10, color: kMint)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Plant image block ───────────────────────────────────────
  Widget _buildPlantImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _current.cardColor,
        borderRadius: kBR2xl,
      ),
      child: Center(child: Icon(_current.icon, size: 56, color: _current.iconColor)),
    );
  }

  // ── Option buttons + submit ─────────────────────────────────
  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the correct species',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: Color(0x80FFFFFF))),
        const SizedBox(height: 10),
        ...List.generate(_shuffled.length, (i) {
          final opt = _shuffled[i];
          final label = ['A', 'B', 'C', 'D'][i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _select(opt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: _optionBg(opt),
                  border: Border.all(color: _optionBorder(opt), width: 1.5),
                  borderRadius: kBRMd,
                ),
                child: Row(
                  children: [
                    // Letter circle
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(opt,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: _optionText(opt))),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selected != null && !_submitted) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAmber,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kQuizWrongBd,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: kBRMd),
              elevation: 0,
            ),
            child: const Text('Submit answer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Result block (shown after submit) ───────────────────────
  Widget _buildResult() {
    final correct = _selected == _current.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verdict
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: correct ? kQuizCorrectBg : kQuizWrongBg,
            border: Border.all(
                color: correct ? kQuizCorrectBd : kQuizWrongBd, width: 1),
            borderRadius: kBRLg,
          ),
          child: Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 20,
                color: correct ? kQuizCorrectBd : kQuizWrongBd,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Correct!' : 'Not quite',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: correct
                            ? const Color(0xFF95D5B2)
                            : const Color(0xFFF09595)),
                  ),
                  Text(
                    correct
                        ? 'That\'s ${_current.answer} — well done.'
                        : 'The correct answer is ${_current.answer}.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Fun fact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: kBRLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Color(0xFFFAC775)),
                  SizedBox(width: 7),
                  Text('Did you know?',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: Color(0xFFFAC775))),
                ],
              ),
              const SizedBox(height: 7),
              Text(_current.funFact,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Next challenge button
        OutlinedButton.icon(
          onPressed: _next,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: kBRSm),
          ),
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Try another plant',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
