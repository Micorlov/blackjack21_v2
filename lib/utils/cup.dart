/// Pure timing and prize logic for the Weekend Cup screen.
///
/// The Cup runs to the end of the current week: it "ends" at the first
/// instant of Monday, local time. Keeping this free of DateTime.now() makes
/// it unit-testable, same as `points.dart` and `daily_bonus.dart`.
library;

/// Total chips in the Cup prize pool (sum of [kCupPrizes] payouts).
const int kCupPrizePool = 5000;

/// Prize table rows: label → chips.
const List<(String, int)> kCupPrizes = [
  ('1st place', 2000),
  ('2nd place', 1200),
  ('3rd place', 800),
  ('4th – 10th', 200),
];

/// The moment the current Cup ends: the first instant of next Monday, local
/// time. Any time on Monday itself belongs to the *next* Cup week, so its
/// end is the Monday after.
DateTime weekendCupEnd(DateTime now) {
  final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
  final monday = DateTime(now.year, now.month, now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday));
  return monday;
}

/// Countdown parts until the Cup ends, each floored, minutes rounded up so
/// the label never shows 0d 0h 0m while time remains.
({int days, int hours, int minutes}) cupCountdown(DateTime now) {
  final left = weekendCupEnd(now).difference(now);
  final totalMinutes = (left.inSeconds / 60).ceil();
  return (days: totalMinutes ~/ (24 * 60), hours: (totalMinutes ~/ 60) % 24, minutes: totalMinutes % 60);
}

/// Compact "Ends in 2d 14h" label for the lobby card; drops the days part
/// once the Cup is inside its final day.
String cupEndsLabel(DateTime now) {
  final c = cupCountdown(now);
  if (c.days > 0) return 'Ends in ${c.days}d ${c.hours}h';
  if (c.hours > 0) return 'Ends in ${c.hours}h ${c.minutes}m';
  return 'Ends in ${c.minutes}m';
}
