import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/points.dart';

/// The friends race, shown while the other seats and the dealer play — the
/// stretch of the hand where the player has nothing to do and the standings
/// are what they actually want to look at.
///
/// Friends only: the world pages that used to sit beside this went with the
/// global leaderboard. Built only when there are real people in the group
/// (see [TableWaitingPanel]); the practice bots never appear here.
class StandingsMiniTable extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;

  static const int _kMaxRows = 5;

  const StandingsMiniTable({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final rows = friendsStandingsRows(state);
    var visible = [for (var i = 0; i < rows.length; i++) (rank: i + 1, row: rows[i])];
    final selfIdx = visible.indexWhere((e) => e.row.isSelf);
    // Capped, always keeping the hero's row visible: it replaces the last
    // visible row when it falls below the cut.
    if (visible.length > _kMaxRows) {
      visible = selfIdx >= _kMaxRows
          ? [...visible.take(_kMaxRows - 1), visible[selfIdx]]
          : visible.take(_kMaxRows).toList();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white.withValues(alpha: AppAlpha.hairline)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Friends this hour',
            style: AppText.sora(12, weight: FontWeight.w600, color: AppColors.textFaint),
          ),
          const SizedBox(height: 4),
          for (final e in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#${e.rank}',
                      style: AppText.mono(13, weight: FontWeight.w700, color: AppColors.textFaint),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sora(
                        12,
                        weight: e.row.isSelf ? FontWeight.w800 : FontWeight.w600,
                        color: e.row.isSelf ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${e.row.points >= 0 ? '+' : '-'}\$${formatChips(e.row.points.abs())}',
                    style: AppText.mono(
                      12,
                      weight: FontWeight.w700,
                      color: e.row.points >= 0 ? AppColors.winLight : AppColors.loseSoft,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One row of the friends standings.
class StandingsRow {
  final String id;
  final String name;
  final int points;
  final bool isSelf;

  const StandingsRow({required this.id, required this.name, required this.points, required this.isSelf});
}

/// The hero and every real friend, ranked by hourly points, highest first.
List<StandingsRow> friendsStandingsRows(GameState s) {
  final now = DateTime.now();
  final heroPts = rolledPoints(s.heroHourlyPoints, s.heroHourKey, hourKeyOf(now));
  final rows = [
    StandingsRow(id: s.heroUid ?? 'hero', name: 'You', points: heroPts, isSelf: true),
    for (final f in s.friends) StandingsRow(id: f.id, name: f.firstName, points: f.hourlyScore, isSelf: false),
  ]..sort((a, b) => b.points.compareTo(a.points));
  return rows;
}
