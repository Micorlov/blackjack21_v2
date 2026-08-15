import 'game_state.dart';
import 'playing_card.dart';
import 'social_models.dart';

/// The live "closest to 21" sweep pot, as shown on the pill above the dealer
/// and spoken aloud once every opponent seat has played.
///
/// Only forfeited bets count. Until a seat busts or loses to a revealed dealer
/// hand there is nothing to sweep, and the pot is empty — the pill says so
/// rather than quoting the chips still sitting in front of the players, and the
/// call-out stays silent. Both surfaces read from here so they can never
/// disagree about what the pot is.
class TablePot {
  const TablePot(this.amount);

  /// The forfeited chips up for grabs — 0 while every seat is still in.
  final int amount;

  /// Whether there is a sweep pot at all.
  bool get isSweep => amount > 0;

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
    return TablePot(sweep);
  }
}
