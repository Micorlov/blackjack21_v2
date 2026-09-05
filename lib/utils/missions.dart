import 'dart:math' as math;

/// A day's worth of small, checkable goals.
///
/// The daily bonus rewards opening the app; nothing rewarded *playing* once
/// you were in it. A player with no friends online and no bonus ready had no
/// reason to sit down for a third hand. Missions give the session a shape
/// without inventing scarcity: the three change at midnight, they are all
/// reachable in a normal sitting, and nothing is ever taken away for missing a
/// day.
///
/// Pure — the day's three are derived from the day key, so every device and
/// every relaunch draws the same three for the same date with nothing stored
/// but progress.
class MissionDef {
  final String id;

  /// Shown on the card, e.g. "Win 3 hands".
  final String label;

  /// How many [MissionEvent]s of the matching kind complete it.
  final int target;

  /// Chips paid on claim.
  final int reward;

  /// Which outcomes count toward it.
  final MissionKind kind;

  const MissionDef({
    required this.id,
    required this.label,
    required this.target,
    required this.reward,
    required this.kind,
  });
}

/// What a mission counts.
enum MissionKind {
  /// Any settled hand.
  handsPlayed,

  /// Hands the player won, blackjacks included.
  handsWon,

  /// Natural 21s.
  blackjacks,

  /// Hands that took the sweep pot.
  sweeps,

  /// Hands played at the Silver table or above.
  bigStakeHands,

  /// Hands won back-to-back — measured against the running win streak, not
  /// counted up, so it resets the way the streak does.
  winStreak,
}

/// What one settled hand contributed.
class MissionEvent {
  final bool won;
  final bool blackjack;
  final bool sweptPot;
  final int stake;
  final int winStreak;

  const MissionEvent({
    required this.won,
    required this.blackjack,
    required this.sweptPot,
    required this.stake,
    required this.winStreak,
  });
}

/// Every mission the game can draw. Kept deliberately short and plain: a
/// mission a player has to re-read is a chore, not a goal.
const List<MissionDef> kMissionPool = [
  MissionDef(id: 'play5', label: 'Play 5 hands', target: 5, reward: 150, kind: MissionKind.handsPlayed),
  MissionDef(id: 'play12', label: 'Play 12 hands', target: 12, reward: 300, kind: MissionKind.handsPlayed),
  MissionDef(id: 'win3', label: 'Win 3 hands', target: 3, reward: 200, kind: MissionKind.handsWon),
  MissionDef(id: 'win6', label: 'Win 6 hands', target: 6, reward: 400, kind: MissionKind.handsWon),
  MissionDef(id: 'bj1', label: 'Hit a blackjack', target: 1, reward: 300, kind: MissionKind.blackjacks),
  MissionDef(id: 'sweep1', label: 'Sweep the table once', target: 1, reward: 350, kind: MissionKind.sweeps),
  MissionDef(id: 'sweep2', label: 'Sweep the table twice', target: 2, reward: 600, kind: MissionKind.sweeps),
  MissionDef(id: 'silver4', label: 'Play 4 hands at Silver or above', target: 4, reward: 300, kind: MissionKind.bigStakeHands),
  MissionDef(id: 'streak3', label: 'Win 3 hands in a row', target: 3, reward: 350, kind: MissionKind.winStreak),
  MissionDef(id: 'streak4', label: 'Win 4 hands in a row', target: 4, reward: 500, kind: MissionKind.winStreak),
];

/// Table minimum at or above which a hand counts as a big-stake hand.
const int kBigStakeMin = 100;

/// How many missions run at once.
const int kMissionsPerDay = 3;

/// The three missions for [dayKey].
///
/// Seeded from the key itself, so two devices — and the same device after a
/// reinstall — agree on the day's set without any of it being stored. Never
/// draws two missions of the same kind: "play 5 hands" beside "play 12 hands"
/// is one goal wearing two labels.
List<MissionDef> missionsForDay(String dayKey) {
  final rng = math.Random(dayKey.hashCode);
  final pool = [...kMissionPool]..shuffle(rng);
  final picked = <MissionDef>[];
  final kinds = <MissionKind>{};
  for (final m in pool) {
    if (kinds.contains(m.kind)) continue;
    picked.add(m);
    kinds.add(m.kind);
    if (picked.length == kMissionsPerDay) break;
  }
  return picked;
}

/// [progress] advanced by one settled hand.
///
/// Returns a new map; missions already at their target stop counting, so a
/// long session cannot inflate a number the card would then have to clamp.
Map<String, int> advanceMissions({
  required List<MissionDef> missions,
  required Map<String, int> progress,
  required MissionEvent event,
}) {
  final next = {...progress};
  for (final m in missions) {
    final current = next[m.id] ?? 0;
    if (current >= m.target) continue;
    final value = switch (m.kind) {
      MissionKind.handsPlayed => current + 1,
      MissionKind.handsWon => event.won ? current + 1 : current,
      MissionKind.blackjacks => event.blackjack ? current + 1 : current,
      MissionKind.sweeps => event.sweptPot ? current + 1 : current,
      MissionKind.bigStakeHands => event.stake >= kBigStakeMin ? current + 1 : current,
      // Measured, not counted: the streak is already tracked, and a mission
      // that counted upward would survive a loss that broke the streak.
      MissionKind.winStreak => math.max(current, event.winStreak),
    };
    next[m.id] = math.min(value, m.target);
  }
  return next;
}

/// Whether [m] is finished but not yet claimed.
bool missionIsClaimable(MissionDef m, Map<String, int> progress, List<String> claimed) =>
    !claimed.contains(m.id) && (progress[m.id] ?? 0) >= m.target;
