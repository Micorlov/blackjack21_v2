import 'package:blackjack21_v2/utils/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ask is a one-shot on a hand the player just won well. These lock down
/// both halves: never twice, and never on a hand nobody feels good about.
void main() {
  bool ask({
    bool alreadyAsked = false,
    int handsPlayed = 25,
    bool sweptPot = false,
    bool blackjack = false,
    int winStreak = 0,
  }) => shouldPromptForReview(
    alreadyAsked: alreadyAsked,
    handsPlayed: handsPlayed,
    sweptPot: sweptPot,
    blackjack: blackjack,
    winStreak: winStreak,
  );

  group('shouldPromptForReview', () {
    test('asks after a swept pot once the player has hands behind them', () {
      expect(ask(sweptPot: true), isTrue);
    });

    test('asks on a blackjack', () {
      expect(ask(blackjack: true), isTrue);
    });

    test('asks on a third straight win', () {
      expect(ask(winStreak: kReviewWinStreak), isTrue);
    });

    test('never asks a second time', () {
      expect(ask(alreadyAsked: true, sweptPot: true, blackjack: true, winStreak: 9), isFalse);
    });

    test('stays quiet before the hand minimum, however good the hand', () {
      expect(ask(handsPlayed: kReviewMinHands - 1, sweptPot: true, blackjack: true), isFalse);
    });

    test('asks on the hand that reaches the minimum', () {
      expect(ask(handsPlayed: kReviewMinHands, sweptPot: true), isTrue);
    });

    test('stays quiet on an ordinary win, a push or a loss', () {
      expect(ask(), isFalse);
      expect(ask(winStreak: 1), isFalse);
      expect(ask(winStreak: kReviewWinStreak - 1), isFalse);
    });
  });
}
