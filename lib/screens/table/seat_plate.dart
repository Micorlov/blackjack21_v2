import 'package:flutter/material.dart';

import '../../models/playing_card.dart';
import '../../models/social_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

/// Line height for the plate's monospaced figures.
///
/// Space Mono's natural line box is 1.48x its size, so two mono lines at 19
/// and 20px would stand 58px tall — taller than the 46px avatar beside them
/// and taller than the slot the felt reserves. Tightening the box to 1.15
/// keeps the plate at avatar height without giving up a point of type size.
const double _kMonoHeight = 1.15;

/// Display-ready data for one friend seat plate around the felt, derived
/// from a [Friend] + its matching [NpcSeat].
///
/// A seat used to carry a fan of 27x38 playing cards above the plate. At that
/// size a rank was ~11px of type on a phone — and once the felt scaled itself
/// down mid-round, nearer 7px. The fan is gone: the hand's total, and what the
/// seat did with it, are written on the plate in type a player can read.
class SeatPlateData {
  final String initial;
  final String name;
  final String stackLabel;
  final Color avatarBg;
  final bool acting;
  final String betLabel;

  /// True once the seat holds cards, so a total (or BUST) is worth showing.
  final bool hasStatus;
  final bool showBet;
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
      hasStatus: hasCards,
      showBet: npc != null,
      statusLabel: npcTotal > 21 ? 'BUST' : '$npcTotal',
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

  /// The badge on the plate's second line, if any. The pot outranks the action
  /// (the sweep is the round's result), and `BUST` is never repeated here —
  /// it already stands where the total would be on the first line.
  bool get showsActionBadge => hasAction && actionLabel != 'BUST';
}

/// One friend's seat around the felt: a name+stack plate with the hand's
/// total, bet and action written on it, and a gold acting-highlight border
/// when it is their turn.
///
/// One layout in every phase. The plate used to grow a card row mid-round and
/// drop it again for betting, which meant two different vertical budgets on
/// the felt and a set of plates that jumped between them.
class SeatPlate extends StatelessWidget {
  final SeatPlateData data;

  const SeatPlate({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: _semanticLabel, excludeSemantics: true, child: _plateBox());
  }

  /// One sentence per seat, instead of the loose numbers a screen reader
  /// would otherwise read off the plate ("Maya", "1,240", "18").
  String get _semanticLabel {
    final parts = <String>[
      data.name,
      '${data.stackLabel} chips',
      if (data.showBet) 'bet ${data.betLabel}',
      if (data.hasStatus) data.statusLabel == 'BUST' ? 'busted' : 'total ${data.statusLabel}',
      if (data.showsActionBadge && data.actionLabel == 'STAND') 'standing',
      if (data.acting) 'playing now',
      if (data.takesPot) 'takes the pot',
    ];
    return parts.join(', ');
  }

  Widget _plateBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: data.acting ? AppColors.gold.withValues(alpha: AppAlpha.border) : Colors.black.withValues(alpha: 0.62),
        border: Border.all(
          color: data.acting ? AppColors.gold : AppColors.gold.withValues(alpha: AppAlpha.tint),
          width: data.acting ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: data.avatarBg),
            alignment: Alignment.center,
            child: Text(
              data.initial,
              style: AppText.sora(22, weight: FontWeight.w800, color: AppColors.goldInk),
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
                    style: AppText.sora(16, color: AppColors.textPrimary.withValues(alpha: 0.95)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: data.hasStatus
                      ? Text(
                          data.statusLabel,
                          style: AppText.mono(20, weight: FontWeight.w700, color: data.statusColor, height: _kMonoHeight),
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
                      style: AppText.mono(19, weight: FontWeight.w700, color: Colors.white, height: _kMonoHeight),
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

  /// Pot won, else the seat's declared action, else its bet.
  Widget? _secondLineBadge() {
    final Widget? badge;
    if (data.takesPot) {
      badge = _potBadge();
    } else if (data.showsActionBadge) {
      badge = _actionBadge();
    } else if (data.showBet) {
      badge = _betDot();
    } else {
      badge = null;
    }
    if (badge == null) return null;
    // A `+$2,500` pot badge at 130% text is wider than the room beside a
    // seven-figure stack; it scales down rather than pushing off the plate.
    return Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: badge));
  }

  Widget _potBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        data.potLabel,
        style: AppText.mono(14, weight: FontWeight.w700, color: AppColors.goldInk, letterSpacing: 0.5, height: _kMonoHeight),
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
        style: AppText.mono(14, weight: FontWeight.w700, color: data.actionColor, letterSpacing: 1, height: _kMonoHeight),
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
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
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
