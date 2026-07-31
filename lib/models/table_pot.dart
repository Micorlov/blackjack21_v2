import 'game_state.dart';
import 'playing_card.dart';
import 'social_models.dart';

/// The live "closest to 21" pot figure, as shown on the pill above the dealer
/// and spoken aloud once every opponent seat has played.
///
/// One pill carries two different figures. Before any seat has forfeited a bet
/// it shows every chip on the table; the moment a seat busts or loses to a
/// revealed dealer hand it switches to the sweep pot actually up for grabs.
/// Both the pill and the spoken call-out read from here so they can never
/// disagree about what the pot is.
class TablePot {
  const TablePot({required this.amount, required this.isSweep});

  final int amount;

  /// Whether [amount] is the forfeited sweep pot rather than the whole table.
  final bool isSweep;

  /// Whether [seat] has already forfeited its bet. [dealerShown] is the
  /// dealer's total once revealed, or null while the hole card is face down —
  /// with it hidden, only a bust can settle a seat early.
  static bool seatLost(NpcSeat seat, int? dealerShown) {
    final value = BlackjackRules.handValue(seat.cards);
    if (value > 21) return true;
    if (dealerShown != null) return dealerShown <= 21 && value <= dealerShown;
    return false;
  }

  static TablePot live(GameState s) {
    final dealerShown =
        s.holeRevealed ? BlackjackRules.handValue(s.dealerHand) : null;

    var sweep = 0;
    for (final seat in s.npcSeats) {
      if (seat.cards.isEmpty) continue;
      if (seatLost(seat, dealerShown)) sweep += seat.bet;
    }
    if (sweep > 0) return TablePot(amount: sweep, isSweep: true);

    var table = 0;
    for (final seat in s.npcSeats) {
      table += seat.bet;
    }
    return TablePot(amount: table + heroBet(s), isSweep: false);
  }

  /// The hero's stake this round. A dealt hand carries its own bet; before the
  /// deal only the pending [GameState.bet] is set.
  static int heroBet(GameState s) {
    if (s.hands.isEmpty) return s.bet;
    return s.hands.first.bet != 0 ? s.hands.first.bet : s.bet;
  }
}
