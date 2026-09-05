import 'dart:math' as math;

import '../data/game_data.dart';

/// Experience and levels.
///
/// The game had no sense of progress beyond the bankroll, and a bankroll goes
/// down as often as it goes up: a player could sit for an hour, play well, end
/// $200 light, and have nothing at all to show for the session. Experience only
/// ever accumulates, so time spent is never taken away.
///
/// Pure functions, no state — everything here is derived from the persisted
/// `xp` total.
class Xp {
  Xp._();

  /// Experience for playing a hand at all. Deliberately the largest share of a
  /// normal hand's award: showing up is the behaviour worth rewarding, and
  /// tying progress to winning would punish the variance the game is made of.
  static const int perHand = 10;

  /// Bonus for winning, for a natural blackjack, and for taking the sweep pot.
  static const int forWin = 8;
  static const int forBlackjack = 25;
  static const int forSweep = 30;

  /// Experience is also scaled by what was at stake, so a VIP hand is worth
  /// more than a Bronze one — capped, so it stays a nudge and not the whole
  /// system.
  static const int maxStakeBonus = 20;

  /// Highest level the curve defines. Past it, experience still accrues.
  static const int maxLevel = 30;

  /// Experience needed to *reach* [level].
  ///
  /// Quadratic: level 2 costs 120, level 10 about 4,900, level 30 about
  /// 50,000. Roughly a hand a level early on, and a long stretch late, which
  /// is the shape that keeps a first session rewarding without making level 30
  /// meaningless.
  static int thresholdFor(int level) {
    if (level <= 1) return 0;
    final n = level - 1;
    return 60 * n * (n + 1);
  }

  /// The level a total of [xp] has reached.
  static int levelFor(int xp) {
    if (xp <= 0) return 1;
    var level = 1;
    while (level < maxLevel && xp >= thresholdFor(level + 1)) {
      level++;
    }
    return level;
  }

  /// Progress through the current level, 0–1. Returns 1 at [maxLevel].
  static double progressWithin(int xp) {
    final level = levelFor(xp);
    if (level >= maxLevel) return 1;
    final from = thresholdFor(level);
    final to = thresholdFor(level + 1);
    if (to <= from) return 1;
    return ((xp - from) / (to - from)).clamp(0.0, 1.0);
  }

  /// Experience still owed before the next level. Zero at [maxLevel].
  static int toNextLevel(int xp) {
    final level = levelFor(xp);
    if (level >= maxLevel) return 0;
    return math.max(0, thresholdFor(level + 1) - xp);
  }

  /// What one settled hand is worth.
  ///
  /// [stake] is the table minimum, which is what separates Bronze from VIP.
  static int forRound({
    required bool won,
    required bool blackjack,
    required bool sweptPot,
    required int stake,
  }) {
    var xp = perHand;
    if (won) xp += forWin;
    if (blackjack) xp += forBlackjack;
    if (sweptPot) xp += forSweep;
    // 25 → 0, 100 → 6, 500 → 20 (capped).
    xp += math.min(maxStakeBonus, (stake / 25).floor());
    return xp;
  }
}

/// Level at which the gold avatar frame becomes available.
const int kAvatarFrameLevel = 3;

/// What reaching [level] opened up, in words a sheet or a toast can print.
///
/// Cosmetics used to be free from the first hand, which left the shop with a
/// wall of things nobody had any reason to want. Gating a few behind levels is
/// what gives playing on a destination.
List<String> unlocksAtLevel(int level) {
  return [
    for (final felt in kFeltDefs)
      if (felt.requiredLevel == level) '${felt.label} felt',
    for (final back in kCardBackDefs)
      if (back.requiredLevel == level) '${back.label} card back',
    if (level == kAvatarFrameLevel) 'Gold avatar frame',
  ];
}

/// "Level 7 · 320 XP to next", for screens that show standing at a glance.
String levelLabel(int xp) {
  final level = Xp.levelFor(xp);
  final toGo = Xp.toNextLevel(xp);
  if (toGo == 0) return 'Level $level';
  return 'Level $level · $toGo XP to next';
}
