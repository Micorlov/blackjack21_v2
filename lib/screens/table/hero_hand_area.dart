import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../models/hand.dart';
import '../../models/playing_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/playing_card_widget.dart';
import 'table_calc.dart';

/// The player's own hand(s) below center on the felt: fanned cards, a bet
/// circle, and a name+stack plate. Hidden entirely during settlement (the
/// bottom result card takes over the recap). Renders one block per
/// `state.hands` entry, stacked vertically — a split hand adds a second
/// block below the first, matching the source design.
class HeroHandArea extends StatelessWidget {
  final GameState state;

  /// Where the block starts, measured from the top of the felt — the design
  /// pins it directly under the lower seat row and lets it run to the bottom
  /// edge (`top:342px;bottom:0`), rather than floating it off the bottom.
  final double top;

  const HeroHandArea({super.key, required this.state, required this.top});

  @override
  Widget build(BuildContext context) {
    final hands = state.hands;
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      bottom: 0,
      // A split hand stacks two full blocks and would otherwise run off the
      // bottom of the felt, so the area scales down rather than overflow.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < hands.length; i++) ...[
              _HeroHandBlock(
                state: state,
                hand: hands[i],
                active: i == state.activeHandIndex && state.phase == RoundPhase.playing,
              ),
              if (i != hands.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroHandBlock extends StatelessWidget {
  final GameState state;
  final Hand hand;
  final bool active;

  const _HeroHandBlock({required this.state, required this.hand, required this.active});

  @override
  Widget build(BuildContext context) {
    final n = hand.cards.length;
    final betAmount = hand.bet != 0 ? hand.bet : state.bet;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (n > 0) ...[_cardsFan(n), const SizedBox(height: 5)],
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _betCircle(betAmount),
            if (n > 0) ...[const SizedBox(width: 10), _handTotalCircle()],
          ],
        ),
        const SizedBox(height: 5),
        _plate(betAmount),
      ],
    );
  }

  Widget _cardsFan(int n) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var ci = 0; ci < n; ci++)
            Transform.translate(
              offset: Offset(ci == 0 ? 0 : -21.0, 0),
              child: Transform.rotate(
                angle: (ci - (n - 1) / 2) * 4 * (math.pi / 180),
                child: PlayingCardFace(card: hand.cards[ci], width: 58, height: 84),
              ),
            ),
        ],
      ),
    );
  }

  Widget _betCircle(int betAmount) {
    final hasBet = betAmount > 0;
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 2),
        gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.28)]),
      ),
      alignment: Alignment.center,
      child: hasBet
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 19,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${formatChips(betAmount)}',
                  style: AppText.mono(15, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ],
            )
          : Text('BET', style: AppText.mono(11, letterSpacing: 1, color: AppColors.gold.withValues(alpha: 0.5))),
    );
  }

  /// The running card total toward 21 — the same number [TableCalc.handLabelFor]
  /// renders as "Soft 19"/"Hard 17" text in [_plate], surfaced here as its own
  /// circle so it reads at a glance. [GameNotifier] speaks this number aloud
  /// as each card lands.
  Widget _handTotalCircle() {
    final busted = hand.status == HandStatus.busted;
    final blackjack = hand.status == HandStatus.blackjack;
    final value = BlackjackRules.handValue(hand.cards);
    final ringColor = busted
        ? AppColors.lose.withValues(alpha: 0.6)
        : blackjack
            ? AppColors.gold
            : AppColors.gold.withValues(alpha: 0.45);
    final numberColor = busted ? AppColors.loseLight : AppColors.gold;
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
        gradient: RadialGradient(
          colors: [AppColors.gold.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.28)],
        ),
      ),
      alignment: Alignment.center,
      child: Text('$value', style: AppText.mono(26, weight: FontWeight.w800, color: numberColor)),
    );
  }

  Widget _plate(int betAmount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: BoxDecoration(
        color: active ? AppColors.gold.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.64),
        border: Border.all(
          color: active ? AppColors.gold.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
            alignment: Alignment.center,
            child: Text(
              state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'G',
              style: AppText.sora(21, weight: FontWeight.w800, color: AppColors.goldInk),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TableCalc.handLabelFor(hand),
                style: AppText.sora(16, color: active ? AppColors.gold : AppColors.textPrimary.withValues(alpha: 0.9)),
              ),
              Text(
                formatChips(state.chips),
                style: AppText.mono(19, weight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
