// lib/features/profile/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../widgets/breadcrumb.dart';
import '../models/leaderboard_entry.dart';
import '../providers/profile_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Always refetches on open rather than reusing whatever Profile last
    // loaded — ranks and points shift as other devices play, so a stale
    // list here would be actively misleading, not just outdated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Breadcrumb(current: 'Leaderboard'),
                    const SizedBox(height: 16),
                    Text('Leaderboard',
                        style: TextStyle(
                            fontFamily: kFontDisplay,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: kTx)),
                    const SizedBox(height: 6),
                    Text(
                        "Ranked by points, for devices that have chosen to be listed. Nothing here identifies who anyone actually is beyond the name they picked.",
                        style: TextStyle(fontSize: 13, color: kMu)),
                    const SizedBox(height: 20),
                    const _MyRankCard(),
                    const SizedBox(height: 20),
                    const _LeaderboardList(),
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

class _MyRankCard extends StatelessWidget {
  const _MyRankCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final myRank = provider.myRank;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDeep,
        borderRadius: kBR2xl,
      ),
      child: myRank == null
          ? const SizedBox(
              height: 24,
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
          : myRank.optedIn
              ? Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: kMint, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        myRank.rank != null
                            ? "You're #${myRank.rank} of ${myRank.outOf} on the leaderboard."
                            : "You're on the leaderboard with ${myRank.totalPoints} points.",
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<ProfileProvider>().setLeaderboardOptIn(false),
                      child: Text('Hide me', style: TextStyle(color: kMint)),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, color: kMint, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "You're not on the leaderboard yet; join in with your profile name and points.",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.read<ProfileProvider>().setLeaderboardOptIn(true),
                      style: ElevatedButton.styleFrom(backgroundColor: kMint, foregroundColor: kDeep),
                      child: const Text('Join'),
                    ),
                  ],
                ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    if (provider.leaderboardLoading && provider.leaderboard.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: kLight, borderRadius: kBRXl),
      );
    }

    if (provider.leaderboard.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBR2xl,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text('No one has joined the leaderboard yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
            const SizedBox(height: 4),
            Text('Be the first, opt in above.',
                style: TextStyle(fontSize: 12, color: kMu)),
          ],
        ),
      );
    }

    final myRank = provider.myRank;
    return Column(
      children: provider.leaderboard
          .map((entry) => _LeaderboardRow(
                entry: entry,
                isMe: myRank != null && myRank.optedIn && myRank.rank == entry.rank,
              ))
          .toList(),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  const _LeaderboardRow({required this.entry, required this.isMe});

  Color _medalColor() => switch (entry.rank) {
        1 => const Color(0xFFFAC775),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => kMu,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? kAccentL : kWhite,
        borderRadius: kBRLg,
        border: Border.all(color: isMe ? kGreen : kBorder, width: isMe ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${entry.rank}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _medalColor())),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: kMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.eco_outlined, size: 16, color: kDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(entry.displayName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Text('(you)', style: TextStyle(fontSize: 12, color: kMu)),
                ],
              ],
            ),
          ),
          Text('${entry.totalPoints} pts',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTx)),
        ],
      ),
    );
  }
}
