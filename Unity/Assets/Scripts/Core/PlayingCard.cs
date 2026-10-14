using System;
using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>A single playing card, e.g. rank "10" suit "♥".</summary>
    public readonly struct PlayingCard : IEquatable<PlayingCard>
    {
        public string Rank { get; }
        public string Suit { get; }

        public PlayingCard(string rank, string suit)
        {
            Rank = rank;
            Suit = suit;
        }

        public bool IsRed => Suit == "♥" || Suit == "♦";

        public bool Equals(PlayingCard other) => Rank == other.Rank && Suit == other.Suit;
        public override bool Equals(object obj) => obj is PlayingCard other && Equals(other);
        public override int GetHashCode() => HashCode.Combine(Rank, Suit);
        public override string ToString() => Rank + Suit;
    }

    /// <summary>Hand-value helpers, ported 1:1 from the Flutter <c>BlackjackRules</c>.</summary>
    public static class BlackjackRules
    {
        public static readonly string[] Suits = { "♠", "♥", "♦", "♣" };
        public static readonly string[] Ranks = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" };

        public static int RankValue(string rank)
        {
            if (rank == "A") return 11;
            if (rank == "J" || rank == "Q" || rank == "K") return 10;
            return int.Parse(rank);
        }

        public static int HandValue(IReadOnlyList<PlayingCard> cards)
        {
            Tally(cards, out var total, out _);
            return total;
        }

        public static bool IsSoft(IReadOnlyList<PlayingCard> cards)
        {
            Tally(cards, out _, out var softAces);
            return softAces > 0;
        }

        // Counts every ace as 11, then demotes aces to 1 while the hand is over 21.
        private static void Tally(IReadOnlyList<PlayingCard> cards, out int total, out int softAces)
        {
            total = 0;
            softAces = 0;
            foreach (var card in cards)
            {
                if (card.Rank == "A") softAces++;
                total += RankValue(card.Rank);
            }
            while (total > 21 && softAces > 0)
            {
                total -= 10;
                softAces--;
            }
        }
    }
}
