/// Pure timing logic for the once-a-day free-chips claim.
///
/// The bonus runs on a rolling 24-hour cooldown from the moment of the last
/// claim (claim at 15:00 → next claim 15:00 tomorrow), so the reminder
/// notification lands at an hour the player actually plays. Keeping this
/// pure (no DateTime.now(), no plugin calls) makes it unit-testable, same
/// as `points.dart`.
library;

/// Chips granted by one daily claim.
const int kDailyBonusChips = 250;

/// How long after a claim the next one unlocks.
const Duration kDailyBonusCooldown = Duration(hours: 24);

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
