// lib/features/profile/models/leaderboard_entry.dart

/// One row of the public leaderboard — deliberately has no device_id field
/// at all, since get_leaderboard() (see supabase/leaderboard.sql) never
/// returns one; there's nothing here to accidentally leak.
class LeaderboardEntry {
  final int rank;
  final String displayName;
  final String avatarEmoji;
  final int totalPoints;
  final int level;

  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.avatarEmoji,
    required this.totalPoints,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: (json['rank'] as num).toInt(),
        displayName: json['display_name'] as String? ?? 'Plant Explorer',
        avatarEmoji: json['avatar_emoji'] as String? ?? 'spa',
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
      );
}

/// This device's own standing — from get_my_leaderboard_rank(), which only
/// ever takes the caller's own device_id as an input and never returns
/// anyone else's.
class MyLeaderboardRank {
  final bool optedIn;
  final int? rank;
  final int totalPoints;
  final int outOf;

  const MyLeaderboardRank({
    required this.optedIn,
    required this.rank,
    required this.totalPoints,
    required this.outOf,
  });

  factory MyLeaderboardRank.fromJson(Map<String, dynamic> json) => MyLeaderboardRank(
        optedIn: json['opted_in'] as bool? ?? false,
        rank: (json['rank'] as num?)?.toInt(),
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        outOf: (json['out_of'] as num?)?.toInt() ?? 0,
      );
}
