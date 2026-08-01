import 'package:blackjack21_v2/utils/points.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bucket keys', () {
    test('hourKeyOf and dayKeyOf zero-pad the timestamp', () {
      final t = DateTime(2026, 8, 1, 9, 5);
      expect(dayKeyOf(t), '2026-08-01');
      expect(hourKeyOf(t), '2026-08-01T09');
    });

    test('rolledPoints keeps points inside the same period', () {
      expect(rolledPoints(120, '2026-08-01T09', '2026-08-01T09'), 120);
    });

    test('rolledPoints zeroes a stale bucket after rollover', () {
      expect(rolledPoints(120, '2026-08-01T09', '2026-08-01T10'), 0);
      expect(rolledPoints(120, '', '2026-08-01T10'), 0);
    });
  });

  group('rankOf', () {
    const hero = RankedPlayer(id: 'me', name: 'You', points: 50);

    test('ranks the hero below higher scores only', () {
      final players = [
        const RankedPlayer(id: 'a', name: 'A', points: 100),
        const RankedPlayer(id: 'b', name: 'B', points: 10),
        hero,
      ];
      expect(rankOf('me', players), 2);
    });

    test('resolves ties in the hero favor', () {
      final players = [const RankedPlayer(id: 'a', name: 'A', points: 50), hero];
      expect(rankOf('me', players), 1);
    });
  });

  group('overtakers', () {
    const heroId = 'me';

    List<RankedPlayer> snapshot(int hero, int maya, int jordan) => [
      RankedPlayer(id: heroId, name: 'You', points: hero),
      RankedPlayer(id: 'maya', name: 'Maya', points: maya),
      RankedPlayer(id: 'jordan', name: 'Jordan', points: jordan),
    ];

    test('reports a friend who moved from behind to ahead', () {
      final result = overtakers(
        before: snapshot(100, 80, 20),
        after: snapshot(100, 130, 20),
        heroId: heroId,
      );
      expect(result.map((p) => p.id), ['maya']);
    });

    test('ignores friends who were already ahead', () {
      final result = overtakers(
        before: snapshot(100, 150, 20),
        after: snapshot(100, 180, 20),
        heroId: heroId,
      );
      expect(result, isEmpty);
    });

    test('ignores friends still behind', () {
      final result = overtakers(
        before: snapshot(100, 80, 20),
        after: snapshot(100, 90, 40),
        heroId: heroId,
      );
      expect(result, isEmpty);
    });

    test('a brand-new member ahead of the hero counts as an overtake', () {
      final result = overtakers(
        before: [RankedPlayer(id: heroId, name: 'You', points: 100)],
        after: [
          RankedPlayer(id: heroId, name: 'You', points: 100),
          const RankedPlayer(id: 'new', name: 'Noa', points: 500),
        ],
        heroId: heroId,
      );
      expect(result.map((p) => p.id), ['new']);
    });
  });
}
