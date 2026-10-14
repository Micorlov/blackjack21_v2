using System.Linq;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class SettlementTests
    {
        private static RoundState Settled(string[] hero, string[] dealer, int bet = 100, int chips = 900, params NpcSeat[] seats) =>
            Settlement.Settle(new RoundState
            {
                Chips = chips,
                Stake = T.Bronze,
                Phase = RoundPhase.Dealer,
                HoleRevealed = true,
                DealerHand = T.Cards(dealer),
                Hands = new[] { new Hand(T.Cards(hero), bet, HandStatus.Stood) },
                NpcSeats = seats,
            }, T.Names);

        [Test]
        public void SplitHands_takeTheSweep_includingSeatsThatActedAfterTheHero()
        {
            var s = Settlement.Settle(new RoundState
            {
                Chips = 800, Stake = T.Bronze, Phase = RoundPhase.Dealer, HoleRevealed = true,
                DealerHand = T.Cards("10", "7"),
                Hands = new[] { new Hand(T.Cards("10", "9"), 100, HandStatus.Stood), new Hand(T.Cards("10", "6"), 100, HandStatus.Stood) },
                NpcSeats = new[]
                {
                    new NpcSeat(50, T.Cards("10", "8"), "STAND", true),       // first base, beats the dealer
                    new NpcSeat(50, T.Cards("10", "7"), "STAND", true),       // first base, ties: a push, keeps the bet
                    new NpcSeat(25, T.Cards("10", "5", "9"), "BUST", true),   // third base, acted after the hero
                    new NpcSeat(100, T.Cards("10", "6"), "STAND", true),      // third base, under the dealer
                },
            }, T.Names);

            Assert.AreEqual(125, s.SweepAmount, "25 + 100 forfeited; the tie is a push");
            Assert.IsTrue(s.SweepInfo.HeroTook, "19 beats the best surviving seat (18)");
            Assert.AreEqual(800 + 200 + 125, s.Chips, "one hand wins, one loses, plus the pot");
            Assert.AreEqual(125, s.RoundNet);
            CollectionAssert.AreEquivalent(new[] { "Sam", "Priya" }, s.SweepInfo.Contributors.Select(c => c.Name));
        }

        [Test]
        public void BotPush_keepsItsBet_outOfTheSweepPot()
        {
            // Bronze hand 3: hero blackjack, dealer 18, Maya stands on 18 (a push).
            var s = Settled(new[] { "A", "K" }, new[] { "10", "8" }, 25, 975,
                new NpcSeat(50, T.Cards("3", "8", "7"), "STAND", true));

            Assert.AreEqual(0, s.SweepAmount, "a push is not a forfeit");
            Assert.IsNull(s.SweepInfo);
            Assert.AreEqual(975 + 25 + 37, s.Chips, "blackjack pays 3:2 on $25, rounded down");
        }

        [Test]
        public void Win_paysEvenMoney()
        {
            var s = Settled(new[] { "10", "9" }, new[] { "10", "7" });
            Assert.AreEqual(1100, s.Chips);
            Assert.AreEqual(100, s.RoundNet);
            Assert.AreEqual("You win!", s.Message);
            Assert.AreEqual(MessageType.Win, s.MessageType);
            Assert.AreEqual(1, s.Stats.CurrentStreak);
        }

        [Test]
        public void DealerBust_paysEveryLiveHand()
        {
            var s = Settled(new[] { "10", "2" }, new[] { "10", "6", "9" });
            Assert.AreEqual(1100, s.Chips);
        }

        [Test]
        public void Push_returnsTheBet()
        {
            var s = Settled(new[] { "10", "7" }, new[] { "9", "8" });
            Assert.AreEqual(1000, s.Chips);
            Assert.AreEqual("Push", s.Message);
            Assert.AreEqual(MessageType.Push, s.MessageType);
        }

        [Test]
        public void Loss_forfeitsTheBet_andResetsTheStreak()
        {
            var s = Settled(new[] { "10", "6" }, new[] { "10", "9" });
            Assert.AreEqual(900, s.Chips);
            Assert.AreEqual(-100, s.RoundNet);
            Assert.AreEqual("Dealer wins", s.Message);
            Assert.AreEqual(0, s.Stats.CurrentStreak);
        }

        [Test]
        public void Blackjack_paysThreeToTwo_roundedDown()
        {
            var s = Settled(new[] { "A", "K" }, new[] { "10", "7" }, bet: 25, chips: 975);
            Assert.AreEqual(975 + 25 + 37, s.Chips);
        }

        [Test]
        public void ATwentyOneBuiltFromThreeCardsIsNotANatural()
        {
            var s = Settled(new[] { "7", "7", "7" }, new[] { "A", "K" });
            Assert.AreEqual("Dealer has blackjack", s.Message);
            Assert.AreEqual(900, s.Chips);
        }

        [Test]
        public void SweepPot_goesToTheHeroWhenTheyHaveTheBestLiveHand()
        {
            var seats = new[]
            {
                new NpcSeat(75, T.Cards("10", "9", "5")),   // bust
                new NpcSeat(50, T.Cards("10", "8")),        // 18 loses to dealer's 19
            };
            var s = Settled(new[] { "K", "Q" }, new[] { "10", "9" }, 100, 900, seats);
            Assert.AreEqual(125, s.SweepAmount);
            Assert.IsTrue(s.SweepInfo.HeroTook);
            Assert.AreEqual(1000 + 100 + 125, s.Chips);
            Assert.AreEqual("You sweep the table", s.Message);
            Assert.AreEqual(2, s.SweepInfo.Contributors.Count);
            Assert.AreEqual("bust", s.SweepInfo.Contributors[0].Reason);
            Assert.AreEqual("lost", s.SweepInfo.Contributors[1].Reason);
        }

        [Test]
        public void SweepPot_staysWithASeatThatOutranksTheHero()
        {
            var seats = new[]
            {
                new NpcSeat(75, T.Cards("10", "9", "5")),   // bust, forfeits 75
                new NpcSeat(50, T.Cards("K", "Q")),         // 20 beats the dealer's 19 and the hero's 20 ties it
            };
            var s = Settled(new[] { "K", "9" }, new[] { "10", "7" }, 100, 900, seats);
            // Hero 19 beats the dealer's 17, but the 20 seat outranks them: no sweep.
            Assert.AreEqual(0, s.SweepAmount);
            Assert.IsFalse(s.SweepInfo.HeroTook);
            Assert.AreEqual(75, s.SweepInfo.Pot);
            Assert.AreEqual("Jordan", s.SweepInfo.Winner);
            Assert.AreEqual(1100, s.Chips, "the hero still wins their own hand");
        }

        [Test]
        public void NoForfeits_meansNoSweepInfo()
        {
            var seats = new[] { new NpcSeat(50, T.Cards("4", "9", "8")) };   // 21 beats the dealer's 17
            var s = Settled(new[] { "K", "Q" }, new[] { "10", "7" }, 100, 900, seats);
            Assert.IsNull(s.SweepInfo);
            Assert.AreEqual(0, s.SweepAmount);
        }

        [Test]
        public void History_keepsOnlyTheLastTenResults()
        {
            var history = new RoundResult[10];
            for (var i = 0; i < 10; i++) history[i] = RoundResult.Win;
            var s = Settlement.Settle(new RoundState
            {
                Phase = RoundPhase.Dealer,
                DealerHand = T.Cards("10", "9"),
                Hands = new[] { new Hand(T.Cards("10", "6"), 100, HandStatus.Stood) },
                History = history,
            }, T.Names);
            Assert.AreEqual(10, s.History.Count);
            Assert.AreEqual(RoundResult.Loss, s.History[9]);
        }
    }

    public class TablePotTests
    {
        [Test]
        public void Live_countsOnlyBustsWhileTheHoleCardIsDown()
        {
            var s = new RoundState
            {
                DealerHand = T.Cards("6", "10"),
                HoleRevealed = false,
                NpcSeats = new[]
                {
                    new NpcSeat(50, T.Cards("4", "9", "8")),     // 21, still in
                    new NpcSeat(75, T.Cards("10", "9", "5")),    // bust
                },
            };
            Assert.AreEqual(75, TablePot.Live(s).Amount);
        }

        [Test]
        public void Live_isEmptyWhenEverySeatIsStillIn()
        {
            var s = new RoundState
            {
                DealerHand = T.Cards("6", "10"),
                NpcSeats = new[] { new NpcSeat(50, T.Cards("4", "9", "8")) },
            };
            Assert.IsFalse(TablePot.Live(s).IsSweep);
        }

        [Test]
        public void Live_onceRevealed_chargesSeatsBelowTheDealer_andNotTies()
        {
            var s = new RoundState
            {
                DealerHand = T.Cards("10", "7"),
                HoleRevealed = true,
                NpcSeats = new[]
                {
                    new NpcSeat(50, T.Cards("10", "7")),   // ties 17 -> push, not charged
                    new NpcSeat(60, T.Cards("10", "8")),   // 18 beats 17
                    new NpcSeat(40, T.Cards("10", "6")),   // 16 loses
                },
            };
            Assert.AreEqual(40, TablePot.Live(s).Amount);
            Assert.IsTrue(TablePot.SeatPushed(s.NpcSeats[0], 17));
            Assert.IsFalse(TablePot.SeatLost(s.NpcSeats[0], 17));
        }
    }
}
