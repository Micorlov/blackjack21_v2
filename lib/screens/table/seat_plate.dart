import 'package:flutter/material.dart';

import '../../models/playing_card.dart';
import '../../models/social_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/playing_card_widget.dart';

/// Size of a single card in a friend's fan. The row that holds the fan is
/// pinned to [_kCardHeight] so a long hand can never change the seat's height.
const double _kCardWidth = 27;
const double _kCardHeight = 38;

/// Display-ready data for one friend seat plate around the felt, derived
/// from a [Friend] + its matching [NpcSeat] (mirrors `seatPlates` in the JS
/// design's `renderVals()`).
class SeatPlateData {
  final String initial;
  final String name;
  final String stackLabel;
  final Color avatarBg;
  final bool acting;
  final List<PlayingCard> cards;
  final bool showCards;
  final String betLabel;
  final bool hasStatus;
  final bool showBet;
  final bool showBetOnly;
  final String statusLabel;
  final Color statusColor;
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
    required this.cards,
    required this.showCards,
    required this.betLabel,
    required this.hasStatus,
    required this.showBet,
    required this.showBetOnly,
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
      cards: npc?.cards ?? const [],
      showCards: hasCards,
      betLabel: npc != null ? formatChips(npc.bet) : '',
      hasStatus: hasCards,
      showBet: npc != null,
      showBetOnly: npc != null && !hasCards,
      statusLabel: npcTotal > 21 ? 'BUST' : '$npcTotal',
      statusColor: npcTotal > 21
          ? AppColors.loseSoft
          : (npcTotal == 21 ? AppColors.gold : AppColors.winLight),
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

/// One friend's seat around the felt: cards + bet/status row above a
/// name+stack plate, with a gold acting-highlight border when it's their turn.
class SeatPlate extends StatelessWidget {
  final SeatPlateData data;

  const SeatPlate({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.showCards) ...[_cardsRow(), const SizedBox(height: 4)],
        _plateRow(),
      ],
    );
  }

  Widget _cardsRow() {
    final badge = data.takesPot ? _potBadge() : (data.hasAction ? _actionBadge() : null);
    return SizedBox(
      // Pinned to exactly one card's height. A long hand (six cards plus a
      // BUST badge) overflows the seat's width and gets scaled down by the
      // FittedBox below, which would otherwise make this row shorter — and
      // since the whole seat is scaled to fit its slot, a shorter card row
      // would leave that seat's name plate *larger* than everyone else's.
      // Card count must not decide how big a name plate is drawn.
      height: _kCardHeight,
      child: Padding(
        padding: EdgeInsets.only(left: data.rightSide ? 0 : 16, right: data.rightSide ? 16 : 0),
        child: Row(
          mainAxisAlignment: data.rightSide ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (badge != null && data.rightSide) ...[badge, const SizedBox(width: 6)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: data.rightSide ? Alignment.centerRight : Alignment.centerLeft,
                child: _cardsFan(),
              ),
            ),
            if (badge != null && !data.rightSide) ...[const SizedBox(width: 6), badge],
          ],
        ),
      ),
    );
  }

  Widget _cardsFan() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < data.cards.length; i++)
          Transform.translate(
            offset: Offset(i == 0 ? 0 : -3.0, 0),
            child: PlayingCardFace(card: data.cards[i], width: _kCardWidth, height: _kCardHeight),
          ),
      ],
    );
  }

  Widget _potBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(8)),
      child: Text(
        data.potLabel,
        style: AppText.mono(12, weight: FontWeight.w700, color: AppColors.goldInk, letterSpacing: 0.5),
      ),
    );
  }

  Widget _actionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border.all(color: data.actionColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        data.actionLabel,
        style: AppText.mono(12, weight: FontWeight.w700, color: data.actionColor, letterSpacing: 1),
      ),
    );
  }

  Widget _plateRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: data.acting ? AppColors.gold.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.62),
        border: Border.all(
          color: data.acting ? AppColors.gold : AppColors.gold.withValues(alpha: 0.22),
          width: data.acting ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: data.avatarBg),
            alignment: Alignment.center,
            child: Text(
              data.initial,
              style: AppText.sora(18, weight: FontWeight.w800, color: AppColors.goldInk),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _plateLine(
                  label: Text(
                    data.name,
                    style: AppText.sora(14, color: AppColors.textPrimary.withValues(alpha: 0.95)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: data.hasStatus
                      ? Text(
                          data.statusLabel,
                          style: AppText.mono(17, weight: FontWeight.w700, color: data.statusColor),
                        )
                      : null,
                ),
                _plateLine(
                  label: Text(
                    data.stackLabel,
                    style: AppText.mono(17, weight: FontWeight.w700, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: data.hasStatus && data.showBet ? _betDot(fontSize: 12, dotSize: 8) : null,
                ),
              ],
            ),
          ),
          if (data.showBetOnly) ...[const SizedBox(width: 8), _betDot(fontSize: 15, dotSize: 12)],
        ],
      ),
    );
  }

  /// One line of the plate: the left-hand label and its right-hand number share
  /// a single text baseline, so the two stacked lines read as straight rows
  /// instead of two independently centred columns.
  Widget _plateLine({required Widget label, Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: label),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _betDot({required double fontSize, required double dotSize}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize * 0.75,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
        ),
        const SizedBox(width: 3),
        Text(
          data.betLabel,
          style: AppText.mono(fontSize, weight: FontWeight.w700, color: AppColors.gold),
        ),
      ],
    );
  }
}
