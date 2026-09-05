import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/playing_card.dart';
import '../../models/social_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/playing_card_widget.dart';
import 'dealt_card.dart';

/// Line height for the plate's monospaced figures.
///
/// Space Mono's natural line box is 1.48x its size, so two mono lines would
/// stand taller than the hand beside them and taller than the slot the felt
/// reserves. Tightening the box to 1.15 keeps the plate at hand height
/// without giving up a point of type size.
const double _kMonoHeight = 1.15;

/// One card in a seat's hand.
///
/// The hand used to be a fan of 27x38 cards sitting *above* the plate, which
/// cost the felt a 38-unit band per seat row and — once the felt scaled itself
/// down to fit the round — drew a rank at about 7px. These are half again as
/// large and sit *beside* the name instead, in the room the avatar used to
/// take, so showing the hand costs the felt almost nothing.
const double _kCardW = 42;
const double _kCardH = 60;

/// Distance between two cards in the hand.
///
/// Cards overlap left to right, so this is how much of each card stays
/// visible — and it has to clear the rank corner, or the card underneath is
/// read wrong rather than merely read small: at a 16 step a queen showed as
/// "C" and a ten as "1". A rank sits 5px in and the widest ("10") runs 22px,
/// so 27 is the narrowest honest overlap.
///
/// A hand too wide for [_kCardsMaxWidth] is scaled down whole rather than
/// squeezed tighter, which keeps that rank-to-step ratio — and so every rank
/// — intact however long the hand runs.
const double _kCardStep = 27;

/// Widest the hand may draw before the fan closes further. Whatever is left of
/// the plate belongs to the name, the stack and the total.
const double _kCardsMaxWidth = 90;

/// Size of the avatar shown in the same place before any card is dealt.
const double _kAvatar = 46;

/// Display-ready data for one friend seat plate around the felt, derived
/// from a [Friend] + its matching [NpcSeat].
class SeatPlateData {
  final String initial;
  final String name;
  final String stackLabel;
  final Color avatarBg;
  final bool acting;
  final String betLabel;

  /// The seat's hand, drawn beside the name once it holds anything.
  final List<PlayingCard> cards;
  final bool showCards;

  /// True once the seat holds cards, so a total is worth showing.
  final bool hasStatus;
  final bool showBet;

  /// The hand's total, as a number. Busted seats are told apart by
  /// [statusColor] and by the `BUST` badge on the line below, not by
  /// replacing the figure — the number is what the cards beside it add up to.
  final String statusLabel;
  final Color statusColor;

  /// True when the seat has declared what it did — `HIT`, `STAND`, `BUST`.
  final bool hasAction;
  final String actionLabel;
  final Color actionColor;
  final bool takesPot;
  final String potLabel;
  final bool rightSide;

  const SeatPlateData({
    required this.initial,
    required this.name,
    required this.stackLabel,
    required this.avatarBg,
    required this.acting,
    required this.betLabel,
    required this.cards,
    required this.showCards,
    required this.hasStatus,
    required this.showBet,
    required this.statusLabel,
    required this.statusColor,
    required this.hasAction,
    required this.actionLabel,
    required this.actionColor,
    required this.takesPot,
    required this.potLabel,
    required this.rightSide,
  });

  factory SeatPlateData.fromState({
    required Friend friend,
    required NpcSeat? npc,
    required bool acting,
    required bool rightSide,
    required Color avatarBg,
    required bool takesPot,
    required int sweepTotalWin,
  }) {
    final hasCards = npc != null && npc.cards.isNotEmpty;
    final npcTotal = hasCards ? BlackjackRules.handValue(npc.cards) : 0;
    return SeatPlateData(
      initial: friend.initial,
      name: friend.firstName,
      stackLabel: formatChips(friend.chips),
      avatarBg: avatarBg,
      acting: acting,
      betLabel: npc != null ? formatChips(npc.bet) : '',
      cards: npc?.cards ?? const [],
      showCards: hasCards,
      hasStatus: hasCards,
      showBet: npc != null,
      statusLabel: '$npcTotal',
      statusColor: npcTotal > 21 ? AppColors.loseSoft : (npcTotal == 21 ? AppColors.gold : AppColors.winLight),
      hasAction: npc != null && npc.action.isNotEmpty,
      actionLabel: npc?.action ?? '',
      actionColor: npc?.action == 'BUST'
          ? AppColors.loseSoft
          : (npc?.action == 'STAND' ? AppColors.winLight : AppColors.gold),
      takesPot: takesPot,
      potLabel: '+\$${formatChips(sweepTotalWin)}',
      rightSide: rightSide,
    );
  }
}

/// One friend's seat around the felt: their hand beside a name+stack plate,
/// with the running total on the name line, and a gold acting-highlight
/// border when it is their turn.
///
/// One layout in every phase — the hand simply takes the avatar's place once
/// it is dealt. The plate used to grow a card row mid-round and drop it again
/// for betting, which meant two vertical budgets on the felt and a set of
/// plates that jumped between them.
class SeatPlate extends StatelessWidget {
  final SeatPlateData data;

  const SeatPlate({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: _semanticLabel, excludeSemantics: true, child: _plateBox());
  }

  /// One sentence per seat, instead of the loose numbers and card names a
  /// screen reader would otherwise read off the plate ("Maya", "1,240", "10 of
  /// diamonds", "8 of clubs", "18").
  String get _semanticLabel {
    final busted = data.actionLabel == 'BUST';
    final parts = <String>[
      data.name,
      '${data.stackLabel} chips',
      if (data.showBet) 'bet ${data.betLabel}',
      if (data.hasStatus) busted ? 'busted on ${data.statusLabel}' : 'total ${data.statusLabel}',
      if (data.hasAction && data.actionLabel == 'STAND') 'standing',
      if (data.acting) 'playing now',
      if (data.takesPot) 'takes the pot',
    ];
    return parts.join(', ');
  }

  Widget _plateBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
      decoration: BoxDecoration(
        color: data.acting ? AppColors.gold.withValues(alpha: AppAlpha.border) : Colors.black.withValues(alpha: 0.62),
        border: Border.all(
          color: data.acting ? AppColors.gold : AppColors.gold.withValues(alpha: AppAlpha.tint),
          width: data.acting ? 2 : 1,
        ),
        // A pill's deep corner curve cuts across the square corners of the
        // hand sitting inside it; the plate keeps a card's own radius instead.
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          if (data.showCards) _cardsBlock() else _avatar(),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _plateLine(
                  label: Text(
                    data.name,
                    style: AppText.sora(16, color: AppColors.textPrimary.withValues(alpha: 0.95)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: data.hasStatus
                      ? Text(
                          data.statusLabel,
                          style: AppText.mono(
                            20,
                            weight: FontWeight.w700,
                            color: data.statusColor,
                            height: _kMonoHeight,
                          ),
                        )
                      : null,
                ),
                _plateLine(
                  // The stack is a live number that grows with the system font
                  // setting; shrinking it keeps it on one line — ellipsising a
                  // bankroll turns it into a lie.
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.stackLabel,
                      style: AppText.mono(17, weight: FontWeight.w700, color: Colors.white, height: _kMonoHeight),
                      maxLines: 1,
                    ),
                  ),
                  trailing: _secondLineBadge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The seat's hand, fanned left to right so every rank corner stays visible.
  Widget _cardsBlock() {
    final n = data.cards.length;
    final width = _kCardW + (n - 1) * _kCardStep;
    return SizedBox(
      width: math.min(width, _kCardsMaxWidth),
      height: _kCardH,
      // Two cards — the hand for most of a round — draw at full size; a
      // third, fourth or fifth card scales the whole fan down a step at a
      // time, ranks and all.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: width,
          height: _kCardH,
          child: Stack(
            children: [
              // Painted in deal order, so each card overlaps the one before
              // it. Keyed by slot so a card joining the fan eases in on its
              // own instead of restarting the whole row's animation.
              for (var i = 0; i < n; i++)
                Positioned(
                  left: i * _kCardStep,
                  child: DealtCard(
                    key: ValueKey('npc-card-$i'),
                    child: PlayingCardFace(card: data.cards[i], width: _kCardW, height: _kCardH),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: _kAvatar,
      height: _kAvatar,
      decoration: BoxDecoration(shape: BoxShape.circle, color: data.avatarBg),
      alignment: Alignment.center,
      child: Text(
        data.initial,
        style: AppText.sora(22, weight: FontWeight.w800, color: AppColors.goldInk),
      ),
    );
  }

  /// Pot won, else what the seat did with its hand, else its bet.
  Widget? _secondLineBadge() {
    final Widget? badge;
    if (data.takesPot) {
      badge = _potBadge();
    } else if (data.hasAction) {
      badge = _actionBadge();
    } else if (data.showBet) {
      badge = _betDot();
    } else {
      badge = null;
    }
    if (badge == null) return null;
    // Beside a seven-figure stack, or at 130% text, the badge is wider than
    // the room left for it; it scales rather than pushing off the plate.
    return Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: badge));
  }

  Widget _potBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        data.potLabel,
        style: AppText.mono(
          14,
          weight: FontWeight.w700,
          color: AppColors.goldInk,
          letterSpacing: 0.5,
          height: _kMonoHeight,
        ),
      ),
    );
  }

  Widget _actionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border.all(color: data.actionColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        data.actionLabel,
        style: AppText.mono(
          13,
          weight: FontWeight.w700,
          color: data.actionColor,
          letterSpacing: 0.8,
          height: _kMonoHeight,
        ),
      ),
    );
  }

  /// One line of the plate: the left-hand label and its right-hand figure share
  /// a single text baseline, so the two stacked lines read as straight rows
  /// instead of two independently centred columns.
  Widget _plateLine({required Widget label, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: label),
        if (trailing != null) ...[const SizedBox(width: 6), trailing],
      ],
    );
  }

  Widget _betDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 7.5,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
        ),
        const SizedBox(width: 3),
        Text(
          data.betLabel,
          style: AppText.mono(14, weight: FontWeight.w700, color: AppColors.gold, height: _kMonoHeight),
        ),
      ],
    );
  }
}
