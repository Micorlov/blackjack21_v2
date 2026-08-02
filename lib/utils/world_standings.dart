import '../models/game_state.dart';
import 'points.dart';

/// One rendered row in a standings list — shared by the betting panel's
/// mini card and the full "see all players" screen.
typedef StandingsRow = ({String id, String name, int points, bool isSelf});

/// Result of building the WORLD list: the rows to render, plus whether the
/// hero's row was appended unranked because it fell outside the live query.
typedef WorldStandings = ({List<StandingsRow> rows, bool selfUnranked});

/// Deterministic filler bots that pad WORLD lists to a believable size while
/// the live player base is still small. Never used on FRIENDS, which already
/// falls back to `kInitialFriends` for the same reason.
const List<({String id, String name})> kWorldFillerBots = [
  (id: 'wbot1', name: 'Liam'),
  (id: 'wbot2', name: 'Emma'),
  (id: 'wbot3', name: 'Noah'),
  (id: 'wbot4', name: 'Olivia'),
  (id: 'wbot5', name: 'Ethan'),
  (id: 'wbot6', name: 'Ava'),
  (id: 'wbot7', name: 'Lucas'),
  (id: 'wbot8', name: 'Mia'),
];

/// The hero's own points for the given period, rolled forward if the stored
/// bucket is from an earlier hour/day.
int heroPoints(GameState s, {required bool hourly}) {
  final now = DateTime.now();
  return hourly
      ? rolledPoints(s.heroHourlyPoints, s.heroHourKey, hourKeyOf(now))
      : rolledPoints(s.heroDailyPoints, s.heroDayKey, dayKeyOf(now));
}

/// Friends + hero, ranked by score. Empty when there are no live friends yet
/// — callers show an invite prompt in that case instead of an empty list.
List<StandingsRow> friendsStandingsRows(GameState s) {
  if (!s.friendsAreLive) return const [];
  final hourly = s.badgeHourly;
  final rows = [
    for (final f in s.friends)
      (id: f.id, name: f.firstName, points: hourly ? f.hourlyScore : f.dailyScore, isSelf: false),
    (id: s.heroUid ?? 'hero', name: 'You', points: heroPoints(s, hourly: hourly), isSelf: true),
  ]..sort((a, b) => b.points.compareTo(a.points));
  return rows;
}

/// Live world top players for the period. The hero's row is guaranteed to
/// appear (appended unranked when outside the live top list) and the whole
/// list is padded with filler bots up to [minCount] so it never looks
/// sparse while the real player base is still small.
WorldStandings worldStandings(GameState s, {required bool hourly, int minCount = 5}) {
  final source = hourly ? s.globalHourly : s.globalDaily;
  final rows = [
    for (final f in source)
      (
        id: f.id,
        name: f.id == s.heroUid ? 'You' : f.firstName,
        points: hourly ? f.hourlyScore : f.dailyScore,
        isSelf: f.id == s.heroUid,
      ),
  ];
  var selfUnranked = false;
  if (!rows.any((r) => r.isSelf)) {
    rows.add((id: s.heroUid ?? 'hero', name: 'You', points: heroPoints(s, hourly: hourly), isSelf: true));
    selfUnranked = true;
  }
  return (rows: _padWithWorldFillers(rows, minCount: minCount), selfUnranked: selfUnranked);
}

/// Appends deterministic filler bots (below the lowest real score) until
/// [rows] reaches [minCount] entries.
List<StandingsRow> _padWithWorldFillers(List<StandingsRow> rows, {required int minCount}) {
  if (rows.length >= minCount) return rows;
  final floor = rows.isEmpty ? 0 : rows.map((r) => r.points).reduce((a, b) => a < b ? a : b);
  final needed = minCount - rows.length;
  return [
    ...rows,
    for (var i = 0; i < needed && i < kWorldFillerBots.length; i++)
      (id: kWorldFillerBots[i].id, name: kWorldFillerBots[i].name, points: floor - (i + 1) * 5, isSelf: false),
  ];
}
