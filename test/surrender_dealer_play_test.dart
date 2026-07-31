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

/// One live NPC seat with a real bet and hand, mirroring a normal (non
/// natural-blackjack) round where the table's sweep pot is in play.
const _liveSeats = [
  NpcSeat(
    bet: 100,
    cards: [PlayingCard(rank: '4', suit: '♠'), PlayingCard(rank: '5', suit: '♣')],
    action: 'STAND',
    done: true,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('surrendering still plays the dealer out for the live NPC seats', () {
    // Dealer's opening two cards total 5 — nowhere near the 17-stand
    // threshold, so a completed hand is only possible if the dealer keeps
    // drawing after the hero surrenders.
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
        hands: const [Hand(cards: [PlayingCard(rank: '9', suit: '♠'), PlayingCard(rank: '6', suit: '♣')], bet: 100)],
        friends: kInitialFriends,
        npcSeats: _liveSeats,
      ),
    );

    notifier.playerSurrender();

    expect(notifier.state.phase, RoundPhase.settlement, reason: 'surrender should still resolve the round');
    expect(
      BlackjackRules.handValue(notifier.state.dealerHand),
      greaterThanOrEqualTo(17),
      reason: 'the dealer must finish its hand so the live NPC seat settles against a real total, '
          'not the un-played opening two cards',
    );

    // Bet was 100; surrender refunds floor(100/2)=50 immediately, so the true
    // net loss for this hand is 50 — before the fix, _settle() never
    // subtracted it from sessionNetDelta and the panel showed +$0 instead.
    expect(notifier.state.chips, 950, reason: 'starting 900 (post-deal) + the 50 surrender refund');
    expect(notifier.state.roundHandNet, -50, reason: 'the settlement panel must show the real -\$50 loss, not \$0');
  });
}
