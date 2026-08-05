import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/utils/points.dart';
import 'package:blackjack21_v2/utils/world_standings.dart';
import 'package:flutter_test/flutter_test.dart';

Friend _friend(String id, String name, {int daily = 0, int hourly = 0}) => Friend(
  id: id,
  name: name,
  chips: 0,
  online: true,
  dailyScore: daily,
  hourlyScore: hourly,
);

/// Bucket keys for "now", so hero points count instead of rolling to zero.
String get _nowHour => hourKeyOf(DateTime.now());
String get _nowDay => dayKeyOf(DateTime.now());

void main() {
  group('heroPoints', () {
    test('returns the live bucket for the requested period', () {
      final s = GameState(
        heroHourlyPoints: 70,
        heroDailyPoints: 250,
        heroHourKey: _nowHour,
        heroDayKey: _nowDay,
      );
      expect(heroPoints(s, hourly: true), 70);
      expect(heroPoints(s, hourly: false), 250);
    });

    test('rolls a stale bucket to zero', () {
      const s = GameState(
        heroHourlyPoints: 70,
        heroDailyPoints: 250,
        heroHourKey: '1999-01-01T00',
        heroDayKey: '1999-01-01',
      );
      expect(heroPoints(s, hourly: true), 0);
      expect(heroPoints(s, hourly: false), 0);
    });
  });

  group('friendsStandingsRows', () {
    test('is empty until friends are live, so callers can show the invite prompt', () {
      final s = GameState(friends: [_friend('f1', 'Ann Lee', hourly: 10)]);
      expect(s.friendsAreLive, isFalse);
      expect(friendsStandingsRows(s), isEmpty);
    });

    test('ranks friends and hero together, highest first', () {
      final s = GameState(
        friendsAreLive: true,
        badgeHourly: true,
        heroUid: 'me',
        heroHourlyPoints: 50,
        heroHourKey: _nowHour,
        friends: [
          _friend('f1', 'Ann Lee', hourly: 90),
          _friend('f2', 'Bob Ray', hourly: 20),
        ],
      );

      final rows = friendsStandingsRows(s);
      expect(rows.map((r) => r.name).toList(), ['Ann', 'You', 'Bob']);
      expect(rows.map((r) => r.points).toList(), [90, 50, 20]);
      expect(rows.singleWhere((r) => r.isSelf).id, 'me');
    });

    test('uses first names only', () {
      final s = GameState(
        friendsAreLive: true,
        friends: [_friend('f1', 'Ann Marie Lee', hourly: 5)],
      );
      expect(friendsStandingsRows(s).first.name, 'Ann');
    });

    test('switches to daily scores when the hourly badge is off', () {
      final s = GameState(
        friendsAreLive: true,
        badgeHourly: false,
        heroDailyPoints: 5,
        heroDayKey: _nowDay,
        friends: [_friend('f1', 'Ann Lee', daily: 400, hourly: 1)],
      );

      final rows = friendsStandingsRows(s);
      expect(rows.first.points, 400);
      expect(rows.last.points, 5);
    });

    test('falls back to a placeholder id when the hero has no uid', () {
      final s = GameState(friendsAreLive: true, friends: [_friend('f1', 'Ann Lee')]);
      expect(friendsStandingsRows(s).singleWhere((r) => r.isSelf).id, 'hero');
    });
  });

  group('worldStandings', () {
    test('marks the hero row when it is already in the live query', () {
      final s = GameState(
        heroUid: 'me',
        globalHourly: [
          _friend('other', 'Ann Lee', hourly: 90),
          _friend('me', 'Michael O', hourly: 60),
        ],
      );

      final result = worldStandings(s, hourly: true, minCount: 0);
      expect(result.selfUnranked, isFalse);

      final self = result.rows.singleWhere((r) => r.isSelf);
      expect(self.id, 'me');
      expect(self.name, 'You');
      expect(self.points, 60);
    });

    test('appends the hero unranked when they fall outside the live query', () {
      final s = GameState(
        heroUid: 'me',
        heroHourlyPoints: 12,
        heroHourKey: _nowHour,
        globalHourly: [_friend('other', 'Ann Lee', hourly: 90)],
      );

      final result = worldStandings(s, hourly: true, minCount: 0);
      expect(result.selfUnranked, isTrue);
      expect(result.rows.last.isSelf, isTrue);
      expect(result.rows.last.points, 12);
    });

    test('reads the daily list and daily scores when hourly is false', () {
      final s = GameState(
        heroUid: 'me',
        globalHourly: [_friend('h', 'Hourly Only', hourly: 999)],
        globalDaily: [_friend('me', 'Michael O', daily: 300, hourly: 999)],
      );

      final result = worldStandings(s, hourly: false, minCount: 0);
      expect(result.rows.single.points, 300);
      expect(result.rows.single.isSelf, isTrue);
    });

    test('pads short lists with filler bots below the lowest real score', () {
      final s = GameState(
        heroUid: 'me',
        globalHourly: [
          _friend('other', 'Ann Lee', hourly: 90),
          _friend('me', 'Michael O', hourly: 60),
        ],
      );

      final rows = worldStandings(s, hourly: true, minCount: 5).rows;
      expect(rows.length, 5);
      // Real rows are untouched; fillers descend 5 points at a time from the
      // lowest real score (60).
      expect(rows.map((r) => r.points).toList(), [90, 60, 55, 50, 45]);
      expect(rows.sublist(2).map((r) => r.name).toList(), ['Liam', 'Emma', 'Noah']);
      expect(rows.sublist(2).every((r) => !r.isSelf), isTrue);
    });

    test('never pads a list that already meets the minimum', () {
      final s = GameState(
        heroUid: 'me',
        globalHourly: [
          _friend('a', 'A A', hourly: 30),
          _friend('b', 'B B', hourly: 20),
          _friend('me', 'M M', hourly: 10),
        ],
      );

      final rows = worldStandings(s, hourly: true, minCount: 3).rows;
      expect(rows.length, 3);
      expect(rows.every((r) => !r.id.startsWith('wbot')), isTrue);
    });

    test('pads from a zero floor when the hero is the only row', () {
      const s = GameState(heroUid: 'me');
      final rows = worldStandings(s, hourly: true, minCount: 3).rows;
      expect(rows.length, 3);
      expect(rows.map((r) => r.points).toList(), [0, -5, -10]);
    });

    test('cannot pad beyond the filler pool, even for a large minimum', () {
      const s = GameState(heroUid: 'me');
      final rows = worldStandings(s, hourly: true, minCount: 50).rows;
      // 1 hero row + the 8 available bots.
      expect(rows.length, 1 + kWorldFillerBots.length);
    });

    test('defaults to a minimum of five rows', () {
      const s = GameState(heroUid: 'me');
      expect(worldStandings(s, hourly: true).rows.length, 5);
    });
  });
}
