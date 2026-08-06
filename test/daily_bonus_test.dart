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

  group('nextDailyBonusStreakDay', () {
    test('starts at day 1 when never claimed', () {
      expect(nextDailyBonusStreakDay(0, null, claim), 1);
    });

    test('starts at day 1 when a stored day exists but no claim time', () {
      expect(nextDailyBonusStreakDay(3, null, claim), 1);
    });

    test('advances to the next day when claimed inside the window', () {
      final now = claim.add(const Duration(hours: 25));
      expect(nextDailyBonusStreakDay(2, claim, now), 3);
    });

    test('still advances at exactly the 48-hour window edge', () {
      final now = claim.add(kDailyBonusStreakWindow);
      expect(nextDailyBonusStreakDay(2, claim, now), 3);
    });

    test('resets to day 1 once the window has lapsed', () {
      final now = claim.add(kDailyBonusStreakWindow + const Duration(minutes: 1));
      expect(nextDailyBonusStreakDay(6, claim, now), 1);
    });

    test('wraps back to day 1 after completing day 7', () {
      final now = claim.add(const Duration(hours: 25));
      expect(nextDailyBonusStreakDay(7, claim, now), 1);
    });
  });

  group('dailyBonusRewardForDay', () {
    test('days 1 through 6 pay the flat bonus', () {
      for (var day = 1; day <= 6; day++) {
        expect(dailyBonusRewardForDay(day), kDailyBonusChips);
      }
    });

    test('day 7 pays the big bonus', () {
      expect(dailyBonusRewardForDay(7), kDailyBonusDay7Chips);
    });
  });
}
