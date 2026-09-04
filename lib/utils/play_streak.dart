/// Pure consecutive-play-day streak logic — separate from the daily-*bonus*
/// streak in `daily_bonus.dart`, which tracks claims, not hands played.
/// Kept pure (no `DateTime.now()`, no plugin calls) so it is unit-testable
/// the same way `daily_bonus.dart` and `points.dart` are.
library;

import 'points.dart';

/// Extra daily-bonus chips per consecutive play day, capped at
/// [kPlayStreakBonusCapDays] days (so a long streak tops out rather than
/// growing forever).
const int kPlayStreakBonusStep = 50;
const int kPlayStreakBonusCapDays = 5;

/// Local hour the "streak ends tonight" reminder fires at, if still unplayed.
const int kStreakReminderHour = 20;

/// The day-key immediately before the one [now] falls in. Built from
/// calendar fields (not `now.subtract(Duration(days: 1))`) so it rolls over
/// months, years, and DST correctly.
String previousDayKey(DateTime now) => dayKeyOf(DateTime(now.year, now.month, now.day - 1));

/// True when at least one hand has already been credited today.
bool playedToday(String lastDayKey, DateTime now) => lastDayKey == dayKeyOf(now);

/// Advances the streak for a hand settled at [now], given the streak's
/// current [streak] count and the day-key it was last extended on
/// ([lastDayKey]). Settling a second hand the same day leaves the streak
/// unchanged; settling one exactly one day later extends it; any bigger gap
/// restarts it at 1.
({int streak, String dayKey}) advancePlayStreak({
  required int streak,
  required String lastDayKey,
  required DateTime now,
}) {
  final today = dayKeyOf(now);
  if (lastDayKey == today) return (streak: streak, dayKey: today);
  if (lastDayKey == previousDayKey(now)) return (streak: streak + 1, dayKey: today);
  return (streak: 1, dayKey: today);
}

/// The streak value to *display* right now: still [streak] while today's or
/// yesterday's play keeps it alive, otherwise it has lapsed and reads as 0
/// even though the stored value has not been reset yet (that only happens
/// the next time a hand is settled, via [advancePlayStreak]).
int livePlayStreak({required int streak, required String lastDayKey, required DateTime now}) {
  final today = dayKeyOf(now);
  if (lastDayKey == today || lastDayKey == previousDayKey(now)) return streak;
  return 0;
}

/// Extra chips a live streak of [liveStreak] days adds to the daily bonus.
int playStreakBonusChips(int liveStreak) =>
    (liveStreak < kPlayStreakBonusCapDays ? liveStreak : kPlayStreakBonusCapDays) * kPlayStreakBonusStep;

/// When to fire the "your streak ends tonight" local reminder, or null when
/// none should be scheduled: no live streak to protect, or a hand was
/// already played today, or [kStreakReminderHour] has already passed today
/// with nothing played (too late to usefully warn).
DateTime? streakReminderAt({required int liveStreak, required bool playedToday, required DateTime now}) {
  if (liveStreak == 0) return null;
  final todayAt = DateTime(now.year, now.month, now.day, kStreakReminderHour);
  if (playedToday) return todayAt.add(const Duration(days: 1));
  return now.isBefore(todayAt) ? todayAt : null;
}
