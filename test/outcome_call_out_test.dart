// Every way a round can end has words of its own. A hand going over 21 is news,
// not arithmetic: both sides of the table used to have it read out as a number
// — "You have twenty three", "Dealer has twenty two" — leaving the player to
// work out what had just happened. A push had nothing said about it at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/services/sound_player.dart';
import 'package:blackjack21_v2/services/spoken_amount.dart';
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

/// A round in progress with [hero] and [dealer] already dealt.
GameState _seated({
  required List<PlayingCard> hero,
  required List<PlayingCard> dealer,
}) =>
    GameState(
      screen: AppScreen.table,
      displayName: 'Guest',
      chips: 900,
      stake: _stake,
      bet: 100,
      phase: RoundPhase.playing,
      dealerHand: dealer,
      holeRevealed: false,
      hands: [Hand(cards: hero, bet: 100)],
      friends: kInitialFriends,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the hero going over 21 is called as a bust', (tester) async {
    // Hard 20: every card in the shoe but an ace takes it over, so a handful
    // of attempts is enough — what the card is stays the shoe's business.
    const hero = [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '10', suit: '♦')];
    const dealer = [PlayingCard(rank: '9', suit: '♣'), PlayingCard(rank: '7', suit: '♥')];

    var sawBust = false;
    for (var attempt = 0; attempt < 10 && !sawBust; attempt++) {
      final sound = RecordingSound();
      final notifier = _FixedGameNotifier(
        _seated(hero: hero, dealer: dealer),
        sound: sound,
      );

      notifier.playerHit();
      await tester.pump(GameNotifier.kHandTotalVoiceLead + const Duration(milliseconds: 50));

      final total = BlackjackRules.handValue(notifier.state.hands.single.cards);
      expect(sound.words, isNotEmpty, reason: 'the new card was not called at all');
      if (total > 21) {
        sawBust = true;
        expect(sound.words.first, ['player_bust'],
            reason: 'a bust was read out as the number $total');
        // A bust hands the table straight to the dealer, which opens its hole
        // card and says what it holds. The player hears their own hand first.
        await tester.pump(GameNotifier.kDealerRevealVoiceLead);
        expect(
          sound.spoken.indexOf('player_bust'),
          lessThan(sound.spoken.indexOf('dealer_has')),
          reason: "the dealer's hand was called before the player's own bust",
        );
      } else {
        expect(sound.words.first, ['you_have', ...spokenAmountWords(total)],
            reason: 'a hand still in play is called by its total');
      }

      for (var i = 0; i < 40 && notifier.state.phase != RoundPhase.settlement; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      notifier.dispose();
    }
    expect(sawBust, isTrue, reason: 'ten hits on a hard 20 and never once over');
  });

  testWidgets('the dealer going over 21 is called as a bust', (tester) async {
    // The dealer must draw on 16 and busts on anything above a five.
    const hero = [PlayingCard(rank: '9', suit: '♠'), PlayingCard(rank: '9', suit: '♣')];
    const dealer = [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '6', suit: '♦')];

    var sawBust = false;
    for (var attempt = 0; attempt < 12 && !sawBust; attempt++) {
      final sound = RecordingSound();
      final notifier = _FixedGameNotifier(
        _seated(hero: hero, dealer: dealer),
        sound: sound,
      );

      notifier.playerStand();
      for (var i = 0; i < 60 && notifier.state.phase != RoundPhase.settlement; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }

      final total = BlackjackRules.handValue(notifier.state.dealerHand);
      expect(sound.dealerLines, isNotEmpty,
          reason: 'the dealer played its hand out in silence');
      if (total > 21) {
        sawBust = true;
        expect(sound.dealerLines.last, ['dealer_bust'],
            reason: 'the dealer busting was read out as the number $total');
      } else {
        expect(sound.dealerLines.last, ['dealer_has', ...spokenAmountWords(total)],
            reason: 'a dealer that stands is called by its total');
      }
      notifier.dispose();
    }
    expect(sawBust, isTrue, reason: 'twelve hands and the dealer never went over');
  });

  testWidgets('a push is said out loud, not left to the tone', (tester) async {
    // Twenty against twenty: the dealer stands where it is, so this round is a
    // push whatever the shoe holds.
    final sound = RecordingSound();
    final notifier = _FixedGameNotifier(
      _seated(
        hero: const [PlayingCard(rank: '10', suit: '♠'), PlayingCard(rank: '10', suit: '♦')],
        dealer: const [PlayingCard(rank: '10', suit: '♣'), PlayingCard(rank: '10', suit: '♥')],
      ),
      sound: sound,
    );

    notifier.playerStand();
    for (var i = 0; i < 60 && notifier.state.phase != RoundPhase.settlement; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(notifier.state.messageType, MessageType.push,
        reason: 'twenty against twenty is a push');

    await tester.pump(GameNotifier.kVoiceLead + const Duration(milliseconds: 100));
    expect(sound.tones, contains(GameSfx.push),
        reason: 'the push tone still plays');
    expect(sound.voices, contains(GameVoice.push),
        reason: 'the bet came back and nothing was said about it');
    notifier.dispose();
  });
}
