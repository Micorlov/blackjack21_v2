import 'enums.dart';
import 'playing_card.dart';

class Hand {
  final List<PlayingCard> cards;
  final int bet;
  final HandStatus status;
  final bool doubled;

  const Hand({this.cards = const [], this.bet = 0, this.status = HandStatus.active, this.doubled = false});

  Hand copyWith({List<PlayingCard>? cards, int? bet, HandStatus? status, bool? doubled}) {
    return Hand(
      cards: cards ?? this.cards,
      bet: bet ?? this.bet,
      status: status ?? this.status,
      doubled: doubled ?? this.doubled,
    );
  }
}
