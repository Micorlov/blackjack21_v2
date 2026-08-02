import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/game_state.dart';
import '../../models/hand.dart';
import '../../models/playing_card.dart';
import '../../models/social_models.dart';
import '../../models/table_pot.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/table_seats.dart';

/// Pure, stateless calculations mirroring the derived fields the JS design's
/// `renderVals()` computed for the table screen (dealer total, mid-round
/// "closest to 21" sweep pot, showdown label, pot-winner display data). These
/// are UI-only helpers — not notifier methods — so they simply read
/// [GameState] and return display-ready values with no side effects.
class TableCalc {
  TableCalc._();

  static String dealerTotalLabel(GameState s) {
    if (s.dealerHand.isEmpty) return '—';
    if (s.holeRevealed) return BlackjackRules.handValue(s.dealerHand).toString();
    return '${BlackjackRules.handValue([s.dealerHand.first])} + ?';
  }

  static String handLabelFor(Hand h) {
    if (h.cards.isEmpty) return 'Waiting';
    if (h.status == HandStatus.blackjack) return 'Blackjack!';
    if (h.status == HandStatus.busted) return 'Busted';
    if (h.status == HandStatus.surrendered) return 'Surrendered';
    final soft = BlackjackRules.isSoft(h.cards) ? 'Soft' : 'Hard';
    return '$soft ${BlackjackRules.handValue(h.cards)}';
  }


  /// The "closest to 21" table-sweep indicator shown above the dealer while a
  /// round is live: every bet already forfeited by a seat that busted or lost
  /// to the revealed dealer hand.
  static MidRoundPot midRoundPot(GameState s) {
    final liveSeats = s.npcSeats.where((n) => n.cards.isNotEmpty).toList();
    final dealerShown = s.holeRevealed ? BlackjackRules.handValue(s.dealerHand) : null;

    final pot = TablePot.live(s);
    final hasSweepPot = pot.isSweep;

    var heroLiveTotal = 0;
    for (final h in s.hands) {
      if (h.status == HandStatus.surrendered) continue;
      final v = BlackjackRules.handValue(h.cards);
      if (v > 0 && v <= 21 && v > heroLiveTotal) heroLiveTotal = v;
    }

    var rivalLiveBest = 0;
    for (final n in liveSeats) {
      if (TablePot.seatLost(n, dealerShown)) continue;
      final v = BlackjackRules.handValue(n.cards);
      if (v > rivalLiveBest) rivalLiveBest = v;
    }

    final heroLeads =
        hasSweepPot &&
        heroLiveTotal > 0 &&
        heroLiveTotal >= rivalLiveBest &&
        (dealerShown == null || dealerShown > 21 || heroLiveTotal > dealerShown);

    // Once the hand is settled the pill must always resolve to an outcome —
    // leaving it on the live "TABLE POT $x" reads as a pot still up for grabs
    // that nobody was ever announced as winning.
    final atSettlement = s.phase == RoundPhase.settlement;
    final sweep = s.sweepInfo;
    final potLabelText = atSettlement
        ? _settledPotLabel(sweep)
        : (hasSweepPot ? 'SWEEP POT' : 'TABLE POT');

    final potValueLabel = atSettlement
        ? '\$${formatChips(sweep?.totalWin ?? 0)}'
        : '\$${formatChips(pot.amount)}';

    return MidRoundPot(
      hasSweepPot: hasSweepPot,
      heroLeads: heroLeads,
      potLabelText: potLabelText,
      potValueLabel: potValueLabel,
      heroLiveTotal: heroLiveTotal,
    );
  }

  /// Settlement-phase pot pill label. `null` sweep info means no seat forfeited
  /// a bet, so there was no sweep pot to win — say that rather than implying an
  /// unclaimed pot.
  static String _settledPotLabel(SweepInfo? sweep) {
    if (sweep == null) return 'NO SWEEP';
    if (sweep.heroTook) return 'YOU TAKE';
    if (sweep.winner == 'Nobody') return 'DEALER TAKES';
    return '${sweep.winner.toUpperCase()} TAKES';
  }

  static String showdownLabel(GameState s, int heroLiveTotal) {
    final dealerShown = s.holeRevealed ? BlackjackRules.handValue(s.dealerHand) : null;
    return 'YOU $heroLiveTotal  ·  DEALER ${dealerShown ?? '?'}';
  }

  /// Settlement-only: who takes the sweep pot, and the headline/sub/colors to
  /// present them with. A `null` [GameState.sweepInfo] is a real outcome too —
  /// no seat forfeited a bet, so there was no pot to sweep — and gets its own
  /// neutral row instead of a blank card.
  static PotWinnerInfo potWinnerInfo(GameState s) {
    final info = s.sweepInfo;
    if (info == null) {
      return PotWinnerInfo(
        initial: '—',
        avatarBg: const Color(0xFF3D4A45),
        color: AppColors.textPrimary,
        rowBg: Colors.white.withValues(alpha: 0.05),
        rowBorder: Colors.white.withValues(alpha: 0.14),
        headline: 'No sweep pot',
        sub: 'NO SEAT FORFEITED A BET',
      );
    }
    if (info.winner == 'Nobody') {
      return PotWinnerInfo(
        initial: 'D',
        avatarBg: const Color(0xFF5A6763),
        color: AppColors.loseLight,
        rowBg: AppColors.lose.withValues(alpha: 0.12),
        rowBorder: AppColors.lose.withValues(alpha: 0.35),
        headline: 'Dealer keeps the pot',
        sub: 'NOBODY BEAT THE DEALER',
      );
    }
    if (info.heroTook) {
      final name = s.displayName.isNotEmpty ? s.displayName : 'G';
      return PotWinnerInfo(
        initial: name[0].toUpperCase(),
        avatarBg: AppColors.gold,
        color: AppColors.gold,
        rowBg: AppColors.gold.withValues(alpha: 0.14),
        rowBorder: AppColors.gold.withValues(alpha: 0.5),
        headline: 'You win the sweep pot',
        sub: 'BET \$${formatChips(info.winnerBet)} + POT \$${formatChips(info.pot)}',
      );
    }
    final idx = tableSeats(s).indexWhere((f) => f.firstName == info.winner);
    return PotWinnerInfo(
      initial: info.winner.isNotEmpty ? info.winner[0].toUpperCase() : '?',
      avatarBg: AppColors.seatColors[(idx < 0 ? 0 : idx) % AppColors.seatColors.length],
      color: AppColors.textPrimary,
      rowBg: Colors.white.withValues(alpha: 0.05),
      rowBorder: Colors.white.withValues(alpha: 0.14),
      headline: '${info.winner} wins the sweep pot',
      sub: 'BET \$${formatChips(info.winnerBet)} + POT \$${formatChips(info.pot)}',
    );
  }
}

class MidRoundPot {
  final bool hasSweepPot;
  final bool heroLeads;
  final String potLabelText;
  final String potValueLabel;
  final int heroLiveTotal;

  const MidRoundPot({
    required this.hasSweepPot,
    required this.heroLeads,
    required this.potLabelText,
    required this.potValueLabel,
    required this.heroLiveTotal,
  });
}

class PotWinnerInfo {
  final String initial;
  final Color avatarBg;
  final Color color;
  final Color rowBg;
  final Color rowBorder;
  final String headline;
  final String sub;

  const PotWinnerInfo({
    required this.initial,
    required this.avatarBg,
    required this.color,
    required this.rowBg,
    required this.rowBorder,
    required this.headline,
    required this.sub,
  });
}
