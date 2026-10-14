using System;
using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>
    /// The card shoe. Cards are dealt from the end of the list. The shoe is the one mutable object
    /// in the engine — it is a source of randomness, not game state.
    /// </summary>
    public sealed class Shoe
    {
        public const int DeckCount = 6;
        public const int ReshuffleBelow = 15;

        private readonly Random _rng;
        private List<PlayingCard> _cards;

        public Shoe(Random rng)
        {
            _rng = rng;
            _cards = Build(DeckCount, rng);
        }

        /// <summary>A shoe with a fixed order (last element is dealt first), for tests.</summary>
        public Shoe(Random rng, IEnumerable<PlayingCard> stacked)
        {
            _rng = rng;
            _cards = new List<PlayingCard>(stacked);
        }

        public int Count => _cards.Count;

        public static List<PlayingCard> Build(int deckCount, Random rng)
        {
            var shoe = new List<PlayingCard>(deckCount * 52);
            for (var d = 0; d < deckCount; d++)
                foreach (var suit in BlackjackRules.Suits)
                    foreach (var rank in BlackjackRules.Ranks)
                        shoe.Add(new PlayingCard(rank, suit));

            // Fisher–Yates.
            for (var i = shoe.Count - 1; i > 0; i--)
            {
                var j = rng.Next(i + 1);
                (shoe[i], shoe[j]) = (shoe[j], shoe[i]);
            }
            return shoe;
        }

        public void ReshuffleIfLow()
        {
            if (_cards.Count < ReshuffleBelow) _cards = Build(DeckCount, _rng);
        }

        public PlayingCard Draw()
        {
            ReshuffleIfLow();
            var last = _cards.Count - 1;
            var card = _cards[last];
            _cards.RemoveAt(last);
            return card;
        }

        /// <summary>
        /// The hero's two starting cards. Looks at up to <paramref name="tries"/> disjoint pairs from the
        /// top of the shoe and takes the best by <see cref="Comeback.StartingHandScore"/>; unused cards
        /// stay in place. With <c>tries: 1</c> this is a normal deal.
        /// </summary>
        public IReadOnlyList<PlayingCard> DrawStartingPair(int tries)
        {
            var usable = _cards.Count / 2;
            var n = Math.Clamp(tries, 1, usable == 0 ? 1 : usable);

            var bestIndex = 0;
            var bestScore = -1;
            for (var k = 0; k < n; k++)
            {
                var a = _cards[_cards.Count - 1 - 2 * k];
                var b = _cards[_cards.Count - 2 - 2 * k];
                var score = Comeback.StartingHandScore(new[] { a, b });
                if (score > bestScore)
                {
                    bestScore = score;
                    bestIndex = k;
                }
            }

            var hi = _cards.Count - 1 - 2 * bestIndex;
            var first = _cards[hi];
            var second = _cards[hi - 1];
            _cards.RemoveAt(hi);
            _cards.RemoveAt(hi - 1);
            return new[] { first, second };
        }
    }

    /// <summary>Comeback dealing — the retention mechanic. See the Flutter <c>utils/comeback.dart</c>.</summary>
    public static class Comeback
    {
        public const int Tries = 3;
        public const int MinBetCover = 6;
        public const int LossStreak = 2;

        public static int StartingHandScore(IReadOnlyList<PlayingCard> pair)
        {
            var v = BlackjackRules.HandValue(pair);
            return v == 21 ? 100 : v;
        }

        public static int TriesFor(int chips, TableStake stake, IReadOnlyList<RoundResult> history)
        {
            var minBet = stake?.Min ?? TableCatalog.ChipDenoms[0];
            var shortStack = chips < minBet * MinBetCover;
            var losingStreak = history.Count >= LossStreak;
            if (losingStreak)
                for (var i = history.Count - LossStreak; i < history.Count; i++)
                    if (history[i] != RoundResult.Loss) { losingStreak = false; break; }
            return shortStack || losingStreak ? Tries : 1;
        }
    }
}
