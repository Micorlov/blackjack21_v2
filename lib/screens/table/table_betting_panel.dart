import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/rebuy.dart';
import '../../widgets/buttons.dart';
import '../../widgets/out_of_chips_sheet.dart';

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
    // With nothing staked yet, the last stake the player actually dealt is
    // one tap away instead of three: same chips, same table, straight in.
    final canGoAllIn =
        state.chips >= tableMin && state.bet < state.chips && (tableMax == null || state.bet < tableMax);
    final canRebet =
        state.bet == 0 &&
        state.lastBet > 0 &&
        state.lastBet <= state.chips &&
        state.lastBet >= tableMin &&
        (tableMax == null || state.lastBet <= tableMax);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // One compact line: the bet figure, with the table minimum folded in
        // as a hint until the bet clears it, and ALL IN parked on the end.
        //
        // ALL IN lives here rather than in the chip tray beside the
        // denominations: the tray scrolls horizontally once the chips stop
        // fitting, and on the Silver table the button was half off the screen
        // edge. This line never scrolls.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Bet ',
                      style: AppText.mono(
                        12,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary.withValues(alpha: 0.82),
                      ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Betting the stack was a tap per chip — twenty of them to reach
            // $500 from a $500 bankroll. The most dramatic move in the game
            // was the most tedious one to set up.
            if (canGoAllIn) ...[
              const SizedBox(width: AppSpacing.sm),
              ActionPillButton(
                label: 'ALL IN',
                semanticLabel: 'Bet everything',
                borderColor: AppColors.gold.withValues(alpha: 0.45),
                backgroundColor: AppColors.gold.withValues(alpha: AppAlpha.hairline),
                textColor: AppColors.gold,
                onPressed: notifier.betAllIn,
                verticalPadding: 6,
                fontSize: 12,
              ),
            ],
          ],
        ),
        // The tray is 60px of chip either side of these gaps, so it reads as
        // its own band without needing a full step of space around it.
        const SizedBox(height: AppSpacing.xs),
        _ChipTray(state: state, notifier: notifier, denoms: denoms, tableMax: tableMax),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: ActionPillButton(
                label: 'CLEAR',
                borderColor: AppColors.lose.withValues(alpha: AppAlpha.strong),
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
              child: canRebet
                  ? GoldButton(
                      label: 'DEAL \$${formatChips(state.lastBet)} AGAIN',
                      semanticLabel: 'Bet ${formatChips(state.lastBet)} again and deal',
                      onPressed: notifier.rebetAndDeal,
                      verticalPadding: 12,
                      fontSize: 17,
                    )
                  : GoldButton(
                      label: 'DEAL',
                      onPressed: dealDisabled ? null : notifier.dealRound,
                      disabledReason: belowTableMin ? 'Bet at least \$${formatChips(tableMin)} to deal' : null,
                      verticalPadding: 12,
                      fontSize: 17,
                    ),
            ),
          ],
        ),
        // Practice bots fill the empty seats. Saying so once, quietly, beats
        // the panel that used to sit here announcing "you play alone" in a
        // quarter of the screen — and the way out of it is a text link, not a
        // fourth gold button competing with DEAL.
        if (!state.friendsAreLive) ...[
          const SizedBox(height: AppSpacing.xs),
          // Wrap, not Row: side by side on a phone in portrait, stacked in the
          // 320-wide landscape rail at large text, where the pair does not fit
          // on one line.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text(
                'Playing with practice bots',
                style: AppText.mono(12, letterSpacing: 0.6, color: AppColors.textMuted),
              ),
              TextLinkButton(label: 'Invite friends', onPressed: notifier.shareInviteWhatsApp, fontSize: 14),
            ],
          ),
        ],
        // Below the table minimum the player cannot legally bet, so the rebuy
        // has to appear before the stack literally hits zero — with a bankroll
        // that now survives relaunch, a stranded $10 would otherwise be a
        // permanent dead end. Limited to once per `kRebuyCooldown`: an
        // unlimited free refill would remove the entire reason to claim the
        // daily bonus or invite anyone to race you.
        // Below the table minimum the player cannot legally bet, and the way
        // back is no longer one pill with a countdown on it: a player who
        // found the rebuy on cooldown was, as far as this panel was
        // concerned, finished, while a daily bonus, a finished mission and a
        // referral reward might all have been waiting unmentioned.
        if (state.chips < (state.stake?.min ?? kStartingChips)) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final ready = isRebuyReady(state.lastRebuyAt, DateTime.now());
              return SizedBox(
                width: double.infinity,
                child: GoldButton(
                  label: ready ? 'Rebuy 1,000 chips' : 'Ways to get chips',
                  onPressed: ready ? notifier.rebuy : () => showOutOfChipsSheet(context),
                  verticalPadding: 12,
                  fontSize: 16,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          TextLinkButton(
            label: 'See every way to get chips',
            onPressed: () => showOutOfChipsSheet(context),
            fontSize: 13,
          ),
        ],
      ],
    );
  }
}

/// The row of denomination chips the player bets with.
///
/// This used to be `SizedBox(height: 46)` wrapping a `FittedBox(scaleDown)`.
/// Because 46/60 is a smaller ratio than any width ever produced, the height
/// always won: the 60px chips rendered at **46x46 on every device**, under the
/// 48dp minimum touch target, permanently — not just on narrow phones.
///
/// The chips now keep their real size. When they do not all fit, the row
/// scrolls horizontally rather than shrinking below the minimum, because a
/// target too small to hit reliably is worse than one that needs a swipe.
class _ChipTray extends StatelessWidget {
  final GameState state;
  final GameNotifier notifier;
  final List<int> denoms;
  final int? tableMax;

  const _ChipTray({required this.state, required this.notifier, required this.denoms, required this.tableMax});

  /// [ChipButton]'s painted diameter. Asserted against the platform minimum so
  /// this stays honest if either number ever moves.
  static const double _chipSize = 60;
  static const double _gap = 9;

  @override
  Widget build(BuildContext context) {
    assert(_chipSize >= AppTouch.minTarget, 'chips must clear the minimum touch target');

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < denoms.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          ChipButton(
            amount: denoms[i],
            color: AppColors.chipColors[denoms[i]]!,
            disabled:
                (state.bet + denoms[i]) > state.chips || (tableMax != null && (state.bet + denoms[i]) > tableMax!),
            onPressed: () => notifier.placeBet(denoms[i]),
          ),
        ],
      ],
    );

    return SizedBox(
      height: _chipSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needed = denoms.length * _chipSize + (denoms.length - 1) * _gap;
          if (needed <= constraints.maxWidth) {
            return Center(child: row);
          }
          return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
        },
      ),
    );
  }
}
