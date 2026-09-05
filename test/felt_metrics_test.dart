import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/screens/table/table_layout.dart';

/// The felt's vertical budget, checked as arithmetic rather than by pumping
/// the whole app: these are the numbers that decide whether the target phone
/// sees the hand at full size or at two-thirds.
///
/// Heights are what a 384x832 phone leaves the felt after the status bar,
/// header, phase banner, action panel and a three-button navigation bar.
const double _phoneWidth = 384;
const double _feltInBetting = 388;
const double _feltInPlay = 475;
const double _feltInSettlement = 269;

const _pair = [PlayingCard(rank: 'A', suit: '♥'), PlayingCard(rank: '2', suit: '♠')];

GameState _state(RoundPhase phase, {bool heroCards = false, int sweepAmount = 0}) {
  return GameState(
    phase: phase,
    bet: 100,
    friends: kInitialFriends,
    hands: heroCards ? const [Hand(cards: _pair, bet: 100)] : const [Hand()],
    dealerHand: heroCards ? _pair : const [],
    sweepAmount: sweepAmount,
    sweepInfo: sweepAmount > 0
        ? SweepInfo(
            pot: sweepAmount,
            winnerBet: 100,
            totalWin: sweepAmount + 100,
            winner: 'Guest',
            winnerTotal: 20,
            heroTook: true,
            contributors: const [SweepContributor(name: 'Maya', amount: 100, reason: 'bust')],
          )
        : null,
  );
}

void main() {
  group('FeltMetrics on the target phone', () {
    test('draws the betting phase at full scale', () {
      final m = FeltMetrics.forState(_state(RoundPhase.betting), const Size(_phoneWidth, _feltInBetting));
      expect(m.scale, 1.0);
    });

    test('draws the hand near full scale while it is being played', () {
      final m = FeltMetrics.forState(
        _state(RoundPhase.playing, heroCards: true),
        const Size(_phoneWidth, _feltInPlay),
      );
      expect(m.scale, greaterThanOrEqualTo(0.85), reason: 'play phase scaled to ${m.scale}');
    });

    test('keeps the settled felt readable under the result card', () {
      final m = FeltMetrics.forState(
        _state(RoundPhase.settlement, heroCards: true, sweepAmount: 300),
        const Size(_phoneWidth, _feltInSettlement),
      );
      expect(m.scale, greaterThanOrEqualTo(0.65), reason: 'settlement scaled to ${m.scale}');
    });
  });

  group('FeltMetrics anatomy', () {
    test('seat slots are the same height in every phase, so plates never jump', () {
      const box = Size(_phoneWidth, 800);
      final betting = FeltMetrics.forState(_state(RoundPhase.betting), box);
      final playing = FeltMetrics.forState(_state(RoundPhase.playing, heroCards: true), box);
      final settled = FeltMetrics.forState(_state(RoundPhase.settlement, heroCards: true), box);
      expect(playing.seatHeight, betting.seatHeight);
      expect(settled.seatHeight, betting.seatHeight);
      expect(playing.seatRowPitch, betting.seatRowPitch);
    });

    test('the hero block starts exactly where the lower seat row ends', () {
      final m = FeltMetrics.forState(_state(RoundPhase.playing, heroCards: true), const Size(_phoneWidth, 800));
      expect(m.heroTop, m.seatTopOf(1) + m.seatHeight + FeltMetrics.seatBandGap);
    });

    test('never asks for less canvas than the bands need', () {
      // When height wins, the canvas is exactly the required height — every
      // band gets the room it asked for and nothing overflows.
      final m = FeltMetrics.forState(_state(RoundPhase.playing, heroCards: true), const Size(320, 279));
      expect(m.scale, lessThan(1.0));
      expect(m.canvas.height * m.scale, closeTo(279, 0.01));
      expect(m.heroTop, lessThan(m.canvas.height));
    });
  });
}
