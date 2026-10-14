namespace Blackjack.Core
{
    /// <summary>
    /// The live "closest to 21" sweep pot shown above the dealer. Only forfeited bets count — until a
    /// seat busts or loses to a revealed dealer hand there is nothing to sweep and the pot is empty.
    /// </summary>
    public readonly struct TablePot
    {
        public int Amount { get; }
        public TablePot(int amount) => Amount = amount;

        public bool IsSweep => Amount > 0;

        /// <summary>
        /// Whether the seat has already forfeited its bet. <paramref name="dealerShown"/> is the dealer's
        /// total once revealed, or null while the hole card is down — then only a bust settles a seat early.
        /// </summary>
        public static bool SeatLost(NpcSeat seat, int? dealerShown)
        {
            var value = BlackjackRules.HandValue(seat.Cards);
            if (value > 21) return true;
            if (dealerShown.HasValue) return dealerShown.Value <= 21 && value <= dealerShown.Value;
            return false;
        }

        public static TablePot Live(RoundState s)
        {
            int? dealerShown = s.HoleRevealed ? BlackjackRules.HandValue(s.DealerHand) : (int?)null;
            var sweep = 0;
            foreach (var seat in s.NpcSeats)
            {
                if (seat.Cards.Count == 0) continue;
                if (SeatLost(seat, dealerShown)) sweep += seat.Bet;
            }
            return new TablePot(sweep);
        }
    }
}
