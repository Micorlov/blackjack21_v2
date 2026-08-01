/// Comeback dealing — the retention mechanic.
///
/// When the hero is close to busting out (short stack or on a losing streak)
/// the deal looks at the next few pairs sitting on top of the shoe and gives
/// the hero the *best* of them instead of blindly taking the top two. Every
/// card still comes out of the real shoe — nothing is invented — so the bias
/// is bounded: with [kComebackTries] candidate pairs the hero simply gets the
/// luckiest of a handful of legitimate deals.
library;

import '../models/playing_card.dart';

/// How many candidate two-card hands a comeback deal may choose between.
const int kComebackTries = 3;

/// A hero is "at risk" when the stack covers fewer than this many minimum
/// bets — one or two losses from being felted at this table.
const int kComebackMinBetCover = 6;

/// Trailing losses that mark a losing streak worth softening.
const int kComebackLossStreak = 2;

/// Score used to compare candidate starting hands: natural blackjack beats
/// everything, otherwise the higher total wins (12 for A-A, which still plays
/// well thanks to the split option).
int startingHandScore(List<PlayingCard> pair) {
  final v = BlackjackRules.handValue(pair);
  if (v == 21) return 100;
  return v;
}

/// Removes and returns the hero's two starting cards from the top of [shoe]
/// (the end of the list, matching `removeLast` draws elsewhere).
///
/// Looks at up to [tries] disjoint pairs from the top of the shoe and takes
/// the pair with the best [startingHandScore]; the unused cards stay in the
/// shoe in their original order. With `tries: 1` this is exactly a normal
/// deal, so the same code path serves both fair and comeback deals.
List<PlayingCard> drawStartingPair(List<PlayingCard> shoe, {int tries = 1}) {
  final usable = shoe.length ~/ 2;
  final n = tries.clamp(1, usable == 0 ? 1 : usable);

  var bestIndex = 0;
  var bestScore = -1;
  for (var k = 0; k < n; k++) {
    final a = shoe[shoe.length - 1 - 2 * k];
    final b = shoe[shoe.length - 2 - 2 * k];
    final score = startingHandScore([a, b]);
    if (score > bestScore) {
      bestScore = score;
      bestIndex = k;
    }
  }

  final hi = shoe.length - 1 - 2 * bestIndex;
  final a = shoe.removeAt(hi);
  final b = shoe.removeAt(hi - 1);
  return [a, b];
}
