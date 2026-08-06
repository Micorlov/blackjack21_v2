import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../state/game_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/points.dart';

/// The always-visible social ticker: your live position vs your friends'
/// hourly or daily points, pinned above every screen — including the table —
/// so the race is never out of sight. Tapping it flips hourly ↔ daily.
class RankStrip extends ConsumerWidget {
  const RankStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    if (state.screen == AppScreen.onboarding || state.screen == AppScreen.tips) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(gameProvider.notifier);

    final hourly = state.badgeHourly;
    final now = DateTime.now();
    final heroPts = hourly
        ? rolledPoints(state.heroHourlyPoints, state.heroHourKey, hourKeyOf(now))
        : rolledPoints(state.heroDailyPoints, state.heroDayKey, dayKeyOf(now));

    final rivals = [
      for (final f in state.friends)
        RankedPlayer(id: f.id, name: f.firstName, points: hourly ? f.hourlyScore : f.dailyScore),
    ];
    final playerCount = rivals.length + 1;
    final rank = rankOf('hero', [...rivals, RankedPlayer(id: 'hero', name: 'You', points: heroPts)]);

    // Chase target: the nearest rival strictly ahead; when leading, the
    // runner-up being held off.
    final ahead = rivals.where((p) => p.points > heroPts).toList()..sort((a, b) => a.points.compareTo(b.points));
    final below = rivals.where((p) => p.points <= heroPts).toList()..sort((a, b) => b.points.compareTo(a.points));
    final String chase;
    if (ahead.isNotEmpty) {
      chase = '▲ ${ahead.first.name} ${_fmt(ahead.first.points)}';
    } else if (below.isNotEmpty) {
      chase = '♛ ${_fmt(heroPts - below.first.points)} over ${below.first.name}';
    } else {
      chase = '♛ leading';
    }

    return GestureDetector(
      onTap: notifier.toggleBadgePeriod,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: AppColors.panel,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(999)),
              child: Text(
                '#$rank/$playerCount',
                style: AppText.sora(12, weight: FontWeight.w800, color: AppColors.goldInk),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hourly ? 'HOURLY' : 'DAILY',
              style: AppText.sora(11, weight: FontWeight.w700, color: AppColors.textFaint, letterSpacing: 1),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'You ${_fmt(heroPts)}',
                overflow: TextOverflow.ellipsis,
                style: AppText.sora(13, weight: FontWeight.w800, color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                chase,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppText.sora(12, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => (n >= 0 ? '+\$' : '-\$') + formatChips(n.abs());
}
