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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(a.icon, size: 24, color: _kGold),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Text(a.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.35,
                                    decoration: TextDecoration.none)),
                            const SizedBox(height: 5),
                            Text('+${a.points} points',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: kMint,
                                    height: 1.3,
                                    decoration: TextDecoration.none)),
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
