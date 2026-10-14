using System;
using System.Collections.Generic;
using System.Linq;

namespace Blackjack.Core
{
    /// <summary>
    /// The blackjack round, ported from the Flutter <c>GameNotifier</c>. Every method is a pure step
    /// from one <see cref="RoundState"/> to the next; pacing (timers, voices, animation) belongs to
    /// the caller. Shoe and RNG are the only side effects.
    /// </summary>
    public static class RoundEngine
    {
        private static readonly int[] NpcBetMultipliers = { 1, 1, 2, 2, 4 };
        private const int HistoryLimit = 10;

        // ---- table entry ------------------------------------------------------------------------

        public static RoundState EnterTable(RoundState s, TableStake stake, Random rng) =>
            FreshRound(s with { Stake = stake }, stake.Min, rng);

        public static RoundState NextHand(RoundState s, Random rng) =>
            FreshRound(s, s.Stake?.Min ?? TableCatalog.ChipDenoms[0], rng);

        private static RoundState FreshRound(RoundState s, int minBet, Random rng) => s with
        {
            Phase = RoundPhase.Betting,
            Bet = 0,
            Hands = new[] { Hand.Empty },
            DealerHand = Array.Empty<PlayingCard>(),
            ActiveHandIndex = 0,
            InsuranceBet = 0,
            HoleRevealed = false,
            ActingSeat = null,
            TurnDeadline = null,
            Message = "",
            MessageType = MessageType.None,
            NpcSeats = RollNpcSeats(minBet, rng),
            SweepAmount = 0,
            RoundNet = 0,
            RoundStake = 0,
            RoundHandNet = 0,
            SweepInfo = null,
        };

        public static IReadOnlyList<NpcSeat> RollNpcSeats(int minBet, Random rng) =>
            Enumerable.Range(0, TableCatalog.OpponentSeats)
                .Select(_ => new NpcSeat(Bet: minBet * NpcBetMultipliers[rng.Next(NpcBetMultipliers.Length)]))
                .ToArray();

        // ---- betting ----------------------------------------------------------------------------

        public static BetResult PlaceBet(RoundState s, int amount)
        {
            if (s.Phase != RoundPhase.Betting) return new BetResult(s);
            if (s.Bet + amount > s.Chips) return new BetResult(s, Rejection.NotEnoughChips);
            if (s.Stake != null && s.Bet + amount > s.Stake.Max)
                return new BetResult(s, Rejection.TableMaximum, s.Stake.Max);
            return new BetResult(s with { Bet = s.Bet + amount });
        }

        public static RoundState ClearBet(RoundState s) => s with { Bet = 0 };

        /// <summary>Bets the whole stack, capped at the table maximum.</summary>
        public static BetResult BetAllIn(RoundState s)
        {
            if (s.Phase != RoundPhase.Betting) return new BetResult(s);
            var amount = s.Stake == null ? s.Chips : Math.Min(s.Chips, s.Stake.Max);
            if (amount <= 0) return new BetResult(s);
            if (s.Stake != null && amount < s.Stake.Min)
                return new BetResult(s, Rejection.TableMinimum, s.Stake.Min);
            return new BetResult(s with { Bet = amount });
        }

        /// <summary>Re-stakes <see cref="RoundState.LastBet"/>. Deal separately with <see cref="Deal"/>.</summary>
        public static BetResult Rebet(RoundState s)
        {
            var last = s.LastBet;
            if (s.Phase != RoundPhase.Betting || last <= 0) return new BetResult(s);
            if (last > s.Chips) return new BetResult(s, Rejection.NotEnoughChips);
            if (s.Stake != null && (last < s.Stake.Min || last > s.Stake.Max)) return new BetResult(s);
            return new BetResult(s with { Bet = last });
        }

        // ---- dealing ----------------------------------------------------------------------------

        public static bool CanDeal(RoundState s) =>
            s.Phase == RoundPhase.Betting
            && s.Bet > 0
            && s.Bet <= s.Chips
            && (s.Stake == null || (s.Bet >= s.Stake.Min && s.Bet <= s.Stake.Max));

        /// <summary>
        /// Deals the round. Returns the state the table is in next: the insurance offer when the dealer
        /// shows an ace, a settled round on a dealer natural, otherwise the seats' turns. A natural on
        /// the hero's side does not end the round — the table plays on so the sweep pot can be won.
        /// </summary>
        public static RoundState Deal(RoundState s, Shoe shoe, IReadOnlyList<string> seatNames)
        {
            if (!CanDeal(s)) return s;
            var bet = s.Bet;
            var withLast = s with { LastBet = bet };

            // Draw order matters for fidelity with the Flutter game: seats, then hero, then dealer.
            var seats = s.NpcSeats
                .Select(n => n with { Cards = new[] { shoe.Draw(), shoe.Draw() }, Action = "", Done = false })
                .ToArray();
            shoe.ReshuffleIfLow();
            var playerCards = shoe.DrawStartingPair(Comeback.TriesFor(s.Chips, s.Stake, s.History));
            var dealerCards = new[] { shoe.Draw(), shoe.Draw() };

            var chips = s.Chips - bet;
            var playerBlackjack = BlackjackRules.HandValue(playerCards) == 21;

            if (dealerCards[0].Rank == "A")
            {
                return withLast with
                {
                    Chips = chips,
                    DealerHand = dealerCards,
                    HoleRevealed = false,
                    NpcSeats = seats,
                    Hands = new[] { new Hand(playerCards, bet) },
                    ActiveHandIndex = 0,
                    Phase = RoundPhase.Insurance,
                    InsuranceBet = bet / 2,
                    Message = "",
                    MessageType = MessageType.None,
                };
            }

            // A dealer natural is the one hand that ends before anybody acts: the seats are never dealt in.
            if (BlackjackRules.HandValue(dealerCards) == 21)
            {
                var revealed = withLast with
                {
                    Chips = chips,
                    DealerHand = dealerCards,
                    HoleRevealed = true,
                    Hands = new[] { new Hand(playerCards, bet, playerBlackjack ? HandStatus.Blackjack : HandStatus.Active) },
                    ActiveHandIndex = 0,
                    Phase = RoundPhase.Dealer,
                };
                return Settlement.Settle(revealed, seatNames);
            }

            var dealt = withLast with
            {
                Chips = chips,
                DealerHand = dealerCards,
                HoleRevealed = false,
                NpcSeats = seats,
                Hands = new[] { new Hand(playerCards, bet, playerBlackjack ? HandStatus.Blackjack : HandStatus.Active) },
                ActiveHandIndex = 0,
                Phase = RoundPhase.Npcs,
                Message = "",
                MessageType = MessageType.None,
                ActingSeat = null,
            };
            return StartNpcTurns(dealt);
        }

        // ---- insurance --------------------------------------------------------------------------

        public static RoundState TakeInsurance(RoundState s, IReadOnlyList<string> seatNames) =>
            ResolveInsurance(s with { Chips = s.Chips - s.InsuranceBet }, seatNames);

        public static RoundState DeclineInsurance(RoundState s, IReadOnlyList<string> seatNames) =>
            ResolveInsurance(s with { InsuranceBet = 0 }, seatNames);

        private static RoundState ResolveInsurance(RoundState s, IReadOnlyList<string> seatNames)
        {
            if (BlackjackRules.HandValue(s.DealerHand) == 21)
                return Settlement.Settle(s with { HoleRevealed = true, Phase = RoundPhase.Dealer }, seatNames);

            var playerBlackjack = BlackjackRules.HandValue(s.Hands[0].Cards) == 21;
            var hands = playerBlackjack
                ? s.Hands.Select(h => h with { Status = HandStatus.Blackjack }).ToArray()
                : s.Hands;
            return StartNpcTurns(s with { Hands = hands });
        }

        // ---- opponent seats ---------------------------------------------------------------------

        /// <summary>The seats that act in <paramref name="phase"/>: first base before the hero, third base after.</summary>
        public static IEnumerable<int> SeatsActingIn(RoundPhase phase, int seatCount)
        {
            var split = Math.Min(TableCatalog.SeatsBeforeHero, seatCount);
            return phase switch
            {
                RoundPhase.Npcs => Enumerable.Range(0, split),
                RoundPhase.NpcsAfter => Enumerable.Range(split, seatCount - split),
                _ => Enumerable.Empty<int>(),
            };
        }

        /// <summary>The first-base seats take their turns, or the hero does straight away when there are none.</summary>
        public static RoundState StartNpcTurns(RoundState s) =>
            SeatsActingIn(RoundPhase.Npcs, s.NpcSeats.Count).Any() ? s with { Phase = RoundPhase.Npcs } : HandOverAfterSeats(s);

        public static RoundState SetActingSeat(RoundState s, int? seat) => s with { ActingSeat = seat };

        /// <summary>One decision for a seat: hit below 17 (busting ends its turn), otherwise stand.</summary>
        public static RoundState NpcAct(RoundState s, Shoe shoe, int seatIndex)
        {
            var seat = s.NpcSeats[seatIndex];
            var value = BlackjackRules.HandValue(seat.Cards);
            NpcSeat next;
            if (value < 17)
            {
                var cards = seat.Cards.Append(shoe.Draw()).ToArray();
                var bust = BlackjackRules.HandValue(cards) > 21;
                next = seat with { Cards = cards, Action = bust ? "BUST" : "HIT", Done = bust };
            }
            else
            {
                next = seat with { Action = "STAND", Done = true };
            }
            return WithSeat(s, seatIndex, next);
        }

        private static RoundState WithSeat(RoundState s, int index, NpcSeat seat)
        {
            var seats = s.NpcSeats.ToArray();
            seats[index] = seat;
            return s with { NpcSeats = seats };
        }

        /// <summary>
        /// Action passes to the hero once the first-base seats have played — unless there is nothing left to
        /// decide (a natural), in which case the third-base seats go next.
        /// </summary>
        public static RoundState HandOverAfterSeats(RoundState s)
        {
            var cleared = s with { ActingSeat = null };
            return cleared.Hands.All(h => h.Status != HandStatus.Active)
                ? AfterHero(cleared)
                : cleared with { Phase = RoundPhase.Playing };
        }

        /// <summary>Once the hero is done the third-base seats play; the dealer goes last.</summary>
        public static RoundState AfterHero(RoundState s) =>
            SeatsActingIn(RoundPhase.NpcsAfter, s.NpcSeats.Count).Any(i => !s.NpcSeats[i].Done)
                ? s with { Phase = RoundPhase.NpcsAfter, ActingSeat = null }
                : BeginDealer(s);

        /// <summary>The third-base seats are done: the dealer turns the hole card.</summary>
        public static RoundState HandOverToDealer(RoundState s) => BeginDealer(s with { ActingSeat = null });

        // ---- hero actions -----------------------------------------------------------------------

        public static RoundState Hit(RoundState s, Shoe shoe)
        {
            var hand = s.ActiveHand;
            var cards = hand.Cards.Append(shoe.Draw()).ToArray();
            var busted = BlackjackRules.HandValue(cards) > 21;
            var next = WithHand(s, hand with { Cards = cards, Status = busted ? HandStatus.Busted : HandStatus.Active });
            return busted ? AdvanceHand(next) : next;
        }

        public static RoundState Stand(RoundState s) =>
            AdvanceHand(WithHand(s, s.ActiveHand with { Status = HandStatus.Stood }));

        public static bool CanDouble(RoundState s) =>
            s.Phase == RoundPhase.Playing && s.ActiveHand.Cards.Count == 2 && s.Chips >= s.ActiveHand.Bet;

        public static RoundState Double(RoundState s, Shoe shoe)
        {
            var hand = s.ActiveHand;
            if (hand.Cards.Count != 2 || s.Chips < hand.Bet) return s;
            var cards = hand.Cards.Append(shoe.Draw()).ToArray();
            var busted = BlackjackRules.HandValue(cards) > 21;
            var doubled = hand with
            {
                Cards = cards,
                Bet = hand.Bet * 2,
                Doubled = true,
                Status = busted ? HandStatus.Busted : HandStatus.Stood,
            };
            return AdvanceHand(WithHand(s, doubled) with { Chips = s.Chips - hand.Bet });
        }

        public static bool CanSplit(RoundState s)
        {
            var hand = s.ActiveHand;
            return s.Phase == RoundPhase.Playing
                && s.Hands.Count == 1
                && hand.Cards.Count == 2
                && hand.Cards[0].Rank == hand.Cards[1].Rank
                && s.Chips >= hand.Bet;
        }

        public static RoundState Split(RoundState s, Shoe shoe)
        {
            if (!CanSplit(s)) return s;
            var hand = s.ActiveHand;
            var a = new Hand(new[] { hand.Cards[0], shoe.Draw() }, hand.Bet);
            var b = new Hand(new[] { hand.Cards[1], shoe.Draw() }, hand.Bet);
            return s with { Hands = new[] { a, b }, ActiveHandIndex = 0, Chips = s.Chips - hand.Bet };
        }

        public static bool CanSurrender(RoundState s) =>
            s.Phase == RoundPhase.Playing && s.Hands.Count == 1 && s.ActiveHand.Cards.Count == 2;

        public static RoundState Surrender(RoundState s)
        {
            if (!CanSurrender(s)) return s;
            var hand = s.ActiveHand;
            var refunded = WithHand(s, hand with { Status = HandStatus.Surrendered }) with { Chips = s.Chips + hand.Bet / 2 };
            return AdvanceHand(refunded);
        }

        private static RoundState WithHand(RoundState s, Hand hand)
        {
            var hands = s.Hands.ToArray();
            hands[s.ActiveHandIndex] = hand;
            return s with { Hands = hands };
        }

        private static RoundState AdvanceHand(RoundState s)
        {
            if (s.ActiveHandIndex < s.Hands.Count - 1) return s with { ActiveHandIndex = s.ActiveHandIndex + 1 };
            if (s.Hands.Any(h => h.Status == HandStatus.Active)) return s;
            // The table always plays out, even if every hero hand surrendered or bust: the seats after the hero
            // still act, and their sweep-pot bets settle against the dealer's final total.
            return AfterHero(s);
        }

        // ---- dealer -----------------------------------------------------------------------------

        public static RoundState BeginDealer(RoundState s) => s with { HoleRevealed = true, Phase = RoundPhase.Dealer };

        public static bool DealerShouldHit(IReadOnlyList<PlayingCard> hand)
        {
            var v = BlackjackRules.HandValue(hand);
            if (v < 17) return true;
            return v == 17 && TableCatalog.DealerHitsSoft17 && BlackjackRules.IsSoft(hand);
        }

        public static RoundState DealerDraw(RoundState s, Shoe shoe) =>
            s with { DealerHand = s.DealerHand.Append(shoe.Draw()).ToArray() };

        /// <summary>Plays every seat that acts in <paramref name="phase"/> to the end of its turn, with no pacing.</summary>
        public static RoundState PlaySeats(RoundState s, Shoe shoe, RoundPhase phase)
        {
            foreach (var i in SeatsActingIn(phase, s.NpcSeats.Count))
                while (!s.NpcSeats[i].Done)
                    s = NpcAct(s, shoe, i);
            return s;
        }

        // ---- synchronous completion (tests, and "nobody is watching") ----------------------------

        /// <summary>Plays any remaining seats and the dealer to the end and settles, with no pacing.</summary>
        public static RoundState RunToSettlement(RoundState s, Shoe shoe, IReadOnlyList<string> seatNames)
        {
            if (s.Phase == RoundPhase.Settlement) return s;
            if (s.Phase == RoundPhase.Insurance || s.Phase == RoundPhase.Betting || s.Phase == RoundPhase.Playing)
                throw new InvalidOperationException($"A decision is pending in phase {s.Phase}.");

            if (s.Phase == RoundPhase.Npcs)
            {
                s = PlaySeats(s, shoe, RoundPhase.Npcs);
                s = HandOverAfterSeats(s);
                if (s.Phase == RoundPhase.Playing)
                    throw new InvalidOperationException("The hero has a decision to make.");
            }
            if (s.Phase == RoundPhase.NpcsAfter) s = HandOverToDealer(PlaySeats(s, shoe, RoundPhase.NpcsAfter));

            while (DealerShouldHit(s.DealerHand)) s = DealerDraw(s, shoe);
            return Settlement.Settle(s with { HoleRevealed = true }, seatNames);
        }
    }
}
