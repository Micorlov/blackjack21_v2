import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/points.dart';
import '../../widgets/buttons.dart';

/// Betting-phase bottom panel: current bet readout, the denomination chips the
/// table allows, CLEAR/DEAL row, and (when broke) a complimentary-chips button.
class TableBettingPanel extends ConsumerWidget {
  const TableBettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final stake = state.stake;
    final denoms = chipDenomsFor(stake);
    final tableMin = stake?.min ?? 0;
    final tableMax = stake?.max;
    final belowTableMin = state.bet < tableMin;
    final dealDisabled = !(state.bet > 0 && state.bet <= state.chips) || belowTableMin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FriendsMiniTable(state: state),
        const SizedBox(height: 8),
        // One compact line: the bet figure, with the table minimum folded in
        // as a hint until the bet clears it.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bet ',
                style: AppText.mono(12, letterSpacing: 1.2, color: AppColors.textPrimary.withValues(alpha: 0.82)),
              ),
              TextSpan(
                text: '\$${state.bet}',
                style: AppText.mono(20, weight: FontWeight.w700, color: AppColors.gold),
              ),
              if (belowTableMin)
                TextSpan(
                  text: '  ·  min \$${formatChips(tableMin)}',
                  style: AppText.mono(12, letterSpacing: 0.8, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // The tray scales as a unit: capped height keeps the chips compact,
        // and the FittedBox still shrinks the row further on narrow phones.
        SizedBox(
          height: 46,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < denoms.length; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  ChipButton(
                    amount: denoms[i],
                    color: AppColors.chipColors[denoms[i]]!,
                    disabled:
                        (state.bet + denoms[i]) > state.chips ||
                        (tableMax != null && (state.bet + denoms[i]) > tableMax),
                    onPressed: () => notifier.placeBet(denoms[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'CLEAR',
                borderColor: AppColors.lose.withValues(alpha: 0.6),
                backgroundColor: AppColors.lose.withValues(alpha: 0.2),
                textColor: AppColors.loseLight,
                onPressed: notifier.clearBet,
                verticalPadding: 12,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GoldButton(
                label: 'DEAL',
                onPressed: dealDisabled ? null : notifier.dealRound,
                verticalPadding: 12,
                fontSize: 17,
              ),
            ),
          ],
        ),
        if (state.chips == 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ActionPillButton(
              label: 'Get 1,000 complimentary chips',
              borderColor: AppColors.gold.withValues(alpha: 0.32),
              backgroundColor: AppColors.gold.withValues(alpha: 0.08),
              textColor: AppColors.gold,
              onPressed: notifier.resetBankroll,
              verticalPadding: 12,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

/// The friends table inside the betting panel: everyone in the race — friends
/// and You — ranked by the same hourly/daily points the rank strip shows.
class _FriendsMiniTable extends StatelessWidget {
  final GameState state;

  const _FriendsMiniTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final hourly = state.badgeHourly;
    final now = DateTime.now();
    final heroPts = hourly
        ? rolledPoints(state.heroHourlyPoints, state.heroHourKey, hourKeyOf(now))
        : rolledPoints(state.heroDailyPoints, state.heroDayKey, dayKeyOf(now));

    final rows = [
      for (final f in state.friends)
        (name: f.firstName, points: hourly ? f.hourlyScore : f.dailyScore, isSelf: false),
      (name: 'You', points: heroPts, isSelf: true),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '#${i + 1}',
                      style: AppText.mono(11, weight: FontWeight.w700, color: i == 0 ? AppColors.gold : AppColors.textFaint),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sora(
                        12,
                        weight: rows[i].isSelf ? FontWeight.w800 : FontWeight.w600,
                        color: rows[i].isSelf ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${rows[i].points >= 0 ? '+' : '-'}\$${formatChips(rows[i].points.abs())}',
                    style: AppText.mono(
                      12,
                      weight: FontWeight.w700,
                      color: rows[i].points >= 0 ? AppColors.winLight : AppColors.loseSoft,
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
