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

  /// Advances the fake clock until the dealer's paced turn has resolved.
  ///
  /// The dealer used to draw its whole hand in one synchronous loop, so this
  /// test could assert on settlement the instant it called `playerSurrender`.
  /// It is now dealt one card at a time on a timer — the pacing fix that made
  /// `RoundPhase.dealer` survive long enough to be seen. Each `pump` fires the
  /// timer that schedules the next one, so the loop is chained rather than one
  /// long jump.
  Future<void> settleDealer(WidgetTester tester, GameNotifier notifier) async {
    for (var i = 0; i < 40 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  testWidgets('surrendering still plays the dealer out for the live NPC seats',
      (tester) async {
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

    // The dealer's turn must actually be observable now — this is the whole
    // point of pacing it. Before the fix, RoundPhase.dealer was set and left
    // again inside one frame, so the "Dealer is playing…" indicator and the
    // hole-card flip were never seen by anyone.
    expect(
      notifier.state.phase,
      RoundPhase.dealer,
      reason: 'the dealer must hold the stage rather than resolving in the '
          'same frame the player acted',
    );
    expect(notifier.state.holeRevealed, isTrue,
        reason: 'the hole card turns over before the dealer draws, as its own beat');

    await settleDealer(tester, notifier);

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
    //
    // The extra 100 is the "First Hand" achievement, which pays on the first
    // settled hand of a fresh state. Asserted explicitly rather than absorbed
    // into the figure, so a change to either number has to be deliberate.
    const firstHandAchievement = 100;
    expect(
      notifier.state.chips,
      950 + firstHandAchievement,
      reason: 'starting 900 (post-deal) + the 50 surrender refund + the first-hand achievement',
    );
    expect(notifier.state.unlockedAchievements, contains('first'));
    expect(notifier.state.roundHandNet, -50, reason: 'the settlement panel must show the real -\$50 loss, not \$0');

    // GameNotifier keeps a heartbeat, a save timer and the post-settlement
    // voice timers running. A plain `test` never noticed; `testWidgets`
    // asserts that no timer outlives the tree, and it is right to. Disposed
    // inline rather than via addTearDown because that invariant is checked
    // before teardown callbacks run.
    notifier.dispose();
  });
}
