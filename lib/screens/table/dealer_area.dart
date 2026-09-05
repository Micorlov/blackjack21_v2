import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/game_data.dart';
import '../../models/game_state.dart';
import '../../models/playing_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/card_animations.dart';
import '../../widgets/playing_card_widget.dart';
import 'dealt_card.dart';
import 'table_calc.dart';
import 'table_layout.dart';

/// Line height for the cluster's monospaced type. Space Mono's natural line
/// box is 1.48x its size; at 1.15 the caption-plus-total column sits inside
/// the 46px avatar instead of standing over it.
const double _kMonoHeight = 1.15;

/// Height reserved for the pot pill whether or not it is showing, so the
/// dealer's cards stay put when a pot appears mid-hand. Matches
/// [FeltMetrics] band budget.
const double _kPotPillSlot = 30;

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

  /// Width of the content band the cards have to stay inside.
  final double contentWidth;

  const DealerArea({
    super.key,
    required this.state,
    required this.midPot,
    required this.cardBack,
    this.inset = 0,
    this.contentWidth = FeltMetrics.referenceWidth,
  });

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
      top: 0,
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
        color: Colors.black.withValues(alpha: AppAlpha.heavy),
        border: Border.all(color: AppColors.gold.withValues(alpha: AppAlpha.muted)),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
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
            child: Text('D', style: AppText.serifItalic(24, color: AppColors.gold)),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEALER',
                style: AppText.mono(
                  14,
                  letterSpacing: 1.6,
                  color: AppColors.gold.withValues(alpha: AppAlpha.scrim),
                  height: _kMonoHeight,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TableCalc.dealerTotalLabel(widget.state),
                    style: AppText.mono(24, weight: FontWeight.w700, color: AppColors.gold, height: _kMonoHeight),
                  ),
                  // A revealed 23 is the single best thing that can happen to
                  // the player, and the felt used to state it as a bare
                  // number: every seat had a BUST tag except the one whose
                  // bust pays everyone.
                  if (TableCalc.dealerBusted(widget.state)) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.lose.withValues(alpha: AppAlpha.tint),
                        border: Border.all(color: AppColors.lose.withValues(alpha: AppAlpha.strong)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BUST',
                        style: AppText.mono(
                          14,
                          weight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.loseLight,
                          height: _kMonoHeight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mid-round with nothing forfeited yet there is no pot to name, and a pill
  /// reading "NO SWEEP POT" every hand was the felt's most repeated sentence
  /// about nothing. The pill stays away until a seat forfeits a bet — but its
  /// room is kept, so the dealer's cards do not shift when it appears.
  Widget _potPill() {
    final midPot = widget.midPot;
    if (midPot.potValueLabel.isEmpty) return const SizedBox(height: _kPotPillSlot);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: AppAlpha.strong),
        border: Border.all(color: AppColors.gold.withValues(alpha: AppAlpha.tint)),
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
              style: AppText.mono(
                14,
                letterSpacing: 1.4,
                color: AppColors.gold.withValues(alpha: 0.7),
                height: _kMonoHeight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              midPot.potValueLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(18, weight: FontWeight.w700, color: AppColors.gold, height: _kMonoHeight),
            ),
          ),
          if (midPot.heroLeads) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'YOU LEAD',
                style: AppText.mono(
                  14,
                  weight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.goldInk,
                  height: _kMonoHeight,
                ),
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
      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TABLE SWEEP',
            style: AppText.mono(14, letterSpacing: 1.4, color: AppColors.goldInk, height: _kMonoHeight),
          ),
          const SizedBox(width: 9),
          Text(
            '+\$${formatChips(widget.state.sweepAmount)}',
            style: AppText.mono(24, weight: FontWeight.w700, color: AppColors.goldInk, height: _kMonoHeight),
          ),
        ],
      ),
    );
  }

  /// The dealer's cards, laid out on a step that closes into a fan once the
  /// hand outgrows the felt.
  ///
  /// This was a plain [Row] of fixed-gap cards, so a dealer who drew to five
  /// or more simply ran off the content band. Positioning by step keeps the
  /// row centred and inside the felt however long the hand gets.
  Widget _dealerCardsRow(BuildContext context) {
    final state = widget.state;
    final count = state.dealerHand.length;
    const rowHeight = FeltMetrics.cardHeight + 2;
    const w = FeltMetrics.cardWidth;
    const h = FeltMetrics.cardHeight;
    if (count == 0) return const SizedBox(height: rowHeight);

    final step = FeltMetrics.dealerCardStep(count, widget.contentWidth);
    final rowWidth = w + (count - 1) * step;

    return SizedBox(
      height: rowHeight,
      child: Center(
        child: SizedBox(
          width: rowWidth,
          child: Stack(
            children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: i * step,
                  bottom: 0,
                  // The hole card turns over in place when the dealer opens
                  // it; every other card eases in as it is dealt (the
                  // design's `bjDeal`). Keys keep each card's animation to
                  // itself as the dealer draws.
                  child: i == 1
                      // [FlipRevealCard] owns its own controller and
                      // duration, so the only way to honour reduced motion is
                      // to not build it: the card simply *is* face up, which
                      // is the same end state the flip arrives at.
                      ? (AppMotion.reduceMotion(context)
                            ? (state.holeRevealed
                                  ? PlayingCardFace(card: state.dealerHand[i], width: w, height: h)
                                  : PlayingCardBack(width: w, height: h, skin: widget.cardBack))
                            : FlipRevealCard(
                                key: const ValueKey('dealer-hole'),
                                revealed: state.holeRevealed,
                                back: PlayingCardBack(width: w, height: h, skin: widget.cardBack),
                                face: PlayingCardFace(card: state.dealerHand[i], width: w, height: h),
                              ))
                      : DealtCard(
                          key: ValueKey('dealer-card-$i'),
                          child: PlayingCardFace(card: state.dealerHand[i], width: w, height: h),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
