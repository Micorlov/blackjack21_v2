import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/data/tutorial_data.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/social_models.dart';
import 'package:blackjack21_v2/utils/formatters.dart';
import 'package:blackjack21_v2/utils/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

GameState atTable({
  RoundPhase phase = RoundPhase.betting,
  int roundsSeen = 0,
  bool dismissed = false,
  TableStake? stake,
}) => GameState(
  screen: AppScreen.table,
  phase: phase,
  tutorialRoundsSeen: roundsSeen,
  tutorialDismissed: dismissed,
  stake: stake ?? kTables.first,
);

void main() {
  group('tutorialTipFor', () {
    test('coaches the very first bet', () {
      final tip = tutorialTipFor(atTable());

      expect(tip, isNotNull);
      expect(tip!.lesson, 0);
      expect(tip.stepLabel, 'COACH · HAND 1 OF 3');
      expect(tip.title, isNotEmpty);
    });

    test('quotes the minimum of the table the player actually walked into', () {
      final bronze = tutorialTipFor(atTable(stake: kTables.first))!;
      final vip = tutorialTipFor(atTable(stake: kTables.last))!;

      expect(bronze.body, contains('\$${formatChips(kTables.first.min)}'));
      expect(vip.body, contains('\$${formatChips(kTables.last.min)}'));
      // No placeholder may ever reach the player.
      expect(bronze.body, isNot(contains('{min}')));
      expect(vip.body, isNot(contains('{min}')));
    });

    test('advances one lesson per hand seen', () {
      for (var lesson = 0; lesson < kTutorialRounds; lesson++) {
        final tip = tutorialTipFor(atTable(roundsSeen: lesson));

        expect(tip, isNotNull, reason: 'lesson $lesson should still coach');
        expect(tip!.lesson, lesson);
        expect(tip.stepLabel, 'COACH · HAND ${lesson + 1} OF $kTutorialRounds');
      }
    });

    test('stops after the third hand', () {
      expect(tutorialTipFor(atTable(roundsSeen: kTutorialRounds)), isNull);
      expect(tutorialTipFor(atTable(roundsSeen: kTutorialRounds + 5)), isNull);
    });

    test('stays silent once skipped', () {
      expect(tutorialTipFor(atTable(dismissed: true)), isNull);
    });

    test('never shows away from the table', () {
      for (final screen in AppScreen.values.where((s) => s != AppScreen.table)) {
        expect(
          tutorialTipFor(const GameState().copyWith(screen: screen)),
          isNull,
          reason: '$screen is not a table',
        );
      }
    });

    test('explains insurance in every lesson, however the Ace falls', () {
      for (var lesson = 0; lesson < kTutorialRounds; lesson++) {
        final tip = tutorialTipFor(atTable(phase: RoundPhase.insurance, roundsSeen: lesson));

        expect(tip, isNotNull, reason: 'lesson $lesson must cover insurance');
        expect(tip!.body, contains('2:1'));
      }
    });

    test('covers the phases the player acts in, on every lesson', () {
      const acting = [RoundPhase.betting, RoundPhase.playing, RoundPhase.settlement];
      for (var lesson = 0; lesson < kTutorialRounds; lesson++) {
        for (final phase in acting) {
          expect(
            tutorialTipFor(atTable(phase: phase, roundsSeen: lesson)),
            isNotNull,
            reason: 'lesson $lesson has nothing to say in $phase',
          );
        }
      }
    });

    test('says nothing while the dealer plays — that phase is not interactive', () {
      expect(tutorialTipFor(atTable(phase: RoundPhase.dealer)), isNull);
    });
  });

  group('tutorial content', () {
    test('ships exactly one lesson per coached hand', () {
      expect(kTutorialLessons, hasLength(kTutorialRounds));
    });

    test('every tip is written, not a placeholder', () {
      for (final lesson in kTutorialLessons) {
        for (final entry in lesson.tips.entries) {
          expect(entry.value.title, isNotEmpty, reason: '${lesson.name} / ${entry.key}');
          expect(entry.value.body.length, greaterThan(20), reason: '${lesson.name} / ${entry.key}');
        }
      }
    });

    test('the guide covers the rules a new player needs', () {
      final guide = kGuideSections.map((s) => '${s.title} ${s.lines.join(' ')}').join('\n');

      expect(guide, contains('21'));
      expect(guide, contains('3:2')); // blackjack payout
      expect(guide, contains('2:1')); // insurance payout
      expect(guide, contains('17')); // dealer draw rule
      for (final section in kGuideSections) {
        expect(section.lines, isNotEmpty, reason: '${section.title} has no body');
      }
    });
  });
}
