import 'dart:convert';

import 'package:blackjack21_v2/data/tutorial_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/services/game_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedGame sample({
  int chips = 1250,
  List<RoundResult> history = const [RoundResult.win, RoundResult.loss],
  int hourlyPoints = 150,
  String hourKey = '2026-08-02T00',
  String dayKey = '2026-08-02',
}) => SavedGame(
  chips: chips,
  stats: const StatsSummary(
    handsPlayed: 8,
    wins: 5,
    losses: 2,
    pushes: 1,
    blackjacks: 1,
    currentStreak: 2,
    bestStreak: 3,
  ),
  history: history,
  hourlyPoints: hourlyPoints,
  dailyPoints: 250,
  hourKey: hourKey,
  dayKey: dayKey,
  soundOn: false,
  voiceOn: false,
  hapticsOn: false,
  notifSocial: false,
  notifLeaderboard: false,
  notifDaily: true,
  themeChoice: 'ocean',
  cardBackSkin: 'midnight',
  avatarFrameGold: true,
  claimedTiers: const ['tier1'],
  tutorialRoundsSeen: 2,
  tutorialDismissed: false,
  rewardedReferralIds: const ['u1', 'u2'],
  playDayStreak: 4,
  lastPlayDayKey: '2026-09-04',
  lastRebuyAtMs: 1756900000000,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SavedGame serialization', () {
    test('round-trips every persisted field', () {
      final restored = SavedGame.fromJson(sample().toJson());

      expect(restored.chips, 1250);
      expect(restored.stats.handsPlayed, 8);
      expect(restored.stats.wins, 5);
      expect(restored.stats.bestStreak, 3);
      expect(restored.history, [RoundResult.win, RoundResult.loss]);
      expect(restored.hourlyPoints, 150);
      expect(restored.dailyPoints, 250);
      expect(restored.hourKey, '2026-08-02T00');
      expect(restored.dayKey, '2026-08-02');
      expect(restored.soundOn, isFalse);
      expect(restored.voiceOn, isFalse);
      expect(restored.hapticsOn, isFalse);
      expect(restored.notifDaily, isTrue);
      expect(restored.themeChoice, 'ocean');
      expect(restored.cardBackSkin, 'midnight');
      expect(restored.avatarFrameGold, isTrue);
      expect(restored.claimedTiers, ['tier1']);
      expect(restored.tutorialRoundsSeen, 2);
      expect(restored.tutorialDismissed, isFalse);
      expect(restored.rewardedReferralIds, ['u1', 'u2']);
      expect(restored.playDayStreak, 4);
      expect(restored.lastPlayDayKey, '2026-09-04');
      expect(restored.lastRebuyAtMs, 1756900000000);
    });

    test('survives a JSON encode/decode hop', () {
      final decoded = jsonDecode(jsonEncode(sample().toJson())) as Map<String, Object?>;
      expect(SavedGame.fromJson(decoded).chips, 1250);
    });

    test('falls back to GameState defaults when keys are missing', () {
      const defaults = GameState();
      final restored = SavedGame.fromJson(<String, Object?>{'v': 1});

      expect(restored.chips, defaults.chips);
      expect(restored.soundOn, defaults.soundOn);
      // A blob saved before the voice toggle existed keeps the table talking,
      // which is what that player has been hearing all along.
      expect(restored.voiceOn, isTrue);
      expect(restored.hapticsOn, defaults.hapticsOn);
      expect(restored.themeChoice, defaults.themeChoice);
      expect(restored.history, isEmpty);
      expect(restored.claimedTiers, isEmpty);
      expect(restored.tutorialRoundsSeen, 0);
      expect(restored.tutorialDismissed, isFalse);
      expect(restored.rewardedReferralIds, isEmpty);
      expect(restored.playDayStreak, 0);
      expect(restored.lastPlayDayKey, isEmpty);
      expect(restored.lastRebuyAtMs, 0);
    });

    test('a player saved before the tutorial existed is not re-tutored', () {
      // No tutorial keys, but hands on the clock: those hands stand in for
      // lessons, so a veteran never gets coaching cards after an update.
      final veteran = SavedGame.fromJson(<String, Object?>{
        'v': 1,
        'stats': {'handsPlayed': 40},
      });
      final novice = SavedGame.fromJson(<String, Object?>{
        'v': 1,
        'stats': {'handsPlayed': 1},
      });

      expect(veteran.tutorialRoundsSeen, kTutorialRounds);
      expect(novice.tutorialRoundsSeen, 1);
    });

    test('ignores values of the wrong type instead of throwing', () {
      final restored = SavedGame.fromJson(<String, Object?>{
        'v': 1,
        'chips': 'not-a-number',
        'soundOn': 3,
        'history': 'not-a-list',
        'claimedTiers': [1, 'tier2'],
      });

      expect(restored.chips, const GameState().chips);
      expect(restored.soundOn, const GameState().soundOn);
      expect(restored.history, isEmpty);
      expect(restored.claimedTiers, ['tier2']);
    });

    test('drops unreadable history entries rather than guessing a result', () {
      final restored = SavedGame.fromJson(<String, Object?>{
        'v': 1,
        'history': ['win', 'sideways', 'push'],
      });

      expect(restored.history, [RoundResult.win, RoundResult.push]);
    });

    test('trims history to the newest kSavedHistoryLimit hands', () {
      final long = List<RoundResult>.filled(kSavedHistoryLimit + 10, RoundResult.loss)
        ..[kSavedHistoryLimit + 9] = RoundResult.win;
      final restored = SavedGame.fromJson(sample(history: long).toJson());

      expect(restored.history, hasLength(kSavedHistoryLimit));
      // The tail is what comeback dealing reads, so the newest hand must survive.
      expect(restored.history.last, RoundResult.win);
    });
  });

  group('GameStore', () {
    test('load returns null before anything has been saved', () async {
      expect(await GameStore().load(), isNull);
    });

    test('saves and loads a player', () async {
      final store = GameStore();
      await store.save(sample(chips: 4200));

      expect((await store.load())?.chips, 4200);
    });

    test('the newest save wins', () async {
      final store = GameStore();
      await store.save(sample(chips: 100));
      await store.save(sample(chips: 900));

      expect((await store.load())?.chips, 900);
    });

    test('discards a blob written by an unknown schema version', () async {
      SharedPreferences.setMockInitialValues({
        'gameStateV1': jsonEncode({'v': 999, 'chips': 5000}),
      });

      expect(await GameStore().load(), isNull);
    });

    test('degrades to null on a corrupted blob instead of throwing', () async {
      SharedPreferences.setMockInitialValues({'gameStateV1': 'not json at all'});

      expect(await GameStore().load(), isNull);
    });
  });
}
