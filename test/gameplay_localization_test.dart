import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blackjack21_v2/data/game_data.dart';
import 'package:blackjack21_v2/l10n/gameplay.dart';
import 'package:blackjack21_v2/l10n/generated/app_localizations.dart';
import 'package:blackjack21_v2/main.dart';
import 'package:blackjack21_v2/models/enums.dart';
import 'package:blackjack21_v2/models/game_state.dart';
import 'package:blackjack21_v2/models/hand.dart';
import 'package:blackjack21_v2/models/playing_card.dart';
import 'package:blackjack21_v2/state/game_notifier.dart';
import 'package:blackjack21_v2/utils/tutorial.dart';
import 'support/real_fonts.dart';

class _Fixed extends GameNotifier {
  _Fixed(GameState value) {
    state = value;
  }
}

void main() {
  setUpAll(loadRealTestFonts);
  for (final locale in AppLocalizations.supportedLocales) {
    final l = lookupAppLocalizations(locale);
    test('${locale.languageCode} has complete coaching, rules and results', () {
      for (var lesson = 0; lesson < 3; lesson++) {
        for (final phase in [RoundPhase.betting, RoundPhase.playing, RoundPhase.insurance, RoundPhase.settlement]) {
          final tip = tutorialTipFor(
            GameState(screen: AppScreen.table, phase: phase, stake: kTables.first, tutorialRoundsSeen: lesson),
            strings: l,
          );
          expect(tip, isNotNull);
          expect(tip!.body, isNot(contains('{min}')));
          if (phase == RoundPhase.betting && lesson < 2) expect(tip.body, contains('\$25'));
        }
      }
      expect(localizedGuide(l).map((s) => s.lines.join()).join(), contains('3:2'));
      expect(localizedResult('You win!', l), l.gameWin);
      if (locale.languageCode != 'en') {
        expect(l.coachPlayBody, isNot(lookupAppLocalizations(const Locale('en')).coachPlayBody));
      }
    });
    for (final phase in [RoundPhase.playing, RoundPhase.betting, RoundPhase.settlement]) {
      testWidgets('${locale.languageCode} $phase fits a small screen at large text', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gameProvider.overrideWith(
                (ref) => _Fixed(
                  GameState(
                    screen: AppScreen.table,
                    phase: phase,
                    stake: kTables.first,
                    languageOverride: locale.languageCode,
                    tutorialRoundsSeen: 0,
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
                      PlayingCard(rank: '9', suit: '♣'),
                      PlayingCard(rank: '8', suit: '♦'),
                    ],
                    holeRevealed: phase == RoundPhase.settlement,
                    message: 'You win!',
                    messageType: MessageType.win,
                  ),
                ),
              ),
            ],
            child: const BlackjackApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          ['he', 'ar'].contains(locale.languageCode) ? TextDirection.rtl : TextDirection.ltr,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
