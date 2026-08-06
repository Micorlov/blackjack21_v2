import 'package:blackjack21_v2/utils/cup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weekendCupEnd', () {
    test('a mid-week moment ends at the coming Monday midnight', () {
      // 2026-08-05 is a Wednesday.
      final now = DateTime(2026, 8, 5, 10, 30);
      expect(weekendCupEnd(now), DateTime(2026, 8, 10));
    });

    test('late Sunday still belongs to the ending Cup', () {
      final now = DateTime(2026, 8, 9, 23, 59);
      expect(weekendCupEnd(now), DateTime(2026, 8, 10));
    });

    test('Monday belongs to the next Cup week', () {
      final now = DateTime(2026, 8, 10, 0, 0);
      expect(weekendCupEnd(now), DateTime(2026, 8, 17));
    });
  });

  group('cupCountdown', () {
    test('splits the remaining time into days, hours and minutes', () {
      // Wednesday 10:00 → Monday 00:00 is 4d 14h 0m.
      final now = DateTime(2026, 8, 5, 10, 0);
      final c = cupCountdown(now);
      expect((c.days, c.hours, c.minutes), (4, 14, 0));
    });

    test('rounds partial minutes up so the label never hits zero early', () {
      final now = DateTime(2026, 8, 9, 23, 59, 30);
      final c = cupCountdown(now);
      expect((c.days, c.hours, c.minutes), (0, 0, 1));
    });
  });

  group('cupEndsLabel', () {
    test('shows days and hours while more than a day remains', () {
      expect(cupEndsLabel(DateTime(2026, 8, 5, 10, 0)), 'Ends in 4d 14h');
    });

    test('drops to hours and minutes inside the final day', () {
      expect(cupEndsLabel(DateTime(2026, 8, 9, 20, 15)), 'Ends in 3h 45m');
    });

    test('shows minutes only inside the final hour', () {
      expect(cupEndsLabel(DateTime(2026, 8, 9, 23, 30)), 'Ends in 30m');
    });
  });

  group('cup prizes', () {
    test('pins the advertised pool and the prize table', () {
      expect(kCupPrizePool, 5000);
      expect(kCupPrizes, [
        ('1st place', 2000),
        ('2nd place', 1200),
        ('3rd place', 800),
        ('4th – 10th', 200),
      ]);
    });
  });
}
