using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class BettingTests
    {
        private static RoundState At(TableStake stake, int chips = 10000) =>
            new RoundState { Chips = chips, Stake = stake };

        [Test]
        public void PlaceBet_addsToTheBet()
        {
            var r = RoundEngine.PlaceBet(At(T.Bronze), 100);
            Assert.IsTrue(r.Accepted);
            Assert.AreEqual(100, r.State.Bet);
        }

        [Test]
        public void PlaceBet_refusesAChipThatWouldPassTheTableMaximum()
        {
            var r = RoundEngine.PlaceBet(At(T.Bronze) with { Bet = 500 }, 25);
            Assert.AreEqual(Rejection.TableMaximum, r.Rejection);
            Assert.AreEqual(500, r.Limit);
            Assert.AreEqual(500, r.State.Bet);
        }

        [Test]
        public void PlaceBet_refusesMoreThanTheStack()
        {
            var r = RoundEngine.PlaceBet(At(T.Bronze, chips: 50), 100);
            Assert.AreEqual(Rejection.NotEnoughChips, r.Rejection);
        }

        [Test]
        public void BetAllIn_isCappedAtTheTableMaximum()
        {
            Assert.AreEqual(500, RoundEngine.BetAllIn(At(T.Bronze)).State.Bet);
            Assert.AreEqual(5000, RoundEngine.BetAllIn(At(T.Vip)).State.Bet);
        }

        [Test]
        public void BetAllIn_refusesWhenTheStackIsBelowTheTableMinimum()
        {
            var r = RoundEngine.BetAllIn(At(T.Vip, chips: 300));
            Assert.AreEqual(Rejection.TableMinimum, r.Rejection);
            Assert.AreEqual(500, r.Limit);
        }

        [Test]
        public void CanDeal_requiresTheBetToReachTheTableMinimum()
        {
            Assert.IsFalse(RoundEngine.CanDeal(At(T.Bronze) with { Bet = 0 }));
            Assert.IsFalse(RoundEngine.CanDeal(At(T.Vip) with { Bet = 100 }), "below the VIP minimum");
            Assert.IsTrue(RoundEngine.CanDeal(At(T.Bronze) with { Bet = 25 }));
            Assert.IsFalse(RoundEngine.CanDeal(At(T.Bronze, chips: 20) with { Bet = 25 }));
        }

        [Test]
        public void Rebet_restakesTheLastBetWhenItStillFits()
        {
            var s = At(T.Bronze) with { LastBet = 100 };
            Assert.AreEqual(100, RoundEngine.Rebet(s).State.Bet);
            Assert.AreEqual(Rejection.NotEnoughChips, RoundEngine.Rebet(s with { Chips = 50 }).Rejection);
            Assert.AreEqual(0, RoundEngine.Rebet(s with { LastBet = 0 }).State.Bet);
        }
    }
}
