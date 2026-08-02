import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import 'formatters.dart';

/// The coaching card the table should be showing right now: which lesson it
/// belongs to, plus the text with every placeholder already filled in.
class ActiveTutorialTip {
  /// 0-based lesson index — lesson N coaches the player's Nth hand.
  final int lesson;
  final String title;
  final String body;

  const ActiveTutorialTip({required this.lesson, required this.title, required this.body});

  /// Badge text on the card, e.g. "HAND 2 OF 3".
  String get stepLabel => 'HAND ${lesson + 1} OF $kTutorialRounds';
}

/// Picks the tip for the current table state, or null when nothing should be
/// shown — the player skipped the tutorial, already played their first
/// [kTutorialRounds] hands, is not at a table, or is in a phase this lesson
/// has nothing to say about.
///
/// Pure: everything it needs is on [state], so the coach card and its tests
/// read the same source of truth the table does.
ActiveTutorialTip? tutorialTipFor(GameState state) {
  if (state.tutorialDismissed) return null;
  if (state.screen != AppScreen.table) return null;

  final lesson = state.tutorialRoundsSeen;
  if (lesson < 0 || lesson >= kTutorialLessons.length) return null;

  // Insurance is offered at random rather than on a scripted hand, so every
  // lesson falls back to the same explanation of it.
  final tip =
      kTutorialLessons[lesson].tips[state.phase] ?? (state.phase == RoundPhase.insurance ? kInsuranceTip : null);
  if (tip == null) return null;

  return ActiveTutorialTip(lesson: lesson, title: tip.title, body: _fillPlaceholders(tip.body, state));
}

/// Quotes the live table minimum rather than a hard-coded figure — the same
/// number the betting panel enforces, whichever table the player walked into.
String _fillPlaceholders(String body, GameState state) {
  final min = state.stake?.min ?? kChipDenoms.first;
  return body.replaceAll('{min}', '\$${formatChips(min)}');
}
