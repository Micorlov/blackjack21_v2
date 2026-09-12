import 'package:flutter/widgets.dart';

import '../data/tutorial_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import 'generated/app_localizations.dart';

/// The fallback also supports isolated widgets without a MaterialApp delegate.
AppLocalizations gameplayStrings(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ?? lookupAppLocalizations(const Locale('en'));

TutorialTip? localizedCoach(GameState state, AppLocalizations l, String minimum) {
  if (state.phase == RoundPhase.insurance) {
    return TutorialTip(title: l.gameInsure, body: l.coachInsuranceBody);
  }
  return switch ((state.tutorialRoundsSeen, state.phase)) {
    (0, RoundPhase.betting) => TutorialTip(title: l.gameBet, body: l.coachBetBody(minimum)),
    (0, RoundPhase.npcs) => TutorialTip(title: l.gamePracticeBots, body: l.coachNpcBody),
    (0, RoundPhase.playing) => TutorialTip(title: '${l.gameHit} / ${l.gameStand}', body: l.coachPlayBody),
    (0, RoundPhase.settlement) => TutorialTip(title: l.gameBalance, body: l.coachSettleBody),
    (1, RoundPhase.betting) => TutorialTip(title: l.gameBet, body: l.coachBetBody(minimum)),
    (1, RoundPhase.playing) => TutorialTip(title: l.gameAgainstDealer, body: l.coachDealerBody),
    (1, RoundPhase.settlement) => TutorialTip(title: l.gamePush, body: l.coachPushBody),
    (2, RoundPhase.betting) => TutorialTip(title: l.gameSweepPot, body: l.coachPotBody),
    (2, RoundPhase.playing) => TutorialTip(title: '${l.gameDouble} / ${l.gameSplit}', body: l.coachMovesBody),
    (2, RoundPhase.settlement) => TutorialTip(title: l.howToPlayLabel, body: l.coachDoneBody),
    _ => null,
  };
}

List<GuideSection> localizedGuide(AppLocalizations l) => [
  GuideSection(title: l.howToPlayLabel, lines: [l.coachPlayBody, l.guideCardsBody]),
  GuideSection(title: '${l.gameDouble} / ${l.gameSplit} / ${l.gameSurrender}', lines: [l.coachMovesBody]),
  GuideSection(title: l.gameAgainstDealer, lines: [l.coachDealerBody, l.coachPushBody]),
  GuideSection(title: l.gameInsure, lines: [l.coachInsuranceBody]),
  GuideSection(title: l.gameBalance, lines: [l.guidePayoutsBody]),
  GuideSection(title: l.gameSweepPot, lines: [l.coachPotBody]),
  GuideSection(title: l.gameChipOptions, lines: [l.guideChipsBody]),
];

/// Stored outcomes stay language-neutral across a language change. Old saves
/// use these stable English labels; translate at display time, not at settlement.
String localizedResult(String result, AppLocalizations l) => switch (result) {
  'Dealer has blackjack' => l.gameDealerBlackjack,
  'Blackjack! You win' => l.gameBlackjackWin,
  'You win!' => l.gameWin,
  'Dealer wins' => l.gameLose,
  'Push' => l.gamePush,
  'Blackjack — you sweep' => l.gameBlackjackSweep,
  'You sweep the table' => l.gameSweepWin,
  _ => result,
};
