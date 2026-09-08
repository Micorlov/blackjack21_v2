/// When to ask a player for a Play Store rating.
///
/// Pure on purpose: the decision is the part worth testing, and it must not
/// need a plugin, a platform channel or a store to exercise. The service that
/// actually opens Google's sheet lives in `services/review_prompter.dart`.
library;

/// Hands that must be behind a player before the ask is allowed.
///
/// Ten is roughly two tables' worth of play — long enough that the player has
/// seen the tutorial finish, a settlement card, and the sweep pot, and short
/// enough that most of the people who will ever like the game are still here.
const int kReviewMinHands = 10;

/// Consecutive wins that count as a good moment on their own.
const int kReviewWinStreak = 3;

/// Whether this settled hand is the right one to ask for a rating on.
///
/// Asking is a one-shot: [alreadyAsked] is the flag persisted in
/// `SavedGame.reviewPromptShown`, and it is never cleared. The three "good
/// moment" signals are deliberately the loudest outcomes the game has — the
/// player has just been told they swept the table, hit a natural, or won a
/// third hand in a row, and the settlement card saying so is on screen.
///
/// A loss, a push, or a plain win is never a good moment to ask on: the star
/// rating a player leaves right after losing chips is the one the store keeps.
bool shouldPromptForReview({
  required bool alreadyAsked,
  required int handsPlayed,
  required bool sweptPot,
  required bool blackjack,
  required int winStreak,
}) {
  if (alreadyAsked) return false;
  if (handsPlayed < kReviewMinHands) return false;
  return sweptPot || blackjack || winStreak >= kReviewWinStreak;
}
