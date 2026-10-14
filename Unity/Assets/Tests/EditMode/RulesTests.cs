using System;
using System.Linq;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class RulesTests
    {
        [TestCase(new[] { "A", "K" }, 21)]
        [TestCase(new[] { "A", "A" }, 12)]
        [TestCase(new[] { "A", "A", "9" }, 21)]
        [TestCase(new[] { "K", "Q", "5" }, 25)]
        [TestCase(new[] { "A", "6", "10" }, 17)]
        public void HandValue_demotesAcesOnlyWhenOver21(string[] ranks, int expected) =>
            Assert.AreEqual(expected, BlackjackRules.HandValue(T.Cards(ranks)));

        [Test]
        public void IsSoft_trueOnlyWhileAnAceStillCountsEleven()
        {
            Assert.IsTrue(BlackjackRules.IsSoft(T.Cards("A", "6")));
            Assert.IsFalse(BlackjackRules.IsSoft(T.Cards("A", "6", "10")));
            Assert.IsFalse(BlackjackRules.IsSoft(T.Cards("10", "7")));
        }

        [Test]
        public void Shoe_holdsSixShuffledDecks()
        {
            Assert.AreEqual(6 * 52, new Shoe(new Random(7)).Count);
            var cards = Shoe.Build(Shoe.DeckCount, new Random(7));
            Assert.AreEqual(6, cards.Count(c => c.Rank == "A" && c.Suit == "♠"));
            Assert.AreEqual(24, cards.Count(c => c.Rank == "10"));
        }

        [Test]
        public void Shoe_reshufflesWhenFewerThan15CardsRemain()
        {
            var shoe = new Shoe(new Random(3), Enumerable.Repeat(T.C("5"), 14));
            shoe.Draw();
            Assert.AreEqual(6 * 52 - 1, shoe.Count);
        }

        [Test]
        public void ChipDenomsFor_dropsChipsAboveTheTableMaximum()
        {
            CollectionAssert.AreEqual(new[] { 25, 50, 100, 500 }, TableCatalog.ChipDenomsFor(T.Bronze));
            CollectionAssert.AreEqual(TableCatalog.ChipDenoms, TableCatalog.ChipDenomsFor(T.Vip));
        }

        [Test]
        public void FormatChips_groupsThousands()
        {
            Assert.AreEqual("1,250", TableCatalog.FormatChips(1250));
            Assert.AreEqual("-1,000,000", TableCatalog.FormatChips(-1000000));
            Assert.AreEqual("25", TableCatalog.FormatChips(25));
        }
    }

    public class ComebackTests
    {
        [Test]
        public void DrawStartingPair_withOneTry_takesTheTopTwo()
        {
            var shoe = T.Stacked("5", "6", "K", "A");
            var pair = shoe.DrawStartingPair(1);
            CollectionAssert.AreEqual(T.Cards("5", "6"), pair);
        }

        [Test]
        public void DrawStartingPair_withThreeTries_prefersANatural()
        {
            var shoe = T.Stacked("2", "3", "4", "5", "A", "K");
            var pair = shoe.DrawStartingPair(3);
            Assert.AreEqual(21, BlackjackRules.HandValue(pair));
        }

        [Test]
        public void TriesFor_isThreeForAShortStackOrALosingStreakElseOne()
        {
            var none = Array.Empty<RoundResult>();
            Assert.AreEqual(1, Comeback.TriesFor(5000, T.Bronze, none));
            Assert.AreEqual(3, Comeback.TriesFor(100, T.Bronze, none), "under six minimum bets");
            var twoLosses = new[] { RoundResult.Win, RoundResult.Loss, RoundResult.Loss };
            Assert.AreEqual(3, Comeback.TriesFor(5000, T.Bronze, twoLosses));
            var mixed = new[] { RoundResult.Loss, RoundResult.Push };
            Assert.AreEqual(1, Comeback.TriesFor(5000, T.Bronze, mixed));
        }
    }
}
