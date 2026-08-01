import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import 'formatters.dart';
import 'points.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String scoreLabel;
  final Color medalColor;
  final Color nameColor;
  final bool isSelf;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.scoreLabel,
    required this.medalColor,
    required this.nameColor,
    required this.isSelf,
  });
}

class _RankSource {
  final String name;
  final int score;
  final bool isSelf;
  const _RankSource({required this.name, required this.score, required this.isSelf});
}

/// Combines friends + the current player into one ranked list for the given
/// `state.leaderboardPeriod` (hourly / daily / all-time). Used by both the
/// Lobby "Top players" card and the Friends "Leaderboard" section so ranking
/// stays consistent across screens.
List<LeaderboardEntry> buildLeaderboard(GameState s) {
  int scoreFor({required int chips, required int dailyScore, required int hourlyScore}) {
    switch (s.leaderboardPeriod) {
      case LeaderboardPeriod.hourly:
        return hourlyScore;
      case LeaderboardPeriod.daily:
        return dailyScore;
      case LeaderboardPeriod.alltime:
        return chips;
    }
  }

  String fmtScore(int n) {
    if (s.leaderboardPeriod == LeaderboardPeriod.alltime) return '\$${formatChips(n)}';
    return (n >= 0 ? '+\$' : '-\$') + formatChips(n.abs());
  }

  final now = DateTime.now();
  final selfScore = scoreFor(
    chips: s.chips,
    dailyScore: rolledPoints(s.heroDailyPoints, s.heroDayKey, dayKeyOf(now)),
    hourlyScore: rolledPoints(s.heroHourlyPoints, s.heroHourKey, hourKeyOf(now)),
  );

  final sources = <_RankSource>[
    ...s.friends.map(
      (f) => _RankSource(
        name: f.name,
        score: scoreFor(chips: f.chips, dailyScore: f.dailyScore, hourlyScore: f.hourlyScore),
        isSelf: false,
      ),
    ),
    _RankSource(name: s.signedIn ? s.displayName : 'You', score: selfScore, isSelf: true),
  ]..sort((a, b) => b.score.compareTo(a.score));

  return List.generate(sources.length, (i) {
    final e = sources[i];
    return LeaderboardEntry(
      rank: i + 1,
      name: e.isSelf ? 'You' : e.name,
      scoreLabel: fmtScore(e.score),
      medalColor: i < 3 ? AppColors.medalColor(i + 1) : AppColors.border,
      nameColor: e.isSelf ? AppColors.gold : AppColors.textPrimary,
      isSelf: e.isSelf,
    );
  });
}
