import 'package:blackjack21_v2/utils/daily_bonus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final claim = DateTime(2026, 8, 1, 15, 0, 0);

  group('isDailyBonusReady', () {
    test('is ready when never claimed', () {
      expect(isDailyBonusReady(null, claim), isTrue);
    });

    test('is not ready immediately after a claim', () {
      expect(isDailyBonusReady(claim, claim.add(const Duration(seconds: 1))), isFalse);
    });

    test('is not ready one minute before the cooldown ends', () {
      final now = claim.add(kDailyBonusCooldown - const Duration(minutes: 1));
      expect(isDailyBonusReady(claim, now), isFalse);
    });

    test('is ready exactly when the cooldown ends', () {
      expect(isDailyBonusReady(claim, claim.add(kDailyBonusCooldown)), isTrue);
    });

    test('is ready long after the cooldown ends', () {
      expect(isDailyBonusReady(claim, claim.add(const Duration(days: 3))), isTrue);
    });
  });

  group('nextDailyBonusAt', () {
    test('is null when never claimed', () {
      expect(nextDailyBonusAt(null), isNull);
    });

    test('is exactly one cooldown after the claim', () {
      expect(nextDailyBonusAt(claim), claim.add(kDailyBonusCooldown));
    });
  });

  group('dailyBonusCountdownLabel', () {
    test('shows hours and minutes right after a claim', () {
      final now = claim.add(const Duration(minutes: 1));
      expect(dailyBonusCountdownLabel(claim, now), '23h 59m');
    });

    test('shows minutes only under an hour', () {
      final now = claim.add(kDailyBonusCooldown - const Duration(minutes: 41));
      expect(dailyBonusCountdownLabel(claim, now), '41m');
    });

    test('rounds partial minutes up so it never reads 0m early', () {
      final now = claim.add(kDailyBonusCooldown - const Duration(seconds: 30));
      expect(dailyBonusCountdownLabel(claim, now), '1m');
    });

    test('is empty once the bonus is ready', () {
      expect(dailyBonusCountdownLabel(claim, claim.add(kDailyBonusCooldown)), '');
    });
  });
}
