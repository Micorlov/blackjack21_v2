import 'package:flutter/material.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/card_animations.dart';
import '../../widgets/playing_card_widget.dart';
import 'table_calc.dart';

/// Centered dealer cluster at the top of the felt: "D" badge + total, the
/// sweep-pot pill (with a mid-round "YOU LEAD" badge and, once settled, a
/// "TABLE SWEEP" banner), then the dealer's two cards — the second stays a
/// [PlayingCardBack] until `state.holeRevealed`.
class DealerArea extends StatelessWidget {
  final GameState state;
  final MidRoundPot midPot;
  final CardBackDef cardBack;

  const DealerArea({super.key, required this.state, required this.midPot, required this.cardBack});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 4,
      child: Column(
        children: [
          _dealerBadgeRow(),
          const SizedBox(height: 8),
          _potPill(),
          if (state.sweepAmount > 0) ...[const SizedBox(height: 8), _sweepBanner()],
          const SizedBox(height: 8),
          _dealerCardsRow(),
        ],
      ),
    );
  }

  Widget _dealerBadgeRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3A34), Color(0xFF151D1A)],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text('D', style: AppText.serifItalic(21, color: AppColors.gold)),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEALER',
                style: AppText.mono(12, letterSpacing: 1.6, color: AppColors.gold.withValues(alpha: 0.85)),
              ),
              Text(
                TableCalc.dealerTotalLabel(state),
                style: AppText.mono(21, weight: FontWeight.w700, color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _potPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // At settlement this label carries the winner's display name
          // ("KONSTANTINOPOULOS TAKES"), which a player picks — so it has to
          // give way rather than push the pot figure off the felt.
          Flexible(
            child: Text(
              midPot.potLabelText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(11, letterSpacing: 1.4, color: AppColors.gold.withValues(alpha: 0.7)),
            ),
          ),
          // Empty while no seat has forfeited: "NO SWEEP POT" stands alone
          // rather than trailing a figure nobody can win.
          if (midPot.potValueLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              midPot.potValueLabel,
              style: AppText.mono(16, weight: FontWeight.w700, color: AppColors.gold),
            ),
          ],
          if (midPot.heroLeads) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'YOU LEAD',
                style: AppText.mono(10, weight: FontWeight.w700, letterSpacing: 1, color: AppColors.goldInk),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sweepBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TABLE SWEEP', style: AppText.mono(11, letterSpacing: 1.4, color: AppColors.goldInk)),
          const SizedBox(width: 9),
          Text(
            '+\$${formatChips(state.sweepAmount)}',
            style: AppText.mono(19, weight: FontWeight.w700, color: AppColors.goldInk),
          ),
        ],
      ),
    );
  }

  Widget _dealerCardsRow() {
    return SizedBox(
      height: 86,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < state.dealerHand.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            // The hole card turns over in place when the dealer opens it;
            // every other card eases in as it is dealt (the design's
            // `bjDeal`). Keys keep each card's animation to itself as the
            // dealer draws.
            if (i == 1)
              FlipRevealCard(
                key: const ValueKey('dealer-hole'),
                revealed: state.holeRevealed,
                back: PlayingCardBack(width: 58, height: 84, skin: cardBack),
                face: PlayingCardFace(card: state.dealerHand[i], width: 58, height: 84),
              )
            else
              DealInCard(
                key: ValueKey('dealer-card-$i'),
                child: PlayingCardFace(card: state.dealerHand[i], width: 58, height: 84),
              ),
          ],
        ],
      ),
    );
  }
}
