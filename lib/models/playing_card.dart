import 'dart:math';

/// A single playing card, e.g. rank '10' suit '♥'.
class PlayingCard {
  final String rank;
  final String suit;

  const PlayingCard({required this.rank, required this.suit});

  bool get isRed => suit == '♥' || suit == '♦';

  @override
  bool operator ==(Object other) => other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);
}

/// Blackjack shoe + hand-value helpers, ported 1:1 from the design's JS logic.
class BlackjackRules {
  BlackjackRules._();

  static const List<String> suits = ['♠', '♥', '♦', '♣'];
  static const List<String> ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

  static List<PlayingCard> buildShoe(int deckCount, Random rng) {
    final shoe = <PlayingCard>[];
    for (var d = 0; d < deckCount; d++) {
      for (final suit in suits) {
        for (final rank in ranks) {
          shoe.add(PlayingCard(rank: rank, suit: suit));
        }
      }
    }
    shoe.shuffle(rng);
    return shoe;
  }

  static int _rankValue(String rank) {
    if (rank == 'A') return 11;
    if (rank == 'J' || rank == 'Q' || rank == 'K') return 10;
    return int.parse(rank);
  }

  static int handValue(List<PlayingCard> cards) {
    var total = 0;
    var aces = 0;
    for (final c in cards) {
      if (c.rank == 'A') aces++;
      total += _rankValue(c.rank);
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  static bool isSoft(List<PlayingCard> cards) {
    var total = 0;
    var aces = 0;
    for (final c in cards) {
      if (c.rank == 'A') aces++;
      total += _rankValue(c.rank);
    }
    var a = aces;
    while (total > 21 && a > 0) {
      total -= 10;
      a--;
    }
    return a > 0;
  }
}
