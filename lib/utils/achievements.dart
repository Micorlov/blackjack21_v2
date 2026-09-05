import '../data/game_data.dart';
import '../models/game_state.dart';

/// Which achievements have just come true.
///
/// The seven definitions in [kAchievementDefs] were recomputed from stats on
/// every build and paid nothing, so the moment of earning one — the only part
/// that matters — did not exist. This is what turns them into events: the
/// notifier asks after each hand, pays whatever comes back, and records the ids
/// so nothing is ever paid or announced twice.
///
/// Pure, and order-stable: awards arrive in definition order, so a hand that
/// completes two of them always announces them in the same order.
List<AchievementDef> newlyUnlocked(GameState state, List<String> already) {
  return [
    for (final def in kAchievementDefs)
      if (!already.contains(def.id) && def.check(state)) def,
  ];
}

/// Total chips owed for [defs].
int achievementReward(List<AchievementDef> defs) => defs.fold(0, (sum, d) => sum + d.reward);
