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

/// A notifier seeded with a fixed state, same pattern as the other table
/// tests, so a round can be pumped directly without driving it through bets
/// and timers.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the dealer holds its revealed cards for a beat before drawing',
      (tester) async {
    // Dealer's opening two cards total 5, so the only reason it would still
    // be holding two cards is the reveal pause — never the 17-stand rule.
    const dealerOpening = [PlayingCard(rank: '2', suit: '♦'), PlayingCard(rank: '3', suit: '♥')];

    final sound = RecordingSound();
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
      sound: sound,
    );

    notifier.playerStand();

    expect(notifier.state.holeRevealed, isTrue,
        reason: 'the hole card turns over the moment the dealer takes the stage');

    // The cards it turned over are read out, inside the pause: 2 + 3 is 5.
    await tester.pump(
      GameNotifier.kDealerVoiceLead + const Duration(milliseconds: 50),
    );
    expect(sound.dealerTotals, hasLength(1),
        reason: 'the dealer opened its hand without saying what it holds');
    expect(sound.dealerTotals.single, ['dealer_has', 'five']);

    // Just short of the pause: the cards are on show, the total has been said,
    // and the dealer must still not have acted.
    await tester.pump(
      GameNotifier.kDealerRevealPause -
          GameNotifier.kDealerVoiceLead -
          const Duration(milliseconds: 100),
    );
    expect(
      notifier.state.dealerHand.length,
      2,
      reason: 'the dealer must not start drawing while the spoken call-out of '
          'the hand the player just finished is still playing',
    );

    // Past it: the turn goes ahead as before.
    await tester.pump(const Duration(milliseconds: 200));
    expect(notifier.state.dealerHand.length, greaterThan(2),
        reason: 'the pause delays the dealer, it does not stop it');

    // GameNotifier keeps a heartbeat and a save timer running, and
    // `testWidgets` rightly asserts that no timer outlives the tree.
    for (var i = 0; i < 40 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    notifier.dispose();
  });

  testWidgets('the dealer waits out its own call-out before drawing',
      (tester) async {
    // Its cards come 600ms apart and the sentences describing them run for
    // over a second, so on the beats alone the dealer would be two cards ahead
    // of what the player is being told it holds. The beat is a floor; the line
    // is what the dealer actually waits for.
    const dealerOpening = [PlayingCard(rank: '2', suit: '♦'), PlayingCard(rank: '3', suit: '♥')];
    final sound = RecordingSound()
      // Longer than the reveal floor, so the voice is what decides.
      ..lineDuration = const Duration(milliseconds: 2500);
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
      sound: sound,
    );

    notifier.playerStand();

    // Past the floor, and still mid-sentence: 200ms lead + 2.5s of line +
    // 250ms of breath is 2.95s, well past the 2s the dealer would otherwise
    // have waited.
    await tester.pump(GameNotifier.kDealerRevealPause + const Duration(milliseconds: 800));
    expect(sound.dealerTotals, hasLength(1));
    expect(
      notifier.state.dealerHand.length,
      2,
      reason: 'the dealer drew while it was still saying what it held',
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(notifier.state.dealerHand.length, greaterThan(2),
        reason: 'the dealer waits for its line, it does not stop for it');

    for (var i = 0; i < 60 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    notifier.dispose();
  });

  testWidgets('a dealer blackjack is called by name, and the result after it',
      (tester) async {
    // The hole card opens on a natural and the round is over on the spot —
    // the dealer never takes a turn, so the reveal is the only chance to say
    // what it turned over. "Dealer has blackjack. Player lost."
    final sound = RecordingSound();
    final notifier = _FixedGameNotifier(
      GameState(
        screen: AppScreen.table,
        displayName: 'Guest',
        chips: 900,
        stake: _stake,
        bet: 100,
        // The dealer's ace is showing, so the round is at the insurance
        // prompt: the one path that reveals a natural on demand.
        phase: RoundPhase.insurance,
        insuranceBet: 50,
        dealerHand: const [PlayingCard(rank: 'A', suit: '♠'), PlayingCard(rank: 'K', suit: '♦')],
        holeRevealed: false,
        hands: const [
          Hand(cards: [PlayingCard(rank: '9', suit: '♠'), PlayingCard(rank: '7', suit: '♣')], bet: 100),
        ],
        friends: kInitialFriends,
      ),
      sound: sound,
    );

    notifier.declineInsurance();
    expect(notifier.state.holeRevealed, isTrue);
    expect(notifier.state.phase, RoundPhase.settlement,
        reason: 'a dealer natural ends the round where it stands');

    await tester.pump(GameNotifier.kVoiceLead + const Duration(milliseconds: 100));
    expect(sound.dealerTotals.single, ['dealer_has', 'blackjack'],
        reason: 'a natural is called by name, not as "twenty one"');
    expect(
      sound.spoken,
      ['dealer_has', GameVoice.playerLose],
      reason: 'the hand the player lost to is named first, then the loss',
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    notifier.dispose();
  });
}
