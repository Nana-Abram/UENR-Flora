// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../widgets/breadcrumb.dart';
import '../models/achievement_model.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';

const _kRareBg = Color(0xFFE8F0FF);
const _kRareTx = Color(0xFF2979FF);
const _kLegendaryBg = Color(0xFFFFFDE7);
const _kLegendaryTx = Color(0xFFB8860B);

class _RarityStyle {
  final Color bg;
  final Color text;
  const _RarityStyle(this.bg, this.text);
}

_RarityStyle _rarityStyle(String rarity) {
  switch (rarity) {
    case 'rare':
      return const _RarityStyle(_kRareBg, _kRareTx);
    case 'legendary':
      return const _RarityStyle(_kLegendaryBg, _kLegendaryTx);
    case 'common':
    default:
      return const _RarityStyle(kMuted, kMu);
  }
}

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _formatUnlockDate(DateTime d) => '${d.day} ${_kMonths[d.month - 1]} ${d.year}';

String _formatShortDate(DateTime d) {
  final now = DateTime.now();
  final justDate = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(justDate).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${_kMonths[d.month - 1]}';
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(current: 'Profile'),
                    SizedBox(height: 16),
                    _HeroHeader(),
                    SizedBox(height: kSp16),
                    _StatsRow(),
                    SizedBox(height: kSp16),
                    _ChallengeStatsCard(),
                    SizedBox(height: kSp16),
                    _AchievementsSection(),
                    SizedBox(height: kSp16),
                    _RecentActivitySection(),
                    _DangerZone(),
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
// A. HERO HEADER
// ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (provider.isLoading || profile == null) {
      return Container(
        height: 190,
        decoration: BoxDecoration(color: kDeep, borderRadius: kBR2xl),
        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }

    final levelInfo = profile.levelInfo;
    final next = profile.nextLevelInfo;
    final progress = next == null ? 1.0 : (profile.totalPoints / next.threshold).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeep, kGreen],
        ),
        borderRadius: kBR2xl,
      ),
      padding: const EdgeInsets.all(kSp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarPicker(emoji: profile.avatarEmoji),
              const SizedBox(width: kSp16),
              Expanded(child: _NameAndLevel(name: profile.displayName, levelInfo: levelInfo)),
            ],
          ),
          const SizedBox(height: kSp20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${profile.totalPoints}',
                  style: const TextStyle(
                      fontFamily: kFontDisplay, fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('pts', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: kBRPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFAC775)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Max level reached!'
                : '${profile.totalPoints} / ${next.threshold} pts to ${next.name}',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String emoji;
  const _AvatarPicker({required this.emoji});

  static const _emojiOptions = [
    '🌱', '🌿', '🌳', '🌲', '🍃', '🌾', '🌵', '🌴', '🌺', '🌸',
    '🦋', '🐝', '🦎', '🦜', '🌍', '🔬', '📸', '🏆', '⚡', '🎯',
  ];

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(kSp24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose an avatar',
                style: TextStyle(
                    fontFamily: kFontDisplay, fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: kSp16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _emojiOptions
                  .map((e) => GestureDetector(
                        onTap: () => Navigator.pop(ctx, e),
                        child: Container(
                          decoration: const BoxDecoration(color: kMuted, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: kSp8),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      context.read<ProfileProvider>().editAvatar(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: kMint.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: kAccent,
                shape: BoxShape.circle,
                border: Border.all(color: kDeep, width: 1.5),
              ),
              child: const Icon(Icons.edit, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameAndLevel extends StatefulWidget {
  final String name;
  final LevelInfo levelInfo;
  const _NameAndLevel({required this.name, required this.levelInfo});

  @override
  State<_NameAndLevel> createState() => _NameAndLevelState();
}

class _NameAndLevelState extends State<_NameAndLevel> {
  bool _editing = false;
  late final TextEditingController _ctrl = TextEditingController(text: widget.name);

  @override
  void didUpdateWidget(covariant _NameAndLevel old) {
    super.didUpdateWidget(old);
    if (!_editing && old.name != widget.name) _ctrl.text = widget.name;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save(String value) {
    final v = value.trim();
    if (v.isNotEmpty) context.read<ProfileProvider>().editName(v);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _editing
            ? SizedBox(
                width: 220,
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: const TextStyle(
                      fontFamily: kFontDisplay, fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: kBRMd, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: kBRMd, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
                  ),
                  onSubmitted: _save,
                ),
              )
            : GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(widget.name,
                          style: const TextStyle(
                              fontFamily: kFontDisplay, fontSize: 19, fontWeight: FontWeight.w500, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 13, color: kMint),
                  ],
                ),
              ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: kBRPill),
          child: Text('Level ${widget.levelInfo.level} · ${widget.levelInfo.name} ${widget.levelInfo.emoji}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// B. STATS ROW
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
              emoji: '🔥', title: 'Streak', value: '${profile?.streakDays ?? 0}', label: 'days'),
        ),
        const SizedBox(width: kSp12),
        Expanded(
          child: _StatCard(
              emoji: '📸', title: 'Scans', value: '${profile?.totalScans ?? 0}', label: 'plants'),
        ),
        const SizedBox(width: kSp12),
        Expanded(
          child: _StatCard(
              emoji: '🌿',
              title: 'Species',
              value: '${profile?.speciesFound.length ?? 0}',
              label: 'found'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final String label;
  const _StatCard({required this.emoji, required this.title, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSp16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Text(title, style: const TextStyle(fontSize: 11, color: kMu)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w600, color: kTx)),
          Text(label, style: const TextStyle(fontSize: 11, color: kMu)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// C. CHALLENGE STATS
// ─────────────────────────────────────────────────────────────
class _ChallengeStatsCard extends StatelessWidget {
  const _ChallengeStatsCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final totalChallenges = profile?.totalChallenges ?? 0;
    final totalCorrect = profile?.totalCorrect ?? 0;
    final accuracy = totalChallenges == 0 ? 0.0 : totalCorrect / totalChallenges;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSp20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🎯 Challenges Completed: $totalChallenges',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
              Text('${(accuracy * 100).round()}% accuracy',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGreen)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: kBRPill,
            child: LinearProgressIndicator(
              value: accuracy,
              minHeight: 7,
              backgroundColor: kMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
            ),
          ),
          const SizedBox(height: 10),
          Text('Longest streak: ${profile?.longestStreak ?? 0} days',
              style: const TextStyle(fontSize: 12, color: kMu)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// D. ACHIEVEMENTS
// ─────────────────────────────────────────────────────────────
class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final unlockedIds = provider.unlockedAchievements.toSet();
    final sorted = [...kAchievements]
      ..sort((a, b) {
        final aU = unlockedIds.contains(a.id);
        final bU = unlockedIds.contains(b.id);
        if (aU == bU) return 0;
        return aU ? -1 : 1;
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSp20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achievements',
                  style: TextStyle(
                      fontFamily: kFontDisplay, fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
              Text('${unlockedIds.length} / ${kAchievements.length} unlocked',
                  style: const TextStyle(fontSize: 12, color: kMu)),
            ],
          ),
          const SizedBox(height: kSp16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              final a = sorted[i];
              final unlocked = unlockedIds.contains(a.id);
              final isNew = provider.newlyUnlocked.any((n) => n.id == a.id);
              return _ShimmerWrap(
                active: unlocked && isNew,
                child: _AchievementTile(
                    achievement: a, unlocked: unlocked, unlockedAt: provider.unlockedAt[a.id]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final DateTime? unlockedAt;
  const _AchievementTile({required this.achievement, required this.unlocked, this.unlockedAt});

  @override
  Widget build(BuildContext context) {
    final rarity = _rarityStyle(achievement.rarity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? kWhite : kMuted,
        borderRadius: kBRXl,
        border: Border.all(color: unlocked ? kBorder : const Color(0x14000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.3,
                child: Text(achievement.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: unlocked ? rarity.bg : kMuted,
                  borderRadius: kBRPill,
                ),
                child: Text(achievement.rarity,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: unlocked ? rarity.text : kMu)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(achievement.title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: unlocked ? kTx : kMu)),
          const SizedBox(height: 3),
          Expanded(
            child: Text(achievement.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: kMu, height: 1.35)),
          ),
          if (unlocked) ...[
            Text('+${achievement.points} pts',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGreen)),
            if (unlockedAt != null) ...[
              const SizedBox(height: 2),
              Text(_formatUnlockDate(unlockedAt!), style: const TextStyle(fontSize: 9, color: kMu)),
            ],
          ],
        ],
      ),
    );
  }
}

/// Brief diagonal light-sweep played a couple of times right after an
/// achievement unlocks, then stops — [active] is only true for the entries
/// in [ProfileProvider.newlyUnlocked] from the current session.
class _ShimmerWrap extends StatefulWidget {
  final Widget child;
  final bool active;
  const _ShimmerWrap({required this.child, required this.active});

  @override
  State<_ShimmerWrap> createState() => _ShimmerWrapState();
}

class _ShimmerWrapState extends State<_ShimmerWrap> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _ctrl.repeat();
      Future.delayed(const Duration(milliseconds: 2300), () {
        if (mounted) _ctrl.stop();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + 3 * t, -1),
            end: Alignment(3 * t, 1),
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.6), Colors.transparent],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// E. RECENT ACTIVITY
// ─────────────────────────────────────────────────────────────
class _RecentActivitySection extends StatefulWidget {
  const _RecentActivitySection();

  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  List<RecentScan>? _scans;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deviceId = context.read<ProfileProvider>().deviceId;
    if (deviceId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final scans = await context.read<ProfileService>().getRecentScans(deviceId);
      if (mounted) setState(() { _scans = scans; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: kSp16),
      padding: const EdgeInsets.all(kSp20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(
                      fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
              Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => ctx.go('/explorer'),
                  child: const Text('View all scans', style: TextStyle(fontSize: 12, color: kGreen)),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: kDeep, strokeWidth: 2)),
            )
          else if (_scans == null || _scans!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No scans yet — identify a plant to see your activity here.',
                  style: TextStyle(fontSize: 12, color: kMu)),
            )
          else
            ..._scans!.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(s.matched ? Icons.check_circle : Icons.cancel,
                          size: 16, color: s.matched ? kHealthyTx : kUnhealthyTx),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.speciesName,
                            style: const TextStyle(fontSize: 13, color: kTx),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(_formatShortDate(s.date), style: const TextStyle(fontSize: 11, color: kMu)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// F. DANGER ZONE
// ─────────────────────────────────────────────────────────────
class _DangerZone extends StatelessWidget {
  const _DangerZone();

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: kBRXl),
        title: const Text('Reset your data?',
            style: TextStyle(fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
        content: const Text(
            'This permanently deletes your points, streaks, achievements, and scan history. This cannot be undone.',
            style: TextStyle(fontSize: 13, color: kMu, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kUnhealthyTx),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProfileProvider>().resetData();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Your data has been reset.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _confirmReset(context),
        style: TextButton.styleFrom(foregroundColor: kMu),
        icon: const Icon(Icons.delete_outline, size: 14, color: kMu),
        label: const Text('Reset my data', style: TextStyle(fontSize: 12, color: kMu)),
      ),
    );
  }
}
