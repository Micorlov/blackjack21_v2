import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../models/playing_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/card_animations.dart';
import '../../widgets/playing_card_widget.dart';
import 'dealt_card.dart';
import 'table_calc.dart';

/// Centered dealer cluster at the top of the felt: "D" badge + total, the
/// sweep-pot pill (with a mid-round "YOU LEAD" badge and, once settled, a
/// "TABLE SWEEP" banner), then the dealer's two cards — the second stays a
/// [PlayingCardBack] until `state.holeRevealed`.
class DealerArea extends StatefulWidget {
  final GameState state;
  final MidRoundPot midPot;
  final CardBackDef cardBack;

  /// Horizontal inset of the felt's content band. Non-zero on wide canvases,
  /// where the cluster is centred in the band rather than in the whole box.
  final double inset;

  const DealerArea({super.key, required this.state, required this.midPot, required this.cardBack, this.inset = 0});

  @override
  State<DealerArea> createState() => _DealerAreaState();
}

class _DealerAreaState extends State<DealerArea> {
  Timer? _sweepRevealTimer;

  /// Whether the "TABLE SWEEP" banner may render yet.
  ///
  /// A natural blackjack reveals the hole card and settles the round —
  /// `sweepAmount` included — in the same beat, but [FlipRevealCard] still
  /// takes half a second to visually turn the card over. Without this gate
  /// the banner used to pop in fully formed while the card was still
  /// edge-on, announcing a result the felt hadn't shown yet. True on first
  /// build: a widget that mounts already past the reveal (hot reload, or
  /// returning to a settled table) has no fresh flip to wait for.
  bool _sweepBannerReady = true;

  @override
  void didUpdateWidget(covariant DealerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justRevealed = !oldWidget.state.holeRevealed && widget.state.holeRevealed;
    if (!justRevealed) return;
    _sweepRevealTimer?.cancel();
    final pause = AppMotion.durationOf(context, AppMotion.spatial + AppMotion.fast);
    if (pause == Duration.zero) return; // Reduced motion: the flip is instant too.
    // A plain field write, not setState: this build hasn't happened yet for
    // this update, so it picks up the new value directly.
    _sweepBannerReady = false;
    _sweepRevealTimer = Timer(pause, () {
      if (!mounted) return;
      setState(() => _sweepBannerReady = true);
    });
  }

  @override
  void dispose() {
    _sweepRevealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final showSweepBanner = state.sweepAmount > 0 && _sweepBannerReady;
    return Positioned(
      left: widget.inset,
      right: widget.inset,
      top: 4,
      child: Column(
        children: [
          _dealerBadgeRow(),
          const SizedBox(height: 8),
          _potPill(),
          if (showSweepBanner) ...[const SizedBox(height: 8), _sweepBanner()],
          const SizedBox(height: 8),
          _dealerCardsRow(context),
        ],
      ),
    );
  }

  /// The dealer's total is the number every decision at the table is made
  /// against, so it gets a spoken form of its own: the visual shows "9 + ?"
  /// while the hole card is down, which reads as gibberish out loud.
  String get _dealerSemanticLabel {
    final state = widget.state;
    if (state.dealerHand.isEmpty) return 'Dealer has no cards yet';
    if (state.holeRevealed) {
      return 'Dealer total ${BlackjackRules.handValue(state.dealerHand)}';
    }
    final upCard = BlackjackRules.handValue([state.dealerHand.first]);
    return 'Dealer shows $upCard, hole card face down';
  }

  Widget _dealerBadgeRow() {
    return Semantics(label: _dealerSemanticLabel, excludeSemantics: true, child: _dealerBadgeBox());
  }

  Widget _dealerBadgeBox() {
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
                TableCalc.dealerTotalLabel(widget.state),
                style: AppText.mono(21, weight: FontWeight.w700, color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _potPill() {
    final midPot = widget.midPot;
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
            '+\$${formatChips(widget.state.sweepAmount)}',
            style: AppText.mono(19, weight: FontWeight.w700, color: AppColors.goldInk),
          ),
        ],
      ),
    );
  }

  Widget _dealerCardsRow(BuildContext context) {
    final state = widget.state;
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
              // [FlipRevealCard] owns its own controller and duration, so the
              // only way to honour reduced motion is to not build it: the card
              // simply *is* face up, which is the same end state the flip
              // arrives at.
              if (AppMotion.reduceMotion(context))
                state.holeRevealed
                    ? PlayingCardFace(card: state.dealerHand[i], width: 58, height: 84)
                    : PlayingCardBack(width: 58, height: 84, skin: widget.cardBack)
              else
                FlipRevealCard(
                  key: const ValueKey('dealer-hole'),
                  revealed: state.holeRevealed,
                  back: PlayingCardBack(width: 58, height: 84, skin: widget.cardBack),
                  face: PlayingCardFace(card: state.dealerHand[i], width: 58, height: 84),
                )
            else
              DealtCard(
                key: ValueKey('dealer-card-$i'),
                child: PlayingCardFace(card: state.dealerHand[i], width: 58, height: 84),
              ),
          ],
        ],
      ),
    );
  }
}
