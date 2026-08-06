/// Pure timing logic for the once-a-day free-chips claim.
///
/// The bonus runs on a rolling 24-hour cooldown from the moment of the last
/// claim (claim at 15:00 → next claim 15:00 tomorrow), so the reminder
/// notification lands at an hour the player actually plays. Keeping this
/// pure (no DateTime.now(), no plugin calls) makes it unit-testable, same
/// as `points.dart`.
library;

/// Chips granted by one daily claim on streak days 1–6.
const int kDailyBonusChips = 250;

/// Chips granted when the claim lands on day 7 of the streak.
const int kDailyBonusDay7Chips = 1000;

/// Length of the streak ladder shown as D1..D7 in the claim overlay.
const int kDailyBonusStreakDays = 7;

/// How long after a claim the next one unlocks.
const Duration kDailyBonusCooldown = Duration(hours: 24);

/// How long after a claim the streak survives. Claiming later than this
/// resets the ladder to day 1 — one full cooldown of slack past the moment
/// the next claim unlocked.
const Duration kDailyBonusStreakWindow = Duration(hours: 48);

/// The streak day the *next* claim would land on: day 1 for a first-ever
/// claim or a lapsed streak, otherwise the day after [lastStreakDay] —
/// wrapping back to 1 after day 7 so the ladder restarts.
int nextDailyBonusStreakDay(int lastStreakDay, DateTime? lastClaimAt, DateTime now) {
  if (lastClaimAt == null || lastStreakDay <= 0) return 1;
  if (now.difference(lastClaimAt) > kDailyBonusStreakWindow) return 1;
  return lastStreakDay >= kDailyBonusStreakDays ? 1 : lastStreakDay + 1;
}

/// Chips paid by a claim landing on streak [day].
int dailyBonusRewardForDay(int day) => day >= kDailyBonusStreakDays ? kDailyBonusDay7Chips : kDailyBonusChips;

/// True when the bonus can be claimed: never claimed before, or the cooldown
/// since [lastClaimAt] has fully elapsed at [now].
bool isDailyBonusReady(DateTime? lastClaimAt, DateTime now) =>
    lastClaimAt == null || now.difference(lastClaimAt) >= kDailyBonusCooldown;

/// The instant the next claim unlocks, or null if it is already claimable
/// (never claimed).
DateTime? nextDailyBonusAt(DateTime? lastClaimAt) =>
    lastClaimAt?.add(kDailyBonusCooldown);

/// Compact countdown label until the next claim, e.g. `23h 59m` or `41m`.
/// Minutes are rounded up so the label never reads `0m` while time remains;
/// returns an empty string once the bonus is ready.
String dailyBonusCountdownLabel(DateTime lastClaimAt, DateTime now) {
  final left = lastClaimAt.add(kDailyBonusCooldown).difference(now);
  if (left <= Duration.zero) return '';
  final minutes = (left.inSeconds / 60).ceil();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}
