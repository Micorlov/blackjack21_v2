import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/models/table_pot.dart';
import 'package:blackjack21_v2/screens/table/table_calc.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

/// A notifier seeded with a fixed state so a settled table can be pumped
/// directly, without driving the round through its timers.
class _FixedGameNotifier extends GameNotifier {
  _FixedGameNotifier(GameState initial) {
    state = initial;
  }
}

const _stake = TableStake(
  key: 'bronze',
  name: 'Bronze Table',
  min: 25,
  max: 500,
  tint: Color(0xFF4FAE8E),
  tintDim: Color(0x264FAE8E),
);

/// The hand from the reported bug: the dealer stands on 17 and every seat beats
/// it, so no bet is forfeited and there is no sweep pot to award.
const _noLoserSeats = [
  NpcSeat(
    bet: 50,
    cards: [PlayingCard(rank: '4', suit: '♠'), PlayingCard(rank: '9', suit: '♣'), PlayingCard(rank: '8', suit: '♦')],
    action: 'STAND',
    done: true,
  ),
  NpcSeat(
    bet: 50,
    cards: [PlayingCard(rank: '5', suit: '♠'), PlayingCard(rank: '7', suit: '♥'), PlayingCard(rank: '6', suit: '♥')],
    action: 'STAND',
    done: true,
  ),
];

/// A seat that went over — the only thing that can forfeit a bet while the
/// dealer's hole card is still down.
const _bustedSeat = NpcSeat(
  bet: 75,
  cards: [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '9', suit: '♦'), PlayingCard(rank: '5', suit: '♣')],
  action: 'BUST',
  done: true,
);

const _dealer17 = [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '7', suit: '♦')];
const _dealerSix = [PlayingCard(rank: '6', suit: '♣'), PlayingCard(rank: '10', suit: '♦')];
const _heroTwenty = [PlayingCard(rank: 'K', suit: '♠'), PlayingCard(rank: 'Q', suit: '♠')];
const _heroSoft18 = [PlayingCard(rank: '7', suit: '♥'), PlayingCard(rank: 'A', suit: '♠')];

/// The reported hand: every opponent seat has stood, the dealer's hole card is
/// still down and action is back with the hero — so no bet has been forfeited
/// and there is nothing to sweep yet.
GameState _midRound({List<NpcSeat> seats = _noLoserSeats}) {
  return GameState(
    screen: AppScreen.table,
    displayName: 'Guest',
    chips: 1400,
    stake: _stake,
    bet: 100,
    phase: RoundPhase.playing,
    dealerHand: _dealerSix,
    holeRevealed: false,
    hands: const [Hand(cards: _heroSoft18, bet: 100, status: HandStatus.active)],
    friends: kInitialFriends,
    npcSeats: seats,
  );
}

GameState _settled({SweepInfo? sweepInfo, int sweepAmount = 0}) {
  return GameState(
    screen: AppScreen.table,
    displayName: 'Guest',
    chips: 1400,
    stake: _stake,
    bet: 500,
    phase: RoundPhase.settlement,
    dealerHand: _dealer17,
    holeRevealed: true,
    hands: const [Hand(cards: _heroTwenty, bet: 500, status: HandStatus.stood)],
    friends: kInitialFriends,
    npcSeats: _noLoserSeats,
    sweepAmount: sweepAmount,
    sweepInfo: sweepInfo,
    message: 'You win!',
    messageType: MessageType.win,
    roundNet: 500,
    roundStake: 500,
    roundHandNet: 500,
  );
}

SweepInfo _sweep({required String winner, required bool heroTook}) {
  return SweepInfo(
    pot: 175,
    winnerBet: 500,
    totalWin: 675,
    winner: winner,
    winnerTotal: 20,
    heroTook: heroTook,
    contributors: const [SweepContributor(name: 'Maya', amount: 175, reason: 'bust')],
  );
}

void main() {
  
  group('pot pill resolves at settlement', () {
    test('names the hero when the hero sweeps', () {
      final pot = TableCalc.midRoundPot(_settled(sweepInfo: _sweep(winner: 'You', heroTook: true), sweepAmount: 175));
      expect(pot.potLabelText, 'YOU TAKE');
      expect(pot.potValueLabel, '\$675');
    });

    test('names the seat that swept', () {
      final pot = TableCalc.midRoundPot(_settled(sweepInfo: _sweep(winner: 'Jordan', heroTook: false)));
      expect(pot.potLabelText, 'JORDAN TAKES');
    });

    test('names the dealer when no player beat them', () {
      final pot = TableCalc.midRoundPot(_settled(sweepInfo: _sweep(winner: 'Nobody', heroTook: false)));
      expect(pot.potLabelText, 'DEALER TAKES');
    });

    test('says NO SWEEP instead of leaving a live table pot dangling', () {
      final pot = TableCalc.midRoundPot(_settled());
      expect(pot.potLabelText, 'NO SWEEP');
      expect(pot.potValueLabel, '\$0');
    });
  });

  group('pot pill mid-round', () {
    test('says NO SWEEP POT, with no figure, while every seat is still in', () {
      final pot = TableCalc.midRoundPot(_midRound());
      expect(pot.hasSweepPot, isFalse);
      expect(pot.potLabelText, 'NO SWEEP POT');
      expect(pot.potValueLabel, '');
    });

    test('quotes the forfeited chips once a seat busts', () {
      final pot = TableCalc.midRoundPot(_midRound(seats: const [..._noLoserSeats, _bustedSeat]));
      expect(pot.hasSweepPot, isTrue);
      expect(pot.potLabelText, 'SWEEP POT');
      expect(pot.potValueLabel, '\$75');
    });
  });

  group('sweep pot call-out', () {
    test('has nothing to announce while every seat is still in', () {
      final pot = TablePot.live(_midRound());
      expect(pot.isSweep, isFalse);
      expect(pot.amount, 0);
    });

    test('announces only the bets actually forfeited', () {
      final pot = TablePot.live(_midRound(seats: const [..._noLoserSeats, _bustedSeat]));
      expect(pot.isSweep, isTrue);
      expect(pot.amount, 75);
    });
  });

  group('pot winner card', () {
    test('explains a hand with no forfeited bets', () {
      final info = TableCalc.potWinnerInfo(_settled());
      expect(info.headline, 'No sweep pot');
      expect(info.sub, 'NO SEAT FORFEITED A BET');
    });

    test('credits the seat that took the pot', () {
      final info = TableCalc.potWinnerInfo(_settled(sweepInfo: _sweep(winner: 'Jordan', heroTook: false)));
      expect(info.headline, 'Sweep pot: Jordan');
    });
  });

  testWidgets('settlement panel always states the pot outcome', (tester) async {
    const padding = FakeViewPadding(top: 47, bottom: 34);
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = const Size(393, 852)
      ..padding = padding
      ..viewPadding = padding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameProvider.overrideWith((ref) => _FixedGameNotifier(_settled()))],
        child: const BlackjackApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Before the fix this hand ended with a "TABLE POT $675" pill on the felt
    // and no mention of the pot anywhere in the result panel.
    expect(find.text('No sweep pot'), findsOneWidget);
    expect(find.text('TABLE POT'), findsNothing);
  });
}
