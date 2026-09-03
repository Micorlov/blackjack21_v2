import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

/// A notifier seeded with a fixed state, same pattern as the other table
/// tests, so a round can be pumped directly without driving it through bets
/// and timers.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the dealer holds its revealed cards for a beat before drawing',
      (tester) async {
    // Dealer's opening two cards total 5, so the only reason it would still
    // be holding two cards is the reveal pause — never the 17-stand rule.
    const dealerOpening = [PlayingCard(rank: '2', suit: '♦'), PlayingCard(rank: '3', suit: '♥')];

    final notifier = _FixedGameNotifier(
      GameState(
        screen: AppScreen.table,
        displayName: 'Guest',
        chips: 900,
        stake: _stake,
        bet: 100,
        phase: RoundPhase.playing,
        dealerHand: dealerOpening,
        holeRevealed: false,
        hands: const [
          Hand(cards: [PlayingCard(rank: '9', suit: '♠'), PlayingCard(rank: '9', suit: '♣')], bet: 100),
        ],
        friends: kInitialFriends,
      ),
    );

    notifier.playerStand();

    expect(notifier.state.holeRevealed, isTrue,
        reason: 'the hole card turns over the moment the dealer takes the stage');

    // Just short of the pause: the cards are on show, and the player is still
    // hearing the call-out of their own hand. The dealer must not have acted.
    await tester.pump(GameNotifier.kDealerRevealPause - const Duration(milliseconds: 50));
    expect(
      notifier.state.dealerHand.length,
      2,
      reason: 'the dealer must not start drawing while the spoken call-out of '
          'the hand the player just finished is still playing',
    );

    // Past it: the turn goes ahead as before.
    await tester.pump(const Duration(milliseconds: 100));
    expect(notifier.state.dealerHand.length, greaterThan(2),
        reason: 'the pause delays the dealer, it does not stop it');

    // GameNotifier keeps a heartbeat and a save timer running, and
    // `testWidgets` rightly asserts that no timer outlives the tree.
    for (var i = 0; i < 40 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    notifier.dispose();
  });
}
