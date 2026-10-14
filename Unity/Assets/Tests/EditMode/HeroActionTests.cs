using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class HeroActionTests
    {
        [Test]
        public void Hit_pastTwentyOneBustsTheHandAndHandsOverToTheDealer()
        {
            var s = T.Playing(hero: new[] { "10", "6" });
            var next = RoundEngine.Hit(s, T.Stacked("K"));
            Assert.AreEqual(HandStatus.Busted, next.Hands[0].Status);
            Assert.AreEqual(RoundPhase.Dealer, next.Phase);
            Assert.IsTrue(next.HoleRevealed);
        }

        [Test]
        public void Hit_belowTwentyOneKeepsTheHandActive()
        {
            var next = RoundEngine.Hit(T.Playing(hero: new[] { "5", "6" }), T.Stacked("3"));
            Assert.AreEqual(HandStatus.Active, next.Hands[0].Status);
            Assert.AreEqual(RoundPhase.Playing, next.Phase);
        }

        [Test]
        public void Double_takesOneCardDoublesTheBetAndStands()
        {
            var next = RoundEngine.Double(T.Playing(chips: 900, bet: 100, hero: new[] { "5", "6" }), T.Stacked("9"));
            Assert.AreEqual(200, next.Hands[0].Bet);
            Assert.IsTrue(next.Hands[0].Doubled);
            Assert.AreEqual(HandStatus.Stood, next.Hands[0].Status);
            Assert.AreEqual(800, next.Chips);
            Assert.AreEqual(RoundPhase.Dealer, next.Phase);
        }

        [Test]
        public void Double_isRefusedWithoutTheChipsToMatchTheBet()
        {
            var s = T.Playing(chips: 50, bet: 100, hero: new[] { "5", "6" });
            Assert.AreSame(s, RoundEngine.Double(s, T.Stacked("9")));
            Assert.IsFalse(RoundEngine.CanDouble(s));
        }

        [Test]
        public void Split_makesTwoHandsEachWithTheOriginalBetAndPlaysTheFirst()
        {
            var s = T.Playing(chips: 900, bet: 100, hero: new[] { "8", "8" });
            var next = RoundEngine.Split(s, T.Stacked("3", "4"));
            Assert.AreEqual(2, next.Hands.Count);
            Assert.AreEqual(800, next.Chips);
            Assert.AreEqual(0, next.ActiveHandIndex);
            Assert.AreEqual(100, next.Hands[1].Bet);
        }

        [Test]
        public void Split_isRefusedForUnmatchedRanksAndAfterAnEarlierSplit()
        {
            Assert.IsFalse(RoundEngine.CanSplit(T.Playing(hero: new[] { "8", "9" })));
            var split = RoundEngine.Split(T.Playing(chips: 900, hero: new[] { "8", "8" }), T.Stacked("8", "3"));
            Assert.IsFalse(RoundEngine.CanSplit(split));
        }

        [Test]
        public void Standing_onTheFirstSplitHandMovesToTheSecond()
        {
            var split = RoundEngine.Split(T.Playing(chips: 900, hero: new[] { "8", "8" }), T.Stacked("3", "4"));
            var next = RoundEngine.Stand(split);
            Assert.AreEqual(1, next.ActiveHandIndex);
            Assert.AreEqual(RoundPhase.Playing, next.Phase);
        }

        [Test]
        public void Surrender_refundsHalfTheBetAndTheDealerStillPlaysOut()
        {
            var s = T.Playing(chips: 900, bet: 100, hero: new[] { "10", "6" });
            var next = RoundEngine.Surrender(s);
            Assert.AreEqual(950, next.Chips);
            Assert.AreEqual(HandStatus.Surrendered, next.Hands[0].Status);
            Assert.AreEqual(RoundPhase.Dealer, next.Phase);

            var settled = RoundEngine.RunToSettlement(next, T.Stacked(), T.Names);
            Assert.AreEqual(950, settled.Chips);
            Assert.AreEqual(-50, settled.RoundNet);
            Assert.AreEqual(1, settled.Stats.Losses);
        }

        [Test]
        public void Surrender_withAnOddBetRoundsTheRefundDownSoTheHalvesSumToTheBet()
        {
            var s = T.Playing(chips: 975, bet: 25, hero: new[] { "10", "6" });
            var settled = RoundEngine.RunToSettlement(RoundEngine.Surrender(s), T.Stacked(), T.Names);
            Assert.AreEqual(975 + 12, settled.Chips);
            Assert.AreEqual(-13, settled.RoundNet);
        }
    }
}
