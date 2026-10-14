using System;
using System.Linq;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    /// <summary>The Flutter blackjack_sweep_test and friends, replayed against the C# engine.</summary>
    public class RoundFlowTests
    {
        private static readonly NpcSeat BustedSeat = new NpcSeat(100, T.Cards("10", "9", "3"));

        private static RoundState InsuranceDecision(params NpcSeat[] seats) => new RoundState
        {
            Chips = 900,
            Stake = T.Bronze,
            Bet = 100,
            Phase = RoundPhase.Insurance,
            DealerHand = new[] { T.C("A", "♣"), T.C("6", "♦") },
            Hands = new[] { new Hand(new[] { T.C("A"), T.C("K", "♦") }, 100) },
            InsuranceBet = 50,
            NpcSeats = seats,
        };

        [Test]
        public void ANaturalPlaysTheTableOutAndTakesTheSweepPot()
        {
            var shoe = T.Stacked();
            var afterInsurance = RoundEngine.DeclineInsurance(InsuranceDecision(BustedSeat), T.Names);

            Assert.AreEqual(RoundPhase.Npcs, afterInsurance.Phase, "a natural must let the seats play");
            Assert.AreEqual(HandStatus.Blackjack, afterInsurance.Hands.Single().Status);

            var settled = RoundEngine.RunToSettlement(afterInsurance, shoe, T.Names);

            Assert.GreaterOrEqual(BlackjackRules.HandValue(settled.DealerHand), 17);
            Assert.AreEqual(100, settled.SweepAmount);
            Assert.IsTrue(settled.SweepInfo.HeroTook);
            // 900 on the felt + the 100 bet back + 150 at 3:2 + the 100 sweep pot.
            Assert.AreEqual(1250, settled.Chips);
            Assert.AreEqual(250, settled.RoundNet);
            Assert.AreEqual("Blackjack — you sweep", settled.Message);
            Assert.AreEqual(1, settled.Stats.Blackjacks);
        }

        [Test]
        public void ANaturalWithNoSeatToSweepIsStillCalledByName()
        {
            var afterInsurance = RoundEngine.DeclineInsurance(InsuranceDecision(), T.Names);
            Assert.AreEqual(RoundPhase.Dealer, afterInsurance.Phase, "nothing to decide, dealer takes over");

            var settled = RoundEngine.RunToSettlement(afterInsurance, T.Stacked(), T.Names);
            Assert.AreEqual("Blackjack! You win", settled.Message);
            Assert.AreEqual(0, settled.SweepAmount);
            Assert.AreEqual(1150, settled.Chips, "900 + the 100 bet back + 150 at 3:2");
        }

        [Test]
        public void DealerNatural_pays_insuranceTwoToOne_andSkipsTheSeats()
        {
            var s = InsuranceDecision(BustedSeat) with
            {
                DealerHand = new[] { T.C("A", "♣"), T.C("K", "♦") },
                Hands = new[] { new Hand(T.Cards("10", "9"), 100) },
            };
            var settled = RoundEngine.TakeInsurance(s, T.Names);

            Assert.AreEqual(RoundPhase.Settlement, settled.Phase);
            // 900 - 50 insurance + 150 insurance payout (stake back + 2:1); the hand loses its 100.
            Assert.AreEqual(1000, settled.Chips);
            Assert.AreEqual(0, settled.RoundNet, "insurance exactly covers the lost hand");
            Assert.AreEqual("Dealer has blackjack", settled.Message);
        }

        [Test]
        public void Deal_withADealerAce_offersInsuranceForHalfTheBet()
        {
            var s = new RoundState { Chips = 1000, Stake = T.Bronze, Bet = 100, NpcSeats = RoundEngine.RollNpcSeats(25, new Random(1)) };
            // Draw order: four seats x2 (8 cards), hero pair (2), dealer (2).
            var shoe = T.Stacked("2", "3", "2", "3", "2", "3", "2", "3", "9", "8", "A", "5");
            var dealt = RoundEngine.Deal(s, shoe, T.Names);

            Assert.AreEqual(RoundPhase.Insurance, dealt.Phase);
            Assert.AreEqual(50, dealt.InsuranceBet);
            Assert.AreEqual(900, dealt.Chips);
            Assert.AreEqual(100, dealt.LastBet);
        }

        [Test]
        public void Deal_refusesABetOutsideTheTableLimits()
        {
            var s = new RoundState { Chips = 5000, Stake = T.Vip, Bet = 100 };
            Assert.AreSame(s, RoundEngine.Deal(s, T.Stacked(), T.Names));
        }

        [Test]
        public void Deal_alwaysLandsInAKnownPhaseAndTakesTheBetOffTheStack()
        {
            var rng = new Random(42);
            for (var i = 0; i < 300; i++)
            {
                var s = new RoundState { Chips = 5000, Stake = T.Bronze, Bet = 25, NpcSeats = RoundEngine.RollNpcSeats(25, rng) };
                var dealt = RoundEngine.Deal(s, new Shoe(rng), T.Names);

                CollectionAssert.Contains(
                    new[] { RoundPhase.Insurance, RoundPhase.Npcs, RoundPhase.Dealer, RoundPhase.Settlement }, dealt.Phase);
                if (dealt.Phase != RoundPhase.Settlement) Assert.AreEqual(4975, dealt.Chips);
            }
        }

        [Test]
        public void ARandomRoundAlwaysSettlesAndConservesChips()
        {
            var rng = new Random(2024);
            var shoe = new Shoe(rng);
            var state = new RoundState { Chips = 100000, Stake = T.Bronze };
            state = RoundEngine.EnterTable(state, T.Bronze, rng);

            for (var round = 0; round < 500; round++)
            {
                state = RoundEngine.PlaceBet(state, 100).State;
                state = RoundEngine.Deal(state, shoe, T.Names);
                state = PlayHero(state, shoe);
                state = RoundEngine.RunToSettlement(state, shoe, T.Names);
                Assert.AreEqual(RoundPhase.Settlement, state.Phase);
                Assert.GreaterOrEqual(state.Chips, 0);
                state = RoundEngine.NextHand(state, rng);
            }
            Assert.AreEqual(500, state.Stats.HandsPlayed);
        }

        // Resolves insurance and the hero's decisions with a basic strategy of "stand on 17+".
        private static RoundState PlayHero(RoundState s, Shoe shoe)
        {
            if (s.Phase == RoundPhase.Insurance) s = RoundEngine.DeclineInsurance(s, T.Names);
            if (s.Phase == RoundPhase.Npcs)
            {
                for (var i = 0; i < s.NpcSeats.Count; i++)
                    while (!s.NpcSeats[i].Done) s = RoundEngine.NpcAct(s, shoe, i);
                s = RoundEngine.HandOverAfterSeats(s);
            }
            while (s.Phase == RoundPhase.Playing)
            {
                s = BlackjackRules.HandValue(s.ActiveHand.Cards) >= 17
                    ? RoundEngine.Stand(s)
                    : RoundEngine.Hit(s, shoe);
            }
            return s;
        }
    }
}
