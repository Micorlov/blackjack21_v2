import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/utils/xp.dart';

void main() {
  group('levels', () {
    test('a new player is level 1', () {
      expect(Xp.levelFor(0), 1);
      expect(Xp.levelFor(-50), 1, reason: 'a negative total is not a real state, but must not throw');
    });

    test('the first level costs about a handful of hands', () {
      // Roughly ten hands at the Bronze table. A first session has to reach a
      // level or the system is invisible.
      expect(Xp.thresholdFor(2), 120);
      expect(Xp.levelFor(119), 1);
      expect(Xp.levelFor(120), 2);
    });

    test('levels get further apart as they go up', () {
      final early = Xp.thresholdFor(3) - Xp.thresholdFor(2);
      final late = Xp.thresholdFor(20) - Xp.thresholdFor(19);
      expect(late, greaterThan(early * 5));
    });

    test('stops at the top of the curve', () {
      expect(Xp.levelFor(10000000), Xp.maxLevel);
      expect(Xp.progressWithin(10000000), 1);
      expect(Xp.toNextLevel(10000000), 0);
    });

    test('progress runs 0 to 1 within a level and never outside it', () {
      expect(Xp.progressWithin(Xp.thresholdFor(5)), 0);
      expect(Xp.progressWithin(Xp.thresholdFor(6) - 1), lessThan(1));
      for (final xp in [0, 1, 119, 120, 5000, 49999]) {
        expect(Xp.progressWithin(xp), inInclusiveRange(0, 1));
      }
    });
  });

  group('what a hand is worth', () {
    test('playing at all is worth more than winning', () {
      // Progress must not evaporate on a losing session; variance is the game.
      expect(Xp.perHand, greaterThan(Xp.forWin));
    });

    test('a plain loss still earns', () {
      expect(Xp.forRound(won: false, blackjack: false, sweptPot: false, stake: 25), greaterThan(0));
    });

    test('a blackjack that sweeps beats a plain win', () {
      final plain = Xp.forRound(won: true, blackjack: false, sweptPot: false, stake: 25);
      final big = Xp.forRound(won: true, blackjack: true, sweptPot: true, stake: 25);
      expect(big, greaterThan(plain * 2));
    });

    test('a bigger table pays more, but only up to a cap', () {
      final bronze = Xp.forRound(won: true, blackjack: false, sweptPot: false, stake: 25);
      final vip = Xp.forRound(won: true, blackjack: false, sweptPot: false, stake: 500);
      final absurd = Xp.forRound(won: true, blackjack: false, sweptPot: false, stake: 100000);
      expect(vip, greaterThan(bronze));
      expect(absurd - vip, lessThanOrEqualTo(Xp.maxStakeBonus));
    });
  });
}
