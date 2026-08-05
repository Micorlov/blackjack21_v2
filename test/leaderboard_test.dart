import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/theme/app_colors.dart';
import 'package:blackjack21_v2/utils/leaderboard.dart';
import 'package:blackjack21_v2/utils/points.dart';
import 'package:flutter_test/flutter_test.dart';

Friend _friend(String name, {int chips = 0, int daily = 0, int hourly = 0}) => Friend(
  id: name,
  name: name,
  chips: chips,
  online: true,
  dailyScore: daily,
  hourlyScore: hourly,
);

/// Bucket keys for "now", so hero points count instead of rolling to zero.
String get _nowHour => hourKeyOf(DateTime.now());
String get _nowDay => dayKeyOf(DateTime.now());

void main() {
  group('buildLeaderboard ranking', () {
    test('always includes the hero alongside their friends', () {
      final s = GameState(friends: [_friend('Ann', chips: 10), _friend('Bob', chips: 20)]);
      final rows = buildLeaderboard(s);

      expect(rows.length, 3);
      expect(rows.where((r) => r.isSelf).length, 1);
    });

    test('ranks highest score first and numbers ranks from one', () {
      final s = GameState(
        chips: 500,
        friends: [_friend('Ann', chips: 900), _friend('Bob', chips: 100)],
      );

      final rows = buildLeaderboard(s);
      expect(rows.map((r) => r.name).toList(), ['Ann', 'You', 'Bob']);
      expect(rows.map((r) => r.rank).toList(), [1, 2, 3]);
    });

    test('produces a leaderboard of one when the player has no friends', () {
      const s = GameState(chips: 1000);
      final rows = buildLeaderboard(s);

      expect(rows.single.rank, 1);
      expect(rows.single.isSelf, isTrue);
      expect(rows.single.name, 'You');
    });
  });

  group('buildLeaderboard period selection', () {
    test('all-time ranks on chips and formats an unsigned total', () {
      final s = GameState(
        chips: 12345,
        friends: [_friend('Ann', chips: 900, hourly: 999999)],
      );

      final rows = buildLeaderboard(s);
      expect(rows.first.isSelf, isTrue);
      expect(rows.first.scoreLabel, r'$12,345');
      expect(rows.last.scoreLabel, r'$900');
    });

    test('hourly ranks on hourly points and signs the label', () {
      final s = GameState(
        leaderboardPeriod: LeaderboardPeriod.hourly,
        chips: 999999,
        heroHourlyPoints: 40,
        heroHourKey: _nowHour,
        friends: [_friend('Ann', chips: 1, hourly: 90)],
      );

      final rows = buildLeaderboard(s);
      expect(rows.map((r) => r.name).toList(), ['Ann', 'You']);
      expect(rows.map((r) => r.scoreLabel).toList(), [r'+$90', r'+$40']);
    });

    test('daily ranks on daily points', () {
      final s = GameState(
        leaderboardPeriod: LeaderboardPeriod.daily,
        heroDailyPoints: 300,
        heroDayKey: _nowDay,
        friends: [_friend('Ann', daily: 100, hourly: 100000)],
      );

      final rows = buildLeaderboard(s);
      expect(rows.first.isSelf, isTrue);
      expect(rows.first.scoreLabel, r'+$300');
    });

    test('renders a losing period with a minus sign', () {
      final s = GameState(
        leaderboardPeriod: LeaderboardPeriod.daily,
        heroDailyPoints: -250,
        heroDayKey: _nowDay,
      );

      expect(buildLeaderboard(s).single.scoreLabel, r'-$250');
    });

    test('counts a stale hero bucket as zero once the period rolls over', () {
      const s = GameState(
        leaderboardPeriod: LeaderboardPeriod.hourly,
        heroHourlyPoints: 5000,
        heroHourKey: '1999-01-01T00',
      );

      expect(buildLeaderboard(s).single.scoreLabel, r'+$0');
    });

    test('thousands-separates large period swings', () {
      final s = GameState(
        leaderboardPeriod: LeaderboardPeriod.daily,
        heroDailyPoints: 1234567,
        heroDayKey: _nowDay,
      );

      expect(buildLeaderboard(s).single.scoreLabel, r'+$1,234,567');
    });
  });

  group('buildLeaderboard presentation', () {
    test('labels the hero row "You" whether or not they are signed in', () {
      const signedOut = GameState();
      expect(buildLeaderboard(signedOut).single.name, 'You');

      const signedIn = GameState(signedIn: true, displayName: 'Michael');
      expect(buildLeaderboard(signedIn).single.name, 'You');
    });

    test('medals only the top three and greys out the rest', () {
      final s = GameState(
        chips: 0,
        friends: [
          _friend('Ann', chips: 50),
          _friend('Bob', chips: 40),
          _friend('Cid', chips: 30),
          _friend('Dee', chips: 20),
        ],
      );

      final rows = buildLeaderboard(s);
      expect(rows[0].medalColor, AppColors.medalColor(1));
      expect(rows[1].medalColor, AppColors.medalColor(2));
      expect(rows[2].medalColor, AppColors.medalColor(3));
      expect(rows[3].medalColor, AppColors.border);
      expect(rows[4].medalColor, AppColors.border);
    });

    test('tints the hero name gold and friends in the default colour', () {
      final s = GameState(chips: 10, friends: [_friend('Ann', chips: 20)]);
      final rows = buildLeaderboard(s);

      expect(rows.singleWhere((r) => r.isSelf).nameColor, AppColors.gold);
      expect(rows.singleWhere((r) => !r.isSelf).nameColor, AppColors.textPrimary);
    });

    test('keeps friend names verbatim', () {
      final s = GameState(chips: 0, friends: [_friend('Ann Marie Lee', chips: 50)]);
      expect(buildLeaderboard(s).first.name, 'Ann Marie Lee');
    });
  });
}
