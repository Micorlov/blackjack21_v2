/// Pure timing logic for the table Rebuy — mirrors `daily_bonus.dart`'s
/// cooldown/countdown shape exactly, so both read the same way in the UI.
library;

/// How long after a rebuy the next one unlocks. Replaces the previous free,
/// unlimited "Reset bankroll to 1,000": without this cooldown there is no
/// real loss in the game, which removes the reason to claim the daily bonus
/// or invite anyone to race you.
const Duration kRebuyCooldown = Duration(hours: 4);

/// Chips a rebuy tops the bankroll up to (never down — see `GameNotifier.rebuy`).
const int kRebuyChips = 1000;

/// True when a rebuy can be taken: never taken before, or the cooldown since
/// [lastRebuyAt] has fully elapsed at [now].
bool isRebuyReady(DateTime? lastRebuyAt, DateTime now) =>
    lastRebuyAt == null || now.difference(lastRebuyAt) >= kRebuyCooldown;

/// Compact countdown label until the next rebuy, e.g. `3h 59m` or `41m`;
/// empty once ready. Minutes round up so the label never reads `0m` while
/// time remains — same rounding as `dailyBonusCountdownLabel`.
String rebuyCountdownLabel(DateTime lastRebuyAt, DateTime now) {
  final left = lastRebuyAt.add(kRebuyCooldown).difference(now);
  if (left <= Duration.zero) return '';
  final minutes = (left.inSeconds / 60).ceil();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}
