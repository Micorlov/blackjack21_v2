import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../models/hand.dart';
import '../../models/playing_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/count_up_text.dart';
import '../../widgets/playing_card_widget.dart';
import 'dealt_card.dart';
import 'table_calc.dart';
import 'table_layout.dart';

/// Line height for the block's monospaced figures — see the same constant in
/// the seat plate for why Space Mono needs one.
const double _kMonoHeight = 1.15;

/// Diameter of the bet circle and the hand-total circle.
const double _kCircle = 78;

/// The player's own hand(s) below center on the felt: fanned cards over one
/// row holding the bet circle, the running total and the name+stack plate.
/// Hidden entirely during settlement (the
/// bottom result card takes over the recap). Renders one block per
/// `state.hands` entry, stacked vertically — a split hand adds a second
/// block below the first, matching the source design.
class HeroHandArea extends StatelessWidget {
  final GameState state;

  /// Where the block starts, measured from the top of the felt — the design
  /// pins it directly under the lower seat row and lets it run to the bottom
  /// edge (`top:342px;bottom:0`), rather than floating it off the bottom.
  final double top;

  /// Horizontal inset of the felt's content band, so a wide canvas centres the
  /// block in the band rather than in the whole box.
  final double inset;

  const HeroHandArea({super.key, required this.state, required this.top, this.inset = 0});

  @override
  Widget build(BuildContext context) {
    final hands = state.hands;
    final split = hands.length > 1;
    return Positioned(
      left: inset,
      right: inset,
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
                handIndex: i,
                split: split,
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

  /// Which of `state.hands` this is. Only meaningful to the player once they
  /// have split, which is exactly when [split] is true.
  final int handIndex;
  final bool split;
  final bool active;

  const _HeroHandBlock({
    required this.state,
    required this.hand,
    required this.handIndex,
    required this.split,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final n = hand.cards.length;
    final betAmount = hand.bet != 0 ? hand.bet : state.bet;
    // The circles used to sit on a row of their own above the plate, which
    // cost the felt a 70-unit band every hand. Side by side with the plate
    // they read as one line — what you bet, what you hold, what you have.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (n > 0) ...[_cardsFan(n), const SizedBox(height: 4)],
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _betCircle(betAmount),
            if (n > 0) ...[const SizedBox(width: 8), _handTotalCircle()],
            const SizedBox(width: 8),
            _plate(betAmount),
          ],
        ),
      ],
    );
  }

  Widget _cardsFan(int n) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var ci = 0; ci < n; ci++)
            Transform.translate(
              offset: Offset(ci == 0 ? 0 : -24.0, 0),
              child: Transform.rotate(
                angle: (ci - (n - 1) / 2) * 4 * (math.pi / 180),
                // Keyed by hand *and* slot so a card joining the fan animates
                // alone: without the key every card in the row would restart
                // its deal-in on each hit.
                child: DealtCard(
                  key: ValueKey('hero-$handIndex-$ci'),
                  child: PlayingCardFace(
                    card: hand.cards[ci],
                    width: FeltMetrics.cardWidth,
                    height: FeltMetrics.cardHeight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _betCircle(int betAmount) {
    final hasBet = betAmount > 0;
    return Semantics(
      label: hasBet ? 'Your bet ${formatChips(betAmount)} chips' : 'No bet placed',
      excludeSemantics: true,
      child: _betCircleBox(betAmount, hasBet),
    );
  }

  Widget _betCircleBox(int betAmount, bool hasBet) {
    return Container(
      width: _kCircle,
      height: _kCircle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 2),
        gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: AppAlpha.hairline), Colors.black.withValues(alpha: 0.28)]),
      ),
      alignment: Alignment.center,
      // The circle is a fixed disc, but the figure inside it is live text
      // that grows with the system font setting. Scaling the contents keeps a
      // seven-figure bet — or a 200% text scale — inside the chip instead of
      // bursting out of it.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: hasBet
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 22,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${formatChips(betAmount)}',
                    style: AppText.mono(18, weight: FontWeight.w700, color: AppColors.gold, height: _kMonoHeight),
                  ),
                ],
              )
            : Text(
                'BET',
                style: AppText.mono(
                  14,
                  letterSpacing: 1,
                  color: AppColors.gold.withValues(alpha: AppAlpha.half),
                  height: _kMonoHeight,
                ),
              ),
      ),
    );
  }

  /// The running card total toward 21 — the same number [TableCalc.handLabelFor]
  /// renders as "Soft 19"/"Hard 17" text in [_plate], surfaced here as its own
  /// circle so it reads at a glance. [GameNotifier] speaks this number aloud
  /// as each card lands.
  Widget _handTotalCircle() {
    return Semantics(label: _handSemanticLabel, excludeSemantics: true, child: _handTotalCircleBox());
  }

  /// Spoken form of the total circle. The visual is a bare number, which out of
  /// context could be anything on the felt — whose hand it is and how it stands
  /// have to be said aloud.
  String get _handSemanticLabel {
    final which = split ? 'Hand ${handIndex + 1}' : 'Your hand';
    final value = BlackjackRules.handValue(hand.cards);
    final status = switch (hand.status) {
      HandStatus.busted => 'busted',
      HandStatus.blackjack => 'blackjack',
      HandStatus.surrendered => 'surrendered',
      _ => TableCalc.handLabelFor(hand).toLowerCase(),
    };
    return '$which, $value, $status';
  }

  Widget _handTotalCircleBox() {
    final busted = hand.status == HandStatus.busted;
    final blackjack = hand.status == HandStatus.blackjack;
    final value = BlackjackRules.handValue(hand.cards);
    final ringColor = busted
        ? AppColors.lose.withValues(alpha: AppAlpha.strong)
        : blackjack
        ? AppColors.gold
        : AppColors.gold.withValues(alpha: 0.45);
    final numberColor = busted ? AppColors.loseLight : AppColors.gold;
    return Container(
      width: _kCircle,
      height: _kCircle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
        gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: AppAlpha.hairline), Colors.black.withValues(alpha: 0.28)]),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$value',
          style: AppText.mono(32, weight: FontWeight.w800, color: numberColor, height: _kMonoHeight),
        ),
      ),
    );
  }

  Widget _plate(int betAmount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: BoxDecoration(
        color: active ? AppColors.gold.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.64),
        border: Border.all(
          color: active ? AppColors.gold.withValues(alpha: 0.55) : Colors.white.withValues(alpha: AppAlpha.hairline),
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
            alignment: Alignment.center,
            child: Text(
              state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'G',
              style: AppText.sora(24, weight: FontWeight.w800, color: AppColors.goldInk),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TableCalc.handLabelFor(hand),
                style: AppText.sora(18, color: active ? AppColors.gold : AppColors.textPrimary.withValues(alpha: 0.9)),
              ),
              // Rolls rather than snapping: this is the number the whole game
              // is scored on, and a win used to be indistinguishable from a
              // loss — it simply became a different figure between frames.
              Semantics(
                label: 'Balance ${formatChips(state.chips)} chips',
                excludeSemantics: true,
                child: CountUpText(
                  value: state.chips,
                  haptic: true,
                  style: AppText.mono(24, weight: FontWeight.w700, color: Colors.white, height: _kMonoHeight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
