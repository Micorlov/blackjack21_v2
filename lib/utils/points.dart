/// Pure point-bucket and ranking logic for the social leaderboard.
///
/// Hourly and daily points are net chips won inside the current clock hour /
/// calendar day. Each bucket carries the key of the period it was earned in;
/// when the clock rolls into a new period the stale bucket counts as zero.
/// Keeping this pure (no Firestore, no DateTime.now()) makes it unit-testable.
library;

/// Key for the clock hour [t] falls in, e.g. `2026-08-01T19`.
String hourKeyOf(DateTime t) =>
    '${dayKeyOf(t)}T${t.hour.toString().padLeft(2, '0')}';

/// Key for the calendar day [t] falls in, e.g. `2026-08-01`.
String dayKeyOf(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Points a bucket is worth *now*: its stored value while [bucketKey] still
/// matches [currentKey], zero once the period has rolled over.
int rolledPoints(int points, String bucketKey, String currentKey) =>
    bucketKey == currentKey ? points : 0;

/// One competitor on a period leaderboard.
class RankedPlayer {
  final String id;
  final String name;
  final int points;

  const RankedPlayer({required this.id, required this.name, required this.points});
}

/// 1-based rank of [heroId] among [players] (higher points rank first; ties
/// resolved in the hero's favor so a shared score never demotes the hero).
int rankOf(String heroId, List<RankedPlayer> players) {
  final hero = players.where((p) => p.id == heroId).toList();
  if (hero.isEmpty) return players.length + 1;
  final heroPoints = hero.first.points;
  final ahead = players.where((p) => p.id != heroId && p.points > heroPoints).length;
  return ahead + 1;
}

/// Players who were **not** ahead of the hero in [before] but **are** ahead in
/// [after] — the friends who just overtook the user and deserve a notification.
/// A player absent from [before] (just joined) counts as previously not ahead.
List<RankedPlayer> overtakers({
  required List<RankedPlayer> before,
  required List<RankedPlayer> after,
  required String heroId,
}) {
  int pointsOf(String id, List<RankedPlayer> list, {required int orElse}) {
    for (final p in list) {
      if (p.id == id) return p.points;
    }
    return orElse;
  }

  final heroBefore = pointsOf(heroId, before, orElse: 0);
  final heroAfter = pointsOf(heroId, after, orElse: heroBefore);

  return [
    for (final p in after)
      if (p.id != heroId &&
          p.points > heroAfter &&
          // Absent from [before] (just joined) → treat as previously not
          // ahead, so a strong newcomer still triggers the alert.
          pointsOf(p.id, before, orElse: heroBefore) <= heroBefore)
        p,
  ];
}
