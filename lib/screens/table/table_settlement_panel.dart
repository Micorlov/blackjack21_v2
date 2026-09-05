import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons.dart';
import '../../widgets/count_up_text.dart';
import '../../widgets/playing_card_widget.dart';
import 'table_calc.dart';

/// Gap between the settlement card strip and the showdown label.
const double _showdownGap = 7;

/// The most of the top row the net figure may take before it scales down.
const double _netMaxShare = 0.55;

/// Settlement-phase result card: outcome message + played-out cards +
/// showdown label, a bet/net/sweep/balance stat breakdown, an optional
/// sweep-pot detail card, and the "READY FOR NEXT HAND" CTA.
class TableSettlementPanel extends ConsumerWidget {
  const TableSettlementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    final roundNetColor = state.roundNet > 0
        ? AppColors.winLight
        : (state.roundNet < 0 ? AppColors.loseLight : AppColors.push);
    final messageColor = switch (state.messageType) {
      MessageType.win => AppColors.win,
      MessageType.lose => AppColors.lose,
      MessageType.push => AppColors.push,
      MessageType.none => AppColors.textPrimary,
    };
    final midPot = TableCalc.midRoundPot(state);
    final showdownLabel = TableCalc.showdownLabel(state, midPot.heroLiveTotal);
    final settleCards = state.hands.expand((h) => h.cards).toList();
    final roundHandColor = state.roundHandNet > 0
        ? AppColors.winLight
        : (state.roundHandNet < 0 ? AppColors.loseLight : AppColors.push);
    final roundHandLabel = '${state.roundHandNet >= 0 ? '+' : '−'}\$${formatChips(state.roundHandNet.abs())}';
    final roundHasSweep = state.sweepAmount > 0;
    final potWinner = TableCalc.potWinnerInfo(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: AppAlpha.heavy),
        border: Border.all(color: roundNetColor, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The net figure is the widest single thing on the card, and at 40px
          // type under a 130% font setting it can outgrow a 320-wide screen's
          // share of the row. It keeps its natural size up to [_netMaxShare]
          // of the row and shrinks past that, rather than pushing the message
          // off the card — the message and the figure are the two things this
          // card exists to say.
          LayoutBuilder(
            builder: (context, rowConstraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(state.message, style: AppText.serifItalic(28, color: messageColor, height: 1.15)),
                ),
                const SizedBox(width: 12),
                // The figure the player actually came for. It counts, with a
                // haptic tick as the digits move, instead of simply appearing.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (rowConstraints.maxWidth * _netMaxShare).clamp(0.0, double.infinity),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topRight,
                    child: CountUpText(
                      value: state.roundNet,
                      prefix: '\$',
                      signed: true,
                      haptic: true,
                      style: AppText.mono(40, weight: FontWeight.w700, color: roundNetColor, height: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // The showdown line used to share the message's column, beside the
          // net figure, and on a phone it read "YOU 14 · DEALE…" — the
          // comparison the card exists to make, with the dealer's half cut
          // off. It has the full width of the card now. It is still laid out
          // first at its natural width, with the card strip shrinking into
          // whatever is left, because a fixed flex split clipped it too.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < settleCards.length; i++)
                          Transform.translate(
                            offset: Offset(i == 0 ? 0 : -2.0, 0),
                            child: PlayingCardFace(card: settleCards[i], width: 24, height: 33),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: _showdownGap),
                // Unflexed children are measured against unbounded width, so
                // this cap is what lets the label fall back to an ellipsis
                // instead of overflowing the panel when even the full row
                // cannot hold it.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (constraints.maxWidth - _showdownGap).clamp(0.0, double.infinity),
                  ),
                  child: Text(
                    showdownLabel,
                    style: AppText.mono(
                      14,
                      letterSpacing: 0.06,
                      color: AppColors.textPrimary.withValues(alpha: AppAlpha.strong),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: AppAlpha.hairline)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _statRow('You bet', '\$${formatChips(state.roundStake)}', AppColors.textPrimary),
                _statRow('Hand vs dealer', roundHandLabel, roundHandColor),
                if (roundHasSweep)
                  _statRow(
                    'Sweep pot',
                    '+\$${formatChips(state.sweepAmount)}',
                    AppColors.gold,
                    labelColor: AppColors.gold,
                  ),
                Container(
                  padding: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: _statRow('Balance', formatChips(state.chips), AppColors.textPrimary),
                ),
              ],
            ),
          ),
          // Always resolved, never hidden: the felt advertises a pot every
          // hand, so every hand has to end by naming who took it (or saying
          // there was nothing to take).
          const SizedBox(height: 8),
          _potDetailCard(state, potWinner),
          const SizedBox(height: 8),
          GoldButton(label: 'READY FOR NEXT HAND', onPressed: notifier.nextHand),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor, {Color? labelColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppText.mono(16, color: labelColor ?? AppColors.textPrimary.withValues(alpha: 0.66)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // The amount is the point of the row — never let it be the part
          // that gets clipped.
          Text(
            value,
            style: AppText.mono(18, weight: FontWeight.w700, color: valueColor),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _potDetailCard(GameState state, PotWinnerInfo potWinner) {
    final sweep = state.sweepInfo;
    final contributors = sweep?.contributors ?? const [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: sweep != null ? AppColors.gold.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: sweep != null
              ? AppColors.gold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: AppAlpha.hairline),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: potWinner.rowBg,
              border: Border.all(color: potWinner.rowBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: potWinner.avatarBg),
                  alignment: Alignment.center,
                  child: Text(
                    potWinner.initial,
                    style: AppText.sora(18, weight: FontWeight.w800, color: AppColors.goldInk),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Two lines, because a winner's chosen display name can
                      // be any length: at one line "You win the sweep pot"
                      // truncated to "You win the sweep p…" on a stock phone.
                      Text(
                        potWinner.headline,
                        style: AppText.sora(17, weight: FontWeight.w800, color: potWinner.color),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        potWinner.sub,
                        style: AppText.mono(
                          13,
                          letterSpacing: 0.06,
                          color: AppColors.textPrimary.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  sweep != null ? '\$${formatChips(sweep.totalWin)}' : '—',
                  style: AppText.mono(22, weight: FontWeight.w700, color: potWinner.color),
                ),
              ],
            ),
          ),
          if (contributors.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final c in contributors)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: AppAlpha.half),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${c.name} ${c.reason} ',
                            style: AppText.mono(14, color: AppColors.textPrimary.withValues(alpha: AppAlpha.strong)),
                          ),
                          TextSpan(
                            text: '−\$${formatChips(c.amount)}',
                            style: AppText.mono(14, weight: FontWeight.w700, color: AppColors.loseLight),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
