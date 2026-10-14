using System;
using System.Collections.Generic;
using System.Linq;

namespace Blackjack.Core.Tests
{
    internal static class T
    {
        public static readonly TableStake Bronze = TableCatalog.Tables[0];
        public static readonly TableStake Vip = TableCatalog.Tables[2];

        public static PlayingCard C(string rank, string suit = "♠") => new PlayingCard(rank, suit);

        public static PlayingCard[] Cards(params string[] ranks) => ranks.Select(r => C(r)).ToArray();

        /// <summary>A shoe whose draws come out in the order given (first listed is dealt first).</summary>
        public static Shoe Stacked(params string[] dealOrder) =>
            new Shoe(new Random(1), PadBelowReshuffle(dealOrder.Reverse().Select(r => C(r))));

        // Keeps the shoe above the reshuffle threshold without disturbing the stacked cards.
        private static IEnumerable<PlayingCard> PadBelowReshuffle(IEnumerable<PlayingCard> top)
        {
            var padding = Enumerable.Repeat(C("2", "♣"), Shoe.ReshuffleBelow + 5);
            return padding.Concat(top);
        }

        public static readonly string[] Names = { "Maya", "Jordan", "Sam", "Priya" };

        public static RoundState Playing(int chips = 1000, int bet = 100, params string[] hero) => new RoundState
        {
            Chips = chips,
            Stake = Bronze,
            Bet = bet,
            Phase = RoundPhase.Playing,
            DealerHand = Cards("10", "7"),
            Hands = new[] { new Hand(Cards(hero), bet) },
        };
    }
}
