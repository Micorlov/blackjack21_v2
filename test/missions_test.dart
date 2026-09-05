import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/utils/missions.dart';
import 'package:blackjack21_v2/utils/points.dart';

MissionEvent _hand({
  bool won = false,
  bool blackjack = false,
  bool sweptPot = false,
  int stake = 25,
  int winStreak = 0,
}) => MissionEvent(won: won, blackjack: blackjack, sweptPot: sweptPot, stake: stake, winStreak: winStreak);

void main() {
  group('drawing the day', () {
    test('the same day always draws the same three', () {
      // Nothing about the draw is stored, so two devices — and the same device
      // after a reinstall — have to agree from the date alone.
      final a = missionsForDay('2026-09-05').map((m) => m.id).toList();
      final b = missionsForDay('2026-09-05').map((m) => m.id).toList();
      expect(a, b);
      expect(a, hasLength(kMissionsPerDay));
    });

    test('a different day draws a different set', () {
      final days = [for (var d = 1; d <= 14; d++) missionsForDay('2026-09-${d.toString().padLeft(2, '0')}')];
      final signatures = days.map((set) => set.map((m) => m.id).join(',')).toSet();
      expect(signatures.length, greaterThan(1), reason: 'every day drew the identical set');
    });

    test('never draws two missions that are the same goal twice', () {
      // "Play 5 hands" next to "Play 12 hands" is one goal wearing two labels.
      for (var d = 1; d <= 60; d++) {
        final set = missionsForDay(dayKeyOf(DateTime(2026, 1, 1).add(Duration(days: d))));
        final kinds = set.map((m) => m.kind).toSet();
        expect(kinds.length, set.length, reason: 'duplicate mission kind on day $d');
      }
    });

    test('every drawn mission is reachable in one sitting', () {
      for (var d = 1; d <= 30; d++) {
        for (final m in missionsForDay('2026-03-${d.toString().padLeft(2, '0')}')) {
          expect(m.target, lessThanOrEqualTo(12));
          expect(m.reward, greaterThan(0));
        }
      }
    });
  });

  group('progress', () {
    final missions = [
      const MissionDef(id: 'play5', label: 'Play 5 hands', target: 5, reward: 150, kind: MissionKind.handsPlayed),
      const MissionDef(id: 'win3', label: 'Win 3 hands', target: 3, reward: 200, kind: MissionKind.handsWon),
      const MissionDef(id: 'streak3', label: 'Win 3 in a row', target: 3, reward: 350, kind: MissionKind.winStreak),
    ];

    test('a played hand counts toward playing, a won hand toward both', () {
      var p = advanceMissions(missions: missions, progress: const {}, event: _hand());
      expect(p['play5'], 1);
      expect(p['win3'], 0);

      p = advanceMissions(missions: missions, progress: p, event: _hand(won: true, winStreak: 1));
      expect(p['play5'], 2);
      expect(p['win3'], 1);
    });

    test('never counts past the target', () {
      var p = <String, int>{};
      for (var i = 0; i < 20; i++) {
        p = advanceMissions(missions: missions, progress: p, event: _hand(won: true, winStreak: i + 1));
      }
      expect(p['play5'], 5);
      expect(p['win3'], 3);
    });

    test('a streak mission follows the streak rather than counting up', () {
      // Counting upward would let a player who won three separate hands, with
      // losses between them, claim "three in a row".
      var p = advanceMissions(missions: missions, progress: const {}, event: _hand(won: true, winStreak: 1));
      p = advanceMissions(missions: missions, progress: p, event: _hand(won: true, winStreak: 2));
      p = advanceMissions(missions: missions, progress: p, event: _hand(winStreak: 0));
      p = advanceMissions(missions: missions, progress: p, event: _hand(won: true, winStreak: 1));
      expect(p['streak3'], 2, reason: 'the best streak so far was two');
    });

    test('progress does not mutate the map it was given', () {
      const before = <String, int>{'play5': 1};
      final after = advanceMissions(missions: missions, progress: before, event: _hand());
      expect(before['play5'], 1);
      expect(after['play5'], 2);
    });
  });

  group('claiming', () {
    const m = MissionDef(id: 'win3', label: 'Win 3 hands', target: 3, reward: 200, kind: MissionKind.handsWon);

    test('is claimable only once it is finished', () {
      expect(missionIsClaimable(m, const {'win3': 2}, const []), isFalse);
      expect(missionIsClaimable(m, const {'win3': 3}, const []), isTrue);
    });

    test('cannot be claimed twice', () {
      expect(missionIsClaimable(m, const {'win3': 3}, const ['win3']), isFalse);
    });
  });
}
