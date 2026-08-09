// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/app_icons.dart';
import '../../../core/category_style.dart';
import '../../../core/species_provider.dart';
import '../../../core/favorites_provider.dart';
import '../../../core/theme_mode_provider.dart';
import '../../../core/string_utils.dart';
import '../../../models/plant_species.dart';
import '../../../widgets/breadcrumb.dart';
import '../../../widgets/hover_lift.dart';
import '../../../widgets/pill_badge.dart';
import '../../../widgets/plant_detail_modal.dart';
import '../../../widgets/scan_activity_bar_chart.dart';
import '../../../widgets/stat_card.dart';
import '../models/achievement_model.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';

const _kRareBg = Color(0xFFE8F0FF);
const _kRareTx = Color(0xFF2979FF);
const _kLegendaryBg = Color(0xFFFFFDE7);
const _kLegendaryTx = Color(0xFFB8860B);
const _kFireBg = Color(0xFFFFF1E0);
const _kFireTx = Color(0xFFE07B39);
const _kGold = Color(0xFFFAC775);

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
      return _RarityStyle(kMuted, kMu);
  }
}

// ── Avatar icon options — a device's chosen "look", stored as a short key
// string in the same `avatar_emoji` column that used to hold a literal
// emoji. Unrecognised/legacy values fall back gracefully in [_avatarIcon].
const List<MapEntry<String, IconData>> _kAvatarIcons = [
  MapEntry('spa', Icons.spa_outlined),
  MapEntry('grass', Icons.grass_outlined),
  MapEntry('eco', Icons.eco_outlined),
  MapEntry('park', Icons.park_outlined),
  MapEntry('forest', Icons.forest_outlined),
  MapEntry('local_florist', Icons.local_florist_outlined),
  MapEntry('water_drop', Icons.water_drop_outlined),
  MapEntry('wb_sunny', Icons.wb_sunny_outlined),
  MapEntry('terrain', Icons.terrain_outlined),
  MapEntry('pets', Icons.pets_outlined),
  MapEntry('bug_report', Icons.bug_report_outlined),
  MapEntry('camera', Icons.camera_alt_outlined),
  MapEntry('menu_book', Icons.menu_book_outlined),
  MapEntry('emoji_events', Icons.emoji_events_outlined),
  MapEntry('bolt', Icons.bolt_outlined),
  MapEntry('track_changes', Icons.track_changes_outlined),
  MapEntry('public', Icons.public_outlined),
  MapEntry('explore', Icons.explore_outlined),
  MapEntry('star', Icons.star_outline),
  MapEntry('auto_awesome', Icons.auto_awesome_outlined),
];

// Human-readable label for each avatar icon key, for screen readers — the
// raw keys ('wb_sunny', 'local_florist') read as gibberish otherwise.
const Map<String, String> _kAvatarIconLabels = {
  'spa': 'Spa',
  'grass': 'Grass',
  'eco': 'Eco',
  'park': 'Park',
  'forest': 'Forest',
  'local_florist': 'Flower',
  'water_drop': 'Water drop',
  'wb_sunny': 'Sun',
  'terrain': 'Terrain',
  'pets': 'Paw print',
  'bug_report': 'Bug',
  'camera': 'Camera',
  'menu_book': 'Book',
  'emoji_events': 'Trophy',
  'bolt': 'Lightning bolt',
  'track_changes': 'Target',
  'public': 'Globe',
  'explore': 'Compass',
  'star': 'Star',
  'auto_awesome': 'Sparkle',
};

IconData _avatarIcon(String key) {
  for (final e in _kAvatarIcons) {
    if (e.key == key) return e.value;
  }
  return Icons.spa_outlined;
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
  /// Raw `?tab=` query value from the route (see app.dart) — e.g. 'saved'
  /// to land directly on the Saved Plants tab instead of the Overview tab
  /// it defaults to. Anything else/null falls back to Overview, same as
  /// visiting /profile with no query param always has.
  final String? initialTab;

  const ProfileScreen({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kDeep,
      // loadProfile() already kicks off loadScans() itself (unawaited) — see
      // ProfileProvider.loadProfile — so awaiting just this one call is
      // enough without double-fetching scan history.
      onRefresh: () => context.read<ProfileProvider>().loadProfile(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Breadcrumb(current: 'Profile'),
                      const SizedBox(height: 16),
                      const _HeroHeader(),
                      const SizedBox(height: kSp20),
                      const _StatsGrid(),
                      const SizedBox(height: kSp20),
                      const _ProfileMainArea(),
                      const SizedBox(height: kSp20),
                      _ProfileTabsSection(initialTab: initialTab),
                      const SizedBox(height: kSp20),
                      const _AppearanceSection(),
                      const SizedBox(height: kSp20),
                      const _LeaderboardLinkCard(),
                      const SizedBox(height: kSp24),
                      const _DangerZone(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDeep, kGreen],
        ),
        borderRadius: kBR2xl,
      ),
      padding: const EdgeInsets.all(kSp24),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= kBreakpointMd;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarPicker(iconKey: profile.avatarEmoji),
              const SizedBox(width: kSp16),
              Expanded(child: _NameAndLevel(name: profile.displayName, levelInfo: levelInfo)),
            ],
          );
          final progressBlock =
              _PointsProgress(profile: profile, next: next, progress: progress, alignEnd: wide);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: identity),
                const SizedBox(width: kSp24),
                SizedBox(width: 230, child: progressBlock),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, const SizedBox(height: kSp20), progressBlock],
          );
        },
      ),
    );
  }
}

class _PointsProgress extends StatelessWidget {
  final UserProfile profile;
  final LevelInfo? next;
  final double progress;
  final bool alignEnd;
  const _PointsProgress(
      {required this.profile, required this.next, required this.progress, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: kBRPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          next == null
              ? 'Max level reached'
              : '${profile.totalPoints} / ${next!.threshold} pts to ${next!.name}',
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String iconKey;
  const _AvatarPicker({required this.iconKey});

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // `isScrollControlled` lets the sheet grow to fit its content instead
      // of clamping to ~half the screen, but on short viewports (small
      // laptop windows, landscape phones) the 20-icon grid can still exceed
      // the screen — the outer height cap + SingleChildScrollView makes it
      // scroll in that case instead of overflowing.
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kSp24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose an avatar',
                  style: TextStyle(
                      fontFamily: kFontDisplay, fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
              const SizedBox(height: kSp16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: _kAvatarIcons.map((e) {
                  final selected = e.key == iconKey;
                  final label = _kAvatarIconLabels[e.key] ?? e.key;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: selected ? '$label (selected)' : label,
                    child: Tooltip(
                      message: label,
                      excludeFromSemantics: true,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, e.key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? kAccentL : kMuted,
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: kAccent, width: 1.5) : null,
                          ),
                          alignment: Alignment.center,
                          child: Icon(e.value, size: 22, color: selected ? kGreen : kMu),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: kSp8),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      context.read<ProfileProvider>().editAvatar(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Semantics/Tooltip on the whole tap target (the avatar circle + pencil
    // overlay act as one button) rather than on the small pencil icon
    // alone, since that's what's actually tappable here.
    return Semantics(
      button: true,
      label: 'Change avatar',
      child: Tooltip(
        message: 'Change avatar',
        excludeFromSemantics: true,
        child: GestureDetector(
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
                child: Center(child: Icon(_avatarIcon(iconKey), size: 34, color: kDeep)),
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
        ),
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Enter (onSubmitted) isn't the only way users leave the field — on
    // web the natural instinct is to just click elsewhere, which doesn't
    // fire onSubmitted at all. Without this, that click silently discards
    // the typed name the moment the field loses focus.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _editing) _save(_ctrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant _NameAndLevel old) {
    super.didUpdateWidget(old);
    if (!_editing && old.name != widget.name) _ctrl.text = widget.name;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _save(String value) {
    if (!_editing) return;
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
                  focusNode: _focusNode,
                  autofocus: true,
                  onTapOutside: (_) => _focusNode.unfocus(),
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
                    Icon(Icons.edit, size: 13, color: kMint),
                  ],
                ),
              ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: kBRPill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.levelInfo.icon, size: 13, color: Colors.white),
              const SizedBox(width: 6),
              Text('Level ${widget.levelInfo.level} · ${widget.levelInfo.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// B. STATS GRID
// ─────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final totalChallenges = profile?.totalChallenges ?? 0;
    final totalCorrect = profile?.totalCorrect ?? 0;
    final accuracy = totalChallenges == 0 ? 0.0 : totalCorrect / totalChallenges;

    final cards = [
      StatCardData(
          icon: kIconStreak,
          iconColor: _kFireTx,
          iconBg: _kFireBg,
          topLabel: 'Streak',
          value: '${profile?.streakDays ?? 0}',
          bottomLabel: 'days'),
      StatCardData(
          icon: kIconCamera,
          iconColor: kAccent,
          iconBg: kAccentL,
          topLabel: 'Scans',
          value: '${profile?.totalScans ?? 0}',
          bottomLabel: 'plants'),
      StatCardData(
          icon: kIconLeaf,
          iconColor: kDeep,
          iconBg: kLight,
          topLabel: 'Species',
          value: '${profile?.speciesFound.length ?? 0}',
          bottomLabel: 'found'),
      StatCardData(
          icon: kIconTarget,
          iconColor: kHealthyTx,
          iconBg: kHealthyBg,
          topLabel: 'Accuracy',
          value: totalChallenges == 0 ? '—' : '${(accuracy * 100).round()}%',
          bottomLabel: 'challenges'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= kBreakpointMd ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: kSp12,
            mainAxisSpacing: kSp12,
            mainAxisExtent: 112,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => StatCard(
            data: cards[i],
            iconCircleSize: 26,
            iconSize: 13,
            valueStyle: TextStyle(
                fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w600, color: kTx),
            cardRadius: kBRXl,
            shadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────
// C. MAIN AREA — achievements + activity (main column) alongside
// challenge performance (sidebar) on wide screens; stacked on narrow.
// ─────────────────────────────────────────────────────────────
class _ProfileMainArea extends StatelessWidget {
  const _ProfileMainArea();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= kBreakpointLg;
        if (wide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _AchievementsSection()),
              SizedBox(width: kSp20),
              Expanded(flex: 1, child: _ChallengePerformanceCard()),
            ],
          );
        }
        return const Column(
          children: [
            _ChallengePerformanceCard(),
            SizedBox(height: kSp16),
            _AchievementsSection(),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// D. CHALLENGE PERFORMANCE
// ─────────────────────────────────────────────────────────────
class _ChallengePerformanceCard extends StatelessWidget {
  const _ChallengePerformanceCard();

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
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: kLight, shape: BoxShape.circle),
                child: Icon(kIconTarget, size: 16, color: kDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Challenge Performance',
                    style: TextStyle(
                        fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
              ),
            ],
          ),
          const SizedBox(height: kSp20),
          Center(
            child: SizedBox(
              width: 116,
              height: 116,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 116,
                    height: 116,
                    child: CircularProgressIndicator(
                      value: totalChallenges == 0 ? 0 : accuracy,
                      strokeWidth: 9,
                      backgroundColor: kMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(kGreen),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(totalChallenges == 0 ? '—' : '${(accuracy * 100).round()}%',
                          style: TextStyle(
                              fontFamily: kFontDisplay, fontSize: 22, fontWeight: FontWeight.w600, color: kTx)),
                      Text('accuracy', style: TextStyle(fontSize: 10, color: kMu)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSp20),
          const Divider(height: 1),
          const SizedBox(height: kSp16),
          _StatLine(
              icon: kIconQuizCorrect,
              iconColor: kHealthyTx,
              label: 'Challenges completed',
              value: '$totalChallenges'),
          const SizedBox(height: 10),
          _StatLine(
              icon: kIconStreak,
              iconColor: _kFireTx,
              label: 'Longest streak',
              value: '${profile?.longestStreak ?? 0} days'),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatLine({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: kMu))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTx)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// E. ACHIEVEMENTS
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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: _kLegendaryBg, shape: BoxShape.circle),
                    child: const Icon(kIconMedal, size: 16, color: _kLegendaryTx),
                  ),
                  const SizedBox(width: 10),
                  Text('Achievements',
                      style: TextStyle(
                          fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
                ],
              ),
              Text('${unlockedIds.length} / ${kAchievements.length} unlocked',
                  style: TextStyle(fontSize: 12, color: kMu)),
            ],
          ),
          const SizedBox(height: kSp16),
          LayoutBuilder(
            builder: (context, c) {
              Widget tileFor(int i) {
                final a = sorted[i];
                final unlocked = unlockedIds.contains(a.id);
                final isNew = provider.newlyUnlocked.any((n) => n.id == a.id);
                return _ShimmerWrap(
                  active: unlocked && isNew,
                  child: HoverLift(
                    borderRadius: kBRXl,
                    child: _AchievementTile(
                        achievement: a, unlocked: unlocked, unlockedAt: provider.unlockedAt[a.id]),
                  ),
                );
              }

              // Below 380 a grid column would be too narrow to read
              // comfortably (this used to force a single, full-width
              // column here, meaning "scroll past 12 stacked cards" just
              // to see the rest of the profile) — a horizontal strip of
              // fixed-width cards reads better at phone widths and keeps
              // the achievements list from dominating the whole page.
              if (c.maxWidth < 380) {
                return SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => SizedBox(width: 160, child: tileFor(i)),
                  ),
                );
              }

              final cols = c.maxWidth >= 620 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 148,
                ),
                itemCount: sorted.length,
                itemBuilder: (_, i) => tileFor(i),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: unlocked ? rarity.bg : kMuted, shape: BoxShape.circle),
                child: Icon(unlocked ? achievement.icon : kIconLock,
                    size: 16, color: unlocked ? rarity.text : kMu),
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
                style: TextStyle(fontSize: 11, color: kMu, height: 1.35)),
          ),
          if (unlocked)
            Row(
              children: [
                Text('+${achievement.points} pts',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGreen)),
                if (unlockedAt != null) ...[
                  Text(' · ', style: TextStyle(fontSize: 11, color: kMu)),
                  Text(_formatUnlockDate(unlockedAt!), style: TextStyle(fontSize: 10, color: kMu)),
                ],
              ],
            )
          else
            Text('Locked', style: TextStyle(fontSize: 10, color: kMu)),
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
// F. RECENT ACTIVITY — shown inside the Overview tab (below).
// ─────────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RecentActivityCard({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final scans = provider.scans.take(5).toList();

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
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: kAccentL, shape: BoxShape.circle),
                    child: Icon(kIconCalendar, size: 15, color: kAccent),
                  ),
                  const SizedBox(width: 10),
                  Text('Recent Activity',
                      style: TextStyle(
                          fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kGreen)),
                    const SizedBox(width: 2),
                    Icon(kIconChevronR, size: 14, color: kGreen),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),
          if (provider.scansLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: kDeep, strokeWidth: 2)),
            )
          else if (scans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No scans yet. Identify a plant to see your activity here.',
                  style: TextStyle(fontSize: 12, color: kMu)),
            )
          else
            Column(
              children: [
                for (int i = 0; i < scans.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(scans[i].matched ? kIconHealthy : kIconCancel,
                            size: 16, color: scans[i].matched ? kHealthyTx : kUnhealthyTx),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(scans[i].speciesName,
                              style: TextStyle(fontSize: 13, color: kTx),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(_formatShortDate(scans[i].date), style: TextStyle(fontSize: 11, color: kMu)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// G. PROFILE TABS — Overview / Saved Plants / Scan History
// ─────────────────────────────────────────────────────────────
enum _ProfileTab { overview, saved, history }

class _ProfileTabsSection extends StatefulWidget {
  final String? initialTab;

  const _ProfileTabsSection({this.initialTab});

  @override
  State<_ProfileTabsSection> createState() => _ProfileTabsSectionState();
}

class _ProfileTabsSectionState extends State<_ProfileTabsSection> {
  late var _tab =
      widget.initialTab == 'saved' ? _ProfileTab.saved : _ProfileTab.overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileTabBar(value: _tab, onChanged: (t) => setState(() => _tab = t)),
        const SizedBox(height: kSp16),
        switch (_tab) {
          _ProfileTab.overview => Column(
              children: [
                const _SpeciesProgressCard(),
                const SizedBox(height: kSp16),
                const _MyScanActivityCard(),
                const SizedBox(height: kSp16),
                _RecentActivityCard(onViewAll: () => setState(() => _tab = _ProfileTab.history)),
              ],
            ),
          _ProfileTab.saved => const _SavedPlantsTab(),
          _ProfileTab.history => const _ScanHistoryTab(),
        },
      ],
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  final _ProfileTab value;
  final ValueChanged<_ProfileTab> onChanged;
  const _ProfileTabBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget segment(_ProfileTab t, String label) {
      final selected = t == value;
      return GestureDetector(
        onTap: () => onChanged(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kWhite : Colors.transparent,
            borderRadius: kBRPill,
            border: selected ? Border.all(color: kBorder, width: 0.5) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? kTx : kMu,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kMuted, borderRadius: kBRPill),
      // Scrollable rather than a plain Row — on narrow phone widths, three
      // segments plus their padding no longer fit ("Scan History" was
      // clipped mid-word with a few pixels of RenderFlex overflow). This
      // stays a no-op (nothing to scroll) at any width wide enough to fit
      // all three already.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment(_ProfileTab.overview, 'Overview'),
            segment(_ProfileTab.saved, 'Saved Plants'),
            segment(_ProfileTab.history, 'Scan History'),
          ],
        ),
      ),
    );
  }
}

// ── G1. Species Progress — count of favorite... no, of *identified*
//    (profile.speciesFound) species per category vs. how many exist in
//    that category across the whole live species table.
class _SpeciesProgressCard extends StatelessWidget {
  const _SpeciesProgressCard();

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SpeciesProvider>().all;
    final found = context.watch<ProfileProvider>().profile?.speciesFound.toSet() ?? const <String>{};

    // Medicinal use isn't tracked here: every species in the live database
    // has a non-empty medicinal_uses field, so a "Medicinal plants" row
    // would always read identical to the overall species-found count —
    // not a meaningfully distinct category.
    final categories = <(String, bool Function(PlantSpecies))>[
      ('Trees identified', (s) => s.growthType == 'trees'),
      ('Ornamentals', (s) => s.growthType == 'ornamental'),
      ('Herbs identified', (s) => s.growthType == 'herbs'),
    ];

    final rows = categories
        .map((c) {
          final total = all.where(c.$2).length;
          final done = all.where((s) => found.contains(s.id) && c.$2(s)).length;
          return (label: c.$1, done: done, total: total);
        })
        .where((r) => r.total > 0)
        .toList();

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
          Text('Species Progress',
              style: TextStyle(
                  fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: kSp16),
          if (rows.isEmpty)
            Text('No species data yet.', style: TextStyle(fontSize: 12, color: kMu))
          else
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _ProgressRow(
                  label: rows[i].label, done: rows[i].done, total: rows[i].total),
            ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  const _ProgressRow({required this.label, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
            Text('$done/$total', style: TextStyle(fontSize: 12, color: kMu)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: kBRPill,
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 7,
            backgroundColor: kMuted,
            valueColor: AlwaysStoppedAnimation<Color>(kGreen),
          ),
        ),
      ],
    );
  }
}

// ── G2. My Scan Activity — this device's own scans, monthly, Jan..now.
const _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

class _MyScanActivityCard extends StatelessWidget {
  const _MyScanActivityCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final now = DateTime.now();
    final currentMonth = now.month;
    final counts = List<int>.filled(currentMonth, 0);
    for (final s in provider.scans) {
      if (s.date.year == now.year && s.date.month <= currentMonth) {
        counts[s.date.month - 1]++;
      }
    }

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
          Text('My Scan Activity',
              style: TextStyle(
                  fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: kSp20),
          if (provider.scansLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: kDeep, strokeWidth: 2)),
            )
          else if (provider.scans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No scan activity yet. Identify a plant to see your trend.',
                    style: TextStyle(fontSize: 12, color: kMu)),
              ),
            )
          else
            ScanActivityBarChart(
              counts: counts,
              height: 200,
              buildLabel: (i) => Text(_kMonthAbbr[i], style: TextStyle(fontSize: 11, color: kMu)),
            ),
        ],
      ),
    );
  }
}

// ── G3. Saved Plants — species this device has favorited.
class _SavedPlantsTab extends StatelessWidget {
  const _SavedPlantsTab();

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final all = context.watch<SpeciesProvider>().all;
    final saved = all.where((s) => favorites.isFavorite(s.id)).toList();

    if (!favorites.loaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: kDeep, strokeWidth: 2)),
      );
    }

    if (saved.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: kSp20),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBRXl,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.favorite_border, size: 32, color: kMu),
            const SizedBox(height: 10),
            Text('No saved plants yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 4),
            Text('Tap the heart icon on any plant to save it here.',
                style: TextStyle(fontSize: 12, color: kMu)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= kBreakpointMd ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: kSp16,
            mainAxisSpacing: kSp16,
            mainAxisExtent: 236,
          ),
          itemCount: saved.length,
          itemBuilder: (_, i) =>
              _SavedPlantTile(key: ValueKey(saved[i].id), species: saved[i]),
        );
      },
    );
  }
}

class _SavedPlantTile extends StatelessWidget {
  final PlantSpecies species;
  const _SavedPlantTile({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final type = species.growthType ?? '';
    final style = categoryStyle(type);

    return HoverLift(
      borderRadius: kBRXl,
      onTap: () => showPlantDetailModal(
        context,
        species: species,
        type: type,
        healthy: true,
        cardColor: cardColor,
        iconColor: iconColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder, width: 0.5),
          borderRadius: kBRXl,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: species.referenceImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: species.referenceImageUrl!,
                          fit: BoxFit.cover,
                          // Saved-plant tile is 120 tall, up to a third of
                          // a wide profile column.
                          memCacheWidth: 400,
                          memCacheHeight: 240,
                          placeholder: (_, __) => Container(
                            color: cardColor,
                            child: Center(child: Icon(Icons.eco_outlined, size: 32, color: iconColor)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: cardColor,
                            child: Center(child: Icon(Icons.eco_outlined, size: 32, color: iconColor)),
                          ),
                        )
                      : Container(
                          color: cardColor,
                          child: Center(child: Icon(Icons.eco_outlined, size: 32, color: iconColor)),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => context.read<FavoritesProvider>().toggle(species.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, size: 14, color: kUnhealthyTx),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species.commonName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTx),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(species.scientificName,
                      style: TextStyle(fontSize: 11, color: kMu, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
                      child: Text(capitalize(type),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: style.text)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── G4. Scan History — every scan this device has made, grouped by day.
class _ScanHistoryTab extends StatelessWidget {
  const _ScanHistoryTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    if (provider.scansLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: kDeep, strokeWidth: 2)),
      );
    }

    if (provider.scans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: kSp20),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBRXl,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Center(
          child: Text('No scans yet. Identify a plant to see your history here.',
              style: TextStyle(fontSize: 12, color: kMu)),
        ),
      );
    }

    // Group consecutive scans by calendar day — the query already orders
    // newest first, so a single pass preserves that order within/between
    // groups.
    final groups = <(DateTime, List<RecentScan>)>[];
    for (final scan in provider.scans) {
      final day = DateTime(scan.date.year, scan.date.month, scan.date.day);
      if (groups.isNotEmpty && groups.last.$1 == day) {
        groups.last.$2.add(scan);
      } else {
        groups.add((day, [scan]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(_scanGroupHeader(group.$1),
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: kMu, letterSpacing: 0.4)),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: kSp16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: kBRXl,
              border: Border.all(color: kBorder, width: 0.5),
            ),
            child: Column(
              children: [
                for (int i = 0; i < group.$2.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: kSp16, endIndent: kSp16),
                  _ScanHistoryRow(scan: group.$2[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _scanGroupHeader(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  final full = '${day.day} ${_kMonths[day.month - 1]} ${day.year}';
  if (diff == 0) return 'TODAY ($full)'.toUpperCase();
  if (diff == 1) return 'YESTERDAY ($full)'.toUpperCase();
  return full.toUpperCase();
}

class _ScanHistoryRow extends StatelessWidget {
  final RecentScan scan;
  const _ScanHistoryRow({required this.scan});

  @override
  Widget build(BuildContext context) {
    final health = scan.healthStatus;
    final confidence = scan.confidence;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 44,
              height: 44,
              child: scan.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: scan.imageUrl!,
                      fit: BoxFit.cover,
                      // Fixed 44x44 avatar-sized thumbnail.
                      memCacheWidth: 88,
                      memCacheHeight: 88,
                      placeholder: (_, __) => Container(
                          color: kMuted, child: Icon(Icons.eco_outlined, size: 18, color: kMu)),
                      errorWidget: (_, __, ___) => Container(
                          color: kMuted, child: Icon(Icons.eco_outlined, size: 18, color: kMu)),
                    )
                  : Container(
                      color: kMuted, child: Icon(Icons.eco_outlined, size: 18, color: kMu)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.speciesName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (scan.scientificName != null) ...[
                  const SizedBox(height: 2),
                  Text(scan.scientificName!,
                      style: TextStyle(fontSize: 11, color: kMu, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (confidence != null) ...[
                Text('Confidence', style: TextStyle(fontSize: 10, color: kMu)),
                Text('${(confidence * 100).round()}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTx)),
                const SizedBox(height: 4),
              ],
              if (health == 'healthy' || health == 'unhealthy')
                PillBadge(healthy: health == 'healthy'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// F½. APPEARANCE
// ─────────────────────────────────────────────────────────────
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeModeProvider>().mode;

    Widget seg(String label, IconData icon, ThemeMode value) {
      final active = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.read<ThemeModeProvider>().setMode(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? kWhite : Colors.transparent,
              borderRadius: kBRPill,
              border: active ? Border.all(color: kBorder, width: 0.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: active ? kTx : kMu),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: active ? kTx : kMu)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kSp16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBRXl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance',
              style: TextStyle(
                  fontFamily: kFontDisplay, fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: kSp12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: kMuted, borderRadius: kBRPill),
            child: Row(
              children: [
                seg('System', Icons.brightness_auto_outlined, ThemeMode.system),
                seg('Light', Icons.light_mode_outlined, ThemeMode.light),
                seg('Dark', Icons.dark_mode_outlined, ThemeMode.dark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardLinkCard extends StatelessWidget {
  const _LeaderboardLinkCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: kBRXl,
      onTap: () => context.go('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBRXl,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kAccentL, borderRadius: kBRMd),
              child: Icon(Icons.emoji_events_outlined, size: 18, color: kDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leaderboard',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
                  const SizedBox(height: 2),
                  Text('See how your points compare (opt-in only)',
                      style: TextStyle(fontSize: 12, color: kMu)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: kMu),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// G. DANGER ZONE
// ─────────────────────────────────────────────────────────────
class _DangerZone extends StatelessWidget {
  const _DangerZone();

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: kBRXl),
        title: Text('Reset your data?',
            style: TextStyle(fontFamily: kFontDisplay, fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
        content: Text(
            'This permanently deletes your points, streaks, achievements, scan history, and favorites. This cannot be undone.',
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
        await context.read<FavoritesProvider>().clear();
      }
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
        icon: Icon(kIconDelete, size: 14, color: kMu),
        label: Text('Reset my data', style: TextStyle(fontSize: 12, color: kMu)),
      ),
    );
  }
}
