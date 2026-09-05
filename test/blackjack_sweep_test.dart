// A natural used to be the one hand that could never win the sweep pot.
//
// Dealt 21 off the top, the round settled in the same beat: the opponent seats
// were dealt cards that were thrown away, none of them played, the dealer never
// finished its hand and no bet was ever forfeited. The best hand in the game
// paid 3:2 and was locked out of the thing this table is actually played for.
// It now runs the table like any other round — the hero simply has nothing to
// decide — and the result says "Blackjack" rather than filing it under a
// generic big win.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/services/sound_player.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

import 'support/recording_sound.dart';

class _FixedGameNotifier extends GameNotifier {
  _FixedGameNotifier(GameState initial, {super.sound}) {
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

/// The hero's natural.
const _heroBlackjack = [PlayingCard(rank: 'A', suit: '♠'), PlayingCard(rank: 'K', suit: '♦')];

/// An ace up, so the round reaches the hero through the insurance decision —
/// the one entry point a test can drive without a stacked shoe. The hole card
/// is a six, so the dealer has no natural of its own and has to play the hand
/// out.
const _dealerAceUp = [PlayingCard(rank: 'A', suit: '♣'), PlayingCard(rank: '6', suit: '♦')];

/// A seat already over 21: its bet is forfeited whatever the dealer draws, so
/// the pot this round plays for is a fixed $100.
const _bustedSeat = NpcSeat(
  bet: 100,
  cards: [
    PlayingCard(rank: '10', suit: '♠'),
    PlayingCard(rank: '9', suit: '♥'),
    PlayingCard(rank: '3', suit: '♣'),
  ],
);

GameState _insuranceDecision({required List<NpcSeat> seats}) => GameState(
  screen: AppScreen.table,
  displayName: 'Guest',
  chips: 900,
  stake: _stake,
  bet: 100,
  phase: RoundPhase.insurance,
  dealerHand: _dealerAceUp,
  holeRevealed: false,
  hands: const [Hand(cards: _heroBlackjack, bet: 100)],
  insuranceBet: 50,
  friends: kInitialFriends,
  npcSeats: seats,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Runs the fake clock until the round has settled.
  Future<void> settle(WidgetTester tester, GameNotifier notifier) async {
    for (var i = 0; i < 120 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('a natural plays the table out and takes the sweep pot', (tester) async {
    final sound = RecordingSound();
    final notifier = _FixedGameNotifier(_insuranceDecision(seats: const [_bustedSeat]), sound: sound);

    notifier.declineInsurance();

    // Before the fix this was already RoundPhase.settlement: the hand was over
    // before the seat beside the hero had played a card.
    expect(
      notifier.state.phase,
      RoundPhase.npcs,
      reason: 'a natural must let the seats play, or there is no pot to win',
    );
    expect(
      notifier.state.hands.single.status,
      HandStatus.blackjack,
      reason: 'the hand is marked as the natural it is while the table plays on',
    );

    await settle(tester, notifier);

    expect(
      BlackjackRules.handValue(notifier.state.dealerHand),
      greaterThanOrEqualTo(17),
      reason: 'the dealer finishes its hand so the seats settle against a real total',
    );
    expect(notifier.state.sweepAmount, 100, reason: 'the busted seat forfeited its \$100 into the pot');
    expect(notifier.state.sweepInfo?.heroTook, isTrue, reason: '21 is the best hand at the table');
    // 900 on the felt + the 100 bet back + 150 at 3:2 + the 100 sweep pot.
    expect(notifier.state.chips, 1250);
    expect(notifier.state.roundNet, 250, reason: '150 for the natural and 100 swept');

    expect(
      notifier.state.message,
      'Blackjack — you sweep',
      reason: 'the sweep line used to overwrite the natural, so the hand went unnamed',
    );

    await tester.pump(GameNotifier.kVoiceLead + const Duration(milliseconds: 100));
    expect(sound.tones, contains(GameSfx.blackjack));
    expect(
      sound.voices,
      contains(GameVoice.playerBlackjackPot),
      reason: 'the call-out names the blackjack and the pot it took',
    );

    notifier.dispose();
  });

  testWidgets('a natural with no seat to sweep is still called by name', (tester) async {
    final sound = RecordingSound();
    final notifier = _FixedGameNotifier(_insuranceDecision(seats: const []), sound: sound);

    notifier.declineInsurance();
    await settle(tester, notifier);

    expect(notifier.state.sweepAmount, 0, reason: 'an empty table forfeits nothing');
    expect(notifier.state.message, 'Blackjack! You win');
    // 900 + the 100 bet back + 150 at 3:2.
    expect(notifier.state.chips, 1150);

    await tester.pump(GameNotifier.kVoiceLead + const Duration(milliseconds: 100));
    expect(
      sound.voices,
      contains(GameVoice.playerBlackjack),
      reason: 'the result used to be the generic "Big win", which named nothing',
    );

    notifier.dispose();
  });
}
