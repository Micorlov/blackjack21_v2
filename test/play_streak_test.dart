import 'package:blackjack21_v2/utils/play_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('previousDayKey', () {
    test('the day before, within a month', () {
      expect(previousDayKey(DateTime(2026, 9, 4)), '2026-09-03');
    });

    test('rolls back across a month boundary', () {
      expect(previousDayKey(DateTime(2026, 9, 1)), '2026-08-31');
    });

    test('rolls back across a year boundary', () {
      expect(previousDayKey(DateTime(2026, 1, 1)), '2025-12-31');
    });
  });

  group('advancePlayStreak', () {
    test('starts at 1 with no prior streak', () {
      final r = advancePlayStreak(streak: 0, lastDayKey: '', now: DateTime(2026, 9, 4));
      expect(r.streak, 1);
      expect(r.dayKey, '2026-09-04');
    });

    test('a second hand the same day leaves the streak unchanged', () {
      final r = advancePlayStreak(streak: 3, lastDayKey: '2026-09-04', now: DateTime(2026, 9, 4, 22));
      expect(r.streak, 3);
      expect(r.dayKey, '2026-09-04');
    });

    test('a hand exactly one day later extends the streak', () {
      final r = advancePlayStreak(streak: 3, lastDayKey: '2026-09-03', now: DateTime(2026, 9, 4));
      expect(r.streak, 4);
    });

    test('a gap of more than one day restarts the streak at 1', () {
      final r = advancePlayStreak(streak: 5, lastDayKey: '2026-09-01', now: DateTime(2026, 9, 4));
      expect(r.streak, 1);
      expect(r.dayKey, '2026-09-04');
    });
  });

  group('livePlayStreak', () {
    test('holds while today already extended it', () {
      expect(livePlayStreak(streak: 4, lastDayKey: '2026-09-04', now: DateTime(2026, 9, 4)), 4);
    });

    test('holds through yesterday — not lapsed yet', () {
      expect(livePlayStreak(streak: 4, lastDayKey: '2026-09-03', now: DateTime(2026, 9, 4)), 4);
    });

    test('reads as 0 once older than yesterday', () {
      expect(livePlayStreak(streak: 4, lastDayKey: '2026-09-01', now: DateTime(2026, 9, 4)), 0);
    });
  });

  group('playedToday', () {
    test('true when the last day-key is today', () {
      expect(playedToday('2026-09-04', DateTime(2026, 9, 4, 23)), isTrue);
    });

    test('false otherwise', () {
      expect(playedToday('2026-09-03', DateTime(2026, 9, 4)), isFalse);
    });
  });

  group('playStreakBonusChips', () {
    test('nothing for a lapsed streak', () {
      expect(playStreakBonusChips(0), 0);
    });

    test('scales with the streak below the cap', () {
      expect(playStreakBonusChips(3), 150);
    });

    test('caps at kPlayStreakBonusCapDays', () {
      expect(playStreakBonusChips(kPlayStreakBonusCapDays), kPlayStreakBonusCapDays * kPlayStreakBonusStep);
      expect(playStreakBonusChips(kPlayStreakBonusCapDays + 4), kPlayStreakBonusCapDays * kPlayStreakBonusStep);
    });
  });

  group('streakReminderAt', () {
    test('null with no live streak to protect', () {
      final at = streakReminderAt(liveStreak: 0, playedToday: false, now: DateTime(2026, 9, 4, 10));
      expect(at, isNull);
    });

    test('tonight at the reminder hour when not yet played and still early', () {
      final at = streakReminderAt(liveStreak: 3, playedToday: false, now: DateTime(2026, 9, 4, 10));
      expect(at, DateTime(2026, 9, 4, kStreakReminderHour));
    });

    test('null once the reminder hour has already passed unplayed', () {
      final at = streakReminderAt(liveStreak: 3, playedToday: false, now: DateTime(2026, 9, 4, 21));
      expect(at, isNull);
    });

    test('tomorrow at the reminder hour once today is already covered', () {
      final at = streakReminderAt(liveStreak: 3, playedToday: true, now: DateTime(2026, 9, 4, 10));
      expect(at, DateTime(2026, 9, 5, kStreakReminderHour));
    });
  });
}
