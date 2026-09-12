import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/services/analytics.dart';
import 'package:blackjack21_v2/services/game_store.dart';
import 'package:blackjack21_v2/services/review_prompter.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';

class _Events extends Analytics {
  final names = <String>[];
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    names.add(name);
  }
}

class _Review extends ReviewPrompter {
  _Review(this.result);
  final bool result;
  int calls = 0;
  @override
  Future<bool> request() async {
    calls++;
    return result;
  }
}

class _Game extends GameNotifier {
  _Game({super.analytics, super.reviewPrompter});
  void seed(GameState value) => state = value;
}

GameState hand({int played = 9, int lesson = 2, bool completed = false}) => GameState(
  screen: AppScreen.table,
  phase: RoundPhase.playing,
  stake: kTables.first,
  chips: 975,
  bet: 25,
  voiceOn: false,
  soundOn: false,
  hapticsOn: false,
  tutorialRoundsSeen: lesson,
  tutorialCompletionLogged: completed,
  stats: StatsSummary(handsPlayed: played),
  hands: const [
    Hand(
      bet: 25,
      cards: [
        PlayingCard(rank: '10', suit: '♠'),
        PlayingCard(rank: '8', suit: '♥'),
      ],
    ),
  ],
  dealerHand: const [
    PlayingCard(rank: '10', suit: '♣'),
    PlayingCard(rank: '7', suit: '♦'),
  ],
);
Future<void> _settle(WidgetTester tester, _Game game) async {
  game.playerStand();
  for (var i = 0; i < 30 && game.state.phase != RoundPhase.settlement; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(game.state.phase, RoundPhase.settlement);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Play now opens a coached beginner table without spending chips', (tester) async {
    final events = _Events();
    final game = _Game(analytics: events);
    await tester.pump();
    game.playNow();
    expect(game.state.screen, AppScreen.table);
    expect(game.state.stake, kTables.first);
    expect(game.state.bet, 0);
    expect(game.state.chips, 1000);
    expect(game.state.tutorialRoundsSeen, 0);
    expect(
      events.names,
      containsAllInOrder([
        AnalyticsEvent.entrySelected,
        AnalyticsEvent.tableEntered,
        AnalyticsEvent.onboardingComplete,
      ]),
    );
    game.dispose();
    await tester.pump();
    expect((await GameStore().load())!.onboardingDone, isTrue);
  });
  for (final completed in [false, true]) {
    testWidgets('review result $completed is saved with cooldown and attempt count', (tester) async {
      final review = _Review(completed);
      final events = _Events();
      final game = _Game(analytics: events, reviewPrompter: review);
      await tester.pump();
      game.seed(hand());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settle(tester, game);
      expect(game.state.reviewLastAttemptAtMs, 0, reason: 'delayed requests must not lock out before running');
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(review.calls, 1);
      expect(game.state.reviewLastAttemptAtMs, greaterThan(0));
      expect(game.state.reviewLastRequestSucceeded, completed);
      expect(game.state.reviewRequestCount, completed ? 1 : 0);
      expect(events.names.where((e) => e == AnalyticsEvent.tenHands), hasLength(1));
      expect(events.names.where((e) => e == AnalyticsEvent.tutorialComplete), hasLength(1));
      final savedState = game.state;
      game.seed(
        hand(played: 10, completed: true).copyWith(
          reviewLastAttemptAtMs: savedState.reviewLastAttemptAtMs,
          reviewRequestCount: savedState.reviewRequestCount,
          reviewLastRequestSucceeded: completed,
        ),
      );
      await _settle(tester, game);
      await tester.pump(const Duration(seconds: 2));
      expect(review.calls, 1, reason: 'the next hand must not prompt again');
      expect(events.names.where((e) => e == AnalyticsEvent.tutorialComplete), hasLength(1));
      game.dispose();
      await tester.pump();
      final restored = await GameStore().load();
      expect(restored!.reviewLastAttemptAtMs, savedState.reviewLastAttemptAtMs);
      expect(restored.reviewRequestCount, completed ? 1 : 0);
    });
  }
  testWidgets('leaving before the review delay does not record an attempt', (tester) async {
    final review = _Review(true);
    final game = _Game(reviewPrompter: review);
    await tester.pump();
    game.seed(hand());
    await _settle(tester, game);
    game.goLobby();
    await tester.pump(const Duration(seconds: 2));
    expect(review.calls, 0);
    expect(game.state.reviewLastAttemptAtMs, 0);
    game.dispose();
  });
  testWidgets('legacy review marker gets one persisted conservative cooldown', (tester) async {
    final legacy = SavedGame.fromJson({'v': 1, 'reviewPromptShown': true, 'chips': 1234});
    await GameStore().save(legacy);
    final game = _Game();
    await tester.pump();
    expect(game.state.reviewRequestCount, 1);
    expect(game.state.reviewLastAttemptAtMs, greaterThan(0));
    expect(game.state.chips, 1234);
    final stamp = game.state.reviewLastAttemptAtMs;
    game.dispose();
    await tester.pump();
    final again = _Game();
    await tester.pump();
    expect(again.state.reviewLastAttemptAtMs, stamp);
    again.dispose();
  });
}
