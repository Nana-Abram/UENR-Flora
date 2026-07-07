// lib/features/profile/widgets/achievement_toast.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/achievement_model.dart';

const _kGold = Color(0xFFFAC775);

/// Styled, auto-dismissing "you unlocked X" banner. Not inserted directly —
/// use [ProfileProvider.showAchievementToast], which mounts this into the
/// app's root overlay so it appears over whatever screen is visible.
class AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;
  const AchievementToast({super.key, required this.achievement, required this.onDismiss});

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast> {
  bool _visible = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 300), widget.onDismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return Positioned(
      // Sits below the app's fixed 64px top navbar rather than overlapping
      // it — this is inserted into the root Navigator's overlay, which
      // stacks above the whole AppShell (navbar included).
      top: 76,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_visible,
        child: GestureDetector(
          onTap: _dismiss,
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, -1.2),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDeep,
                    borderRadius: kBRXl,
                    border: Border.all(color: _kGold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(a.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ACHIEVEMENT UNLOCKED!',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kGold,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 3),
                            Text(a.title,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('+${a.points} points',
                                style: const TextStyle(fontSize: 12, color: kMint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
