import 'package:flutter_test/flutter_test.dart';

import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/utils/achievements.dart';

void main() {
  group('unlocking', () {
    test('a fresh player has earned nothing', () {
      expect(newlyUnlocked(const GameState(), const []), isEmpty);
    });

    test('the first hand unlocks the first achievement', () {
      const state = GameState(stats: StatsSummary(handsPlayed: 1));
      expect(newlyUnlocked(state, const []).map((d) => d.id), ['first']);
    });

    test('never returns one that has already been paid', () {
      // This is the whole guarantee: achievements are checked after every
      // hand, so anything already in the list must never come back.
      const state = GameState(stats: StatsSummary(handsPlayed: 1));
      expect(newlyUnlocked(state, const ['first']), isEmpty);
    });

    test('one hand can complete several at once, in a stable order', () {
      const state = GameState(
        chips: 9000,
        stats: StatsSummary(handsPlayed: 120, blackjacks: 2, bestStreak: 5),
      );
      final ids = newlyUnlocked(state, const []).map((d) => d.id).toList();
      expect(ids, ['first', 'bj', 'streak3', 'highroller', 'century']);
      expect(newlyUnlocked(state, ids), isEmpty);
    });

    test('the ones nothing at the table can trigger still unlock', () {
      const vip = GameState(visitedVIP: true);
      expect(newlyUnlocked(vip, const []).map((d) => d.id), contains('vip'));

      const social = GameState(referralsCount: 3);
      expect(newlyUnlocked(social, const []).map((d) => d.id), contains('social'));
    });
  });

  group('rewards', () {
    test('every achievement pays something', () {
      // They were decorative for the app's whole life; a zero here would put
      // one of them back to being a badge that does nothing.
      for (final def in kAchievementDefs) {
        expect(def.reward, greaterThan(0), reason: '${def.id} pays nothing');
      }
    });

    test('a batch pays the sum of its parts', () {
      const state = GameState(stats: StatsSummary(handsPlayed: 1, blackjacks: 1));
      final earned = newlyUnlocked(state, const []);
      expect(achievementReward(earned), earned.fold(0, (t, d) => t + d.reward));
    });

    test('the harder ones pay more than the first hand', () {
      final first = kAchievementDefs.firstWhere((d) => d.id == 'first');
      final century = kAchievementDefs.firstWhere((d) => d.id == 'century');
      expect(century.reward, greaterThan(first.reward * 5));
    });
  });

  group('progress', () {
    test('counting achievements report where the player stands', () {
      const state = GameState(stats: StatsSummary(handsPlayed: 12));
      final century = kAchievementDefs.firstWhere((d) => d.id == 'century');
      expect(century.progress!(state), (12, 100));
    });

    test('progress never runs past its target', () {
      const state = GameState(stats: StatsSummary(handsPlayed: 400));
      final century = kAchievementDefs.firstWhere((d) => d.id == 'century');
      expect(century.progress!(state), (100, 100));
    });

    test('one-off achievements report no progress at all', () {
      // A bar drawn for "hit a natural 21" is a checkbox pretending to be a
      // meter.
      expect(kAchievementDefs.firstWhere((d) => d.id == 'bj').progress, isNull);
      expect(kAchievementDefs.firstWhere((d) => d.id == 'vip').progress, isNull);
    });
  });
}
