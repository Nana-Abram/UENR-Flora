// lib/features/challenge/screens/challenge_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/category_style.dart';
import '../../../core/species_provider.dart';
import '../../../models/plant_species.dart';
import '../../../widgets/breadcrumb.dart';
import '../../../widgets/plant_detail_modal.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/challenge_model.dart';
import '../providers/challenge_badge_provider.dart';
import '../providers/challenge_provider.dart';
import '../services/challenge_service.dart';

const _kGold = Color(0xFFFAC775);

Map<ChallengeType, CategoryStyle> _typeStyles = {
  ChallengeType.identifyPhoto: CategoryStyle(kDeep, const Color(0xFFE3EDE7)),
  ChallengeType.nameIt: CategoryStyle(kGreen, const Color(0xFFE6F2EC)),
  ChallengeType.findIt: CategoryStyle(kAccent, kAccentL),
  ChallengeType.trueFalse: const CategoryStyle(Color(0xFF40916C), Color(0xFFE8F4EE)),
  ChallengeType.familyMatch: const CategoryStyle(Color(0xFF973C00), Color(0xFFFFFBEB)),
};

String _formatDate(DateTime d) {
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ChallengeProvider(ctx.read<ChallengeService>())..loadTodaysChallenge(),
      child: const _ProfileListenerBridge(child: _ChallengeBody()),
    );
  }
}

/// Subscribes ProfileProvider to this screen's (screen-scoped)
/// ChallengeProvider for the lifetime of the Challenge screen, so points
/// get awarded — and streak-milestone notifications fire — the moment a
/// challenge is submitted, purely by ProfileProvider observing
/// ChallengeProvider's state rather than this screen calling into
/// ProfileProvider directly.
class _ProfileListenerBridge extends StatefulWidget {
  final Widget child;
  const _ProfileListenerBridge({required this.child});

  @override
  State<_ProfileListenerBridge> createState() => _ProfileListenerBridgeState();
}

class _ProfileListenerBridgeState extends State<_ProfileListenerBridge> {
  ChallengeProvider? _challenge;
  ProfileProvider? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final challenge = context.read<ChallengeProvider>();
    final profile = context.read<ProfileProvider>();
    if (!identical(_challenge, challenge) || !identical(_profile, profile)) {
      if (_challenge != null && _profile != null) {
        _profile!.stopListeningToChallenge(_challenge!);
      }
      _challenge = challenge;
      _profile = profile;
      profile.listenToChallenge(challenge);
    }
  }

  @override
  void dispose() {
    if (_challenge != null && _profile != null) {
      _profile!.stopListeningToChallenge(_challenge!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ChallengeBody extends StatelessWidget {
  const _ChallengeBody();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(current: 'Daily Challenge'),
                    SizedBox(height: 16),
                    _ChallengeHeader(),
                    SizedBox(height: 20),
                    _ChallengeContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// A. HEADER
// ─────────────────────────────────────────────────────────────
class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final challenge = provider.currentChallenge;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeep, kGreen],
        ),
        borderRadius: kBR2xl,
      ),
      padding: const EdgeInsets.all(kSp24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= kBreakpointSm;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Daily Challenge',
                  style: TextStyle(
                      fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w500,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(_formatDate(DateTime.now()),
                  style: TextStyle(fontSize: 13, color: kMint)),
            ],
          );

          final badges = Wrap(
            spacing: 10, runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (challenge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    borderRadius: kBRPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 15, color: _kGold),
                      const SizedBox(width: 6),
                      Text('${challenge.pointsReward} pts',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500, color: _kGold)),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  borderRadius: kBRPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 15, color: _kGold),
                    const SizedBox(width: 6),
                    Text('${provider.streakDays} day streak',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: _kGold)),
                  ],
                ),
              ),
            ],
          );

          if (!wide) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              title, const SizedBox(height: 14), badges,
            ]);
          }
          return Row(children: [
            Expanded(child: title),
            badges,
          ]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Content router: loading / error / no-challenge / completed / active
// ─────────────────────────────────────────────────────────────
class _ChallengeContent extends StatelessWidget {
  const _ChallengeContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();

    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: kDeep)),
      );
    }
    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(provider.error!, style: TextStyle(fontSize: 13, color: kMu)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<ChallengeProvider>().loadTodaysChallenge(),
              child: Text('Retry', style: TextStyle(fontSize: 13, color: kGreen)),
            ),
          ],
        ),
      );
    }
    if (provider.currentChallenge == null) {
      return const _NoChallengeState();
    }
    if (provider.hasCompleted) {
      return const _AlreadyCompletedCard();
    }
    return const _ActiveChallengeCard();
  }
}

// ─────────────────────────────────────────────────────────────
// G. NO CHALLENGE STATE
// ─────────────────────────────────────────────────────────────
class _NoChallengeState extends StatelessWidget {
  const _NoChallengeState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 40, color: kMu),
          const SizedBox(height: 14),
          Text('No challenge today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 6),
          Text('Check back tomorrow for a brand new plant challenge!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kMu)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// F. ALREADY COMPLETED STATE
// ─────────────────────────────────────────────────────────────
class _AlreadyCompletedCard extends StatelessWidget {
  const _AlreadyCompletedCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final challenge = provider.currentChallenge!;
    final completion = provider.completion;
    final correct = completion?.isCorrect ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSp24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeChip(type: challenge.type),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                size: 28,
                color: correct ? kHealthyTx : kUnhealthyTx,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You've completed today's challenge",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
                    const SizedBox(height: 4),
                    Text(
                      completion != null
                          ? 'Your answer: ${completion.answerGiven ?? '—'}  ·  +${completion.pointsEarned} pts'
                          : 'Come back tomorrow for a new one.',
                      style: TextStyle(fontSize: 12, color: kMu),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  icon: Icons.local_fire_department,
                  label: 'Current streak',
                  value: '${provider.streakDays} days',
                  color: kAccent,
                ),
              ),
              Expanded(
                child: _StatBlock(
                  icon: Icons.timer_outlined,
                  label: 'Next challenge in',
                  valueWidget: _CountdownToTomorrow(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx),
                  ),
                  color: kDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color color;
  const _StatBlock({required this.icon, required this.label, required this.color, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: kMu)),
        ]),
        const SizedBox(height: 6),
        valueWidget ??
            Text(value ?? '—',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// B-E. ACTIVE CHALLENGE CARD
// ─────────────────────────────────────────────────────────────
class _ActiveChallengeCard extends StatelessWidget {
  const _ActiveChallengeCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final challenge = provider.currentChallenge!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kSp24),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: kBR2xl,
            border: Border.all(color: kBorder, width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeChip(type: challenge.type),
                  const Spacer(),
                  if (!provider.isSubmitted) _ElapsedTimer(seconds: provider.timeElapsed),
                ],
              ),
              const SizedBox(height: 14),
              Text(challenge.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTx)),
              const SizedBox(height: 6),
              Text(challenge.description,
                  style: TextStyle(fontSize: 13, color: kMu, height: 1.5)),
              if (challenge.speciesId != null) ...[
                const SizedBox(height: 16),
                _ChallengeSpeciesImage(speciesId: challenge.speciesId!),
              ],
              const SizedBox(height: 18),
              Text(challenge.question,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx, height: 1.4)),
              const SizedBox(height: 18),
              if (challenge.type == ChallengeType.findIt)
                const _FindItInput()
              else
                _AnswerOptions(challenge: challenge),
              const SizedBox(height: 18),
              _SubmitButton(challenge: challenge),
            ],
          ),
        ),
        if (provider.isSubmitted) ...[
          const SizedBox(height: 20),
          _SlideUpReveal(child: _ResultPanel(challenge: challenge)),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ChallengeType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final style = _typeStyles[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
      child: Text(type.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: style.text)),
    );
  }
}

class _ElapsedTimer extends StatelessWidget {
  final int seconds;
  const _ElapsedTimer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 12, color: kMu),
        const SizedBox(width: 4),
        Text('${seconds}s', style: TextStyle(fontSize: 11, color: kMu)),
      ],
    );
  }
}

class _ChallengeSpeciesImage extends StatelessWidget {
  final String speciesId;
  const _ChallengeSpeciesImage({required this.speciesId});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SpeciesProvider>().all;
    PlantSpecies? species;
    for (final s in all) {
      if (s.id == speciesId) { species = s; break; }
    }
    final imageUrl = species?.referenceImageUrl;
    if (imageUrl == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: kBRXl,
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          // Banner is 180 tall, full card width.
          memCacheWidth: 700,
          memCacheHeight: 360,
          placeholder: (_, __) => Container(color: kMuted),
          errorWidget: (_, __, ___) => Container(
            color: kMuted,
            child: Center(child: Icon(Icons.eco_outlined, size: 32, color: kMu)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// C. ANSWER OPTIONS
// ─────────────────────────────────────────────────────────────
class _AnswerOptions extends StatelessWidget {
  final DailyChallenge challenge;
  const _AnswerOptions({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    return Column(
      children: challenge.options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OptionCard(
            option: opt,
            selected: provider.selectedAnswer == opt,
            submitted: provider.isSubmitted,
            isCorrectAnswer: opt == challenge.correctAnswer,
            onTap: () => context.read<ChallengeProvider>().selectAnswer(opt),
          ),
        );
      }).toList(),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String option;
  final bool selected;
  final bool submitted;
  final bool isCorrectAnswer;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.submitted,
    required this.isCorrectAnswer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = kWhite;
    Color border = kBorder;
    Color text = kTx;
    Widget? trailing;

    if (!submitted) {
      if (selected) {
        bg = kGreen;
        border = kGreen;
        text = Colors.white;
      }
    } else {
      if (isCorrectAnswer) {
        bg = kHealthyBg;
        border = kHealthyTx;
        text = kHealthyTx;
        trailing = Icon(Icons.check_circle, size: 20, color: kHealthyTx);
      } else if (selected) {
        bg = kUnhealthyBg;
        border = kUnhealthyTx;
        text = kUnhealthyTx;
        trailing = Icon(Icons.cancel, size: 20, color: kUnhealthyTx);
      } else {
        text = kMu;
      }
    }

    return GestureDetector(
      onTap: submitted ? null : onTap,
      child: AnimatedScale(
        scale: selected && !submitted ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: selected || (submitted && isCorrectAnswer) ? 1.6 : 1),
            borderRadius: kBRLg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(option,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _FindItInput extends StatefulWidget {
  const _FindItInput();

  @override
  State<_FindItInput> createState() => _FindItInputState();
}

class _FindItInputState extends State<_FindItInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    return TextField(
      controller: _controller,
      enabled: !provider.isSubmitted,
      onChanged: (v) => context.read<ChallengeProvider>().selectAnswer(v.trim()),
      style: TextStyle(fontSize: 14, color: kTx),
      decoration: const InputDecoration(
        hintText: 'Type the plant name...',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// D. SUBMIT BUTTON
// ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final DailyChallenge challenge;
  const _SubmitButton({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final canSubmit = provider.selectedAnswer != null &&
        provider.selectedAnswer!.isNotEmpty &&
        !provider.isSubmitted;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isSubmitted
            ? () => Scrollable.ensureVisible(
                  _ResultPanel.keyFor(challenge.id).currentContext ?? context,
                  duration: const Duration(milliseconds: 300),
                )
            : (canSubmit ? () => _submit(context) : null),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: kBRLg),
        ),
        child: Text(provider.isSubmitted ? 'View Result' : 'Submit Answer',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final challengeProvider = context.read<ChallengeProvider>();
    await challengeProvider.submitAnswer();
    if (!context.mounted) return;
    context.read<ChallengeBadgeProvider>().refresh();
    // Awarding points and firing streak-milestone notifications happens in
    // ProfileProvider, which is listening to this ChallengeProvider — see
    // _ProfileListenerBridge above.
  }
}

// ─────────────────────────────────────────────────────────────
// E. RESULT PANEL
// ─────────────────────────────────────────────────────────────
class _ResultPanel extends StatelessWidget {
  final DailyChallenge challenge;
  const _ResultPanel({required this.challenge});

  // Only the current day's challenge is ever mounted at a time, so this
  // only needs to remember one (id, key) pair — not accumulate a new
  // GlobalKey for every distinct challenge this browser tab has ever seen
  // across however many days it stays open.
  static String? _cachedChallengeId;
  static GlobalKey? _cachedKey;
  static GlobalKey keyFor(String challengeId) {
    if (_cachedChallengeId != challengeId || _cachedKey == null) {
      _cachedChallengeId = challengeId;
      _cachedKey = GlobalKey();
    }
    return _cachedKey!;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();
    final correct = provider.isCorrect;
    final buildingStreak = correct && provider.streakDays >= 2;

    return Container(
      key: keyFor(challenge.id),
      width: double.infinity,
      padding: const EdgeInsets.all(kSp24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(correct ? '✅' : '❌', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text(
                  correct
                      ? 'Correct! +${provider.pointsEarned} points'
                      : 'Not quite — the answer was ${provider.correctAnswer}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: correct ? kHealthyTx : kUnhealthyTx),
                ),
              ],
            ),
          ),
          if (provider.funFact != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kLight, borderRadius: kBRLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: kGreen),
                    const SizedBox(width: 7),
                    Text('Did you know?',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kGreen)),
                  ]),
                  const SizedBox(height: 7),
                  Text(provider.funFact!,
                      style: TextStyle(fontSize: 13, color: kTx, height: 1.6)),
                ],
              ),
            ),
          ],
          if (buildingStreak) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: kAccentL,
                borderRadius: kBRLg,
                border: Border.all(color: kAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: kAccent),
                  const SizedBox(width: 6),
                  Text('🔥 ${provider.streakDays}-day streak! Keep it up!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kAccent)),
                ],
              ),
            ),
          ],
          if (challenge.speciesId != null) ...[
            const SizedBox(height: 16),
            _ViewSpeciesButton(speciesId: challenge.speciesId!),
          ],
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          // Wrap rather than Row — the countdown ticks every second and at
          // some widths (esp. this panel's ~303px minimum) the two texts
          // together came within a fraction of a pixel of the container's
          // width, tripping Flutter's overflow assertion. Wrap just flows
          // the countdown onto its own line instead of ever overflowing.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Come back tomorrow — next challenge in ',
                  style: TextStyle(fontSize: 12, color: kMu)),
              _CountdownToTomorrow(
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTx),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewSpeciesButton extends StatelessWidget {
  final String speciesId;
  const _ViewSpeciesButton({required this.speciesId});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SpeciesProvider>().all;
    PlantSpecies? species;
    for (final s in all) {
      if (s.id == speciesId) { species = s; break; }
    }
    if (species == null) return const SizedBox.shrink();
    final found = species;

    final colors = colorPairForId(found.id);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showPlantDetailModal(
          context,
          species: found,
          type: found.growthType ?? '',
          healthy: true,
          cardColor: Color(colors[0]),
          iconColor: Color(colors[1]),
        ),
        icon: const Icon(Icons.eco_outlined, size: 16),
        label: const Text('View This Species'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared: slide-up reveal + live countdown
// ─────────────────────────────────────────────────────────────
class _SlideUpReveal extends StatefulWidget {
  final Widget child;
  const _SlideUpReveal({required this.child});

  @override
  State<_SlideUpReveal> createState() => _SlideUpRevealState();
}

class _SlideUpRevealState extends State<_SlideUpReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: widget.child,
      ),
    );
  }
}

class _CountdownToTomorrow extends StatefulWidget {
  final TextStyle style;
  const _CountdownToTomorrow({required this.style});

  @override
  State<_CountdownToTomorrow> createState() => _CountdownToTomorrowState();
}

class _CountdownToTomorrowState extends State<_CountdownToTomorrow> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _remaining = tomorrow.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$h:$m:$s', style: widget.style);
  }
}
