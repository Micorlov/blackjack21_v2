using System.Linq;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class SpokenAmountTests
    {
        [TestCase(7, "seven")]
        [TestCase(16, "sixteen")]
        [TestCase(20, "twenty")]
        [TestCase(21, "twenty one")]
        [TestCase(100, "one hundred")]
        [TestCase(125, "one hundred twenty five")]
        [TestCase(1000, "one thousand")]
        [TestCase(5250, "five thousand two hundred fifty")]
        [TestCase(999999, "nine hundred ninety nine thousand nine hundred ninety nine")]
        public void Words_saysTheNumber(int amount, string expected) =>
            Assert.AreEqual(expected, string.Join(" ", SpokenAmount.Words(amount)));

        [TestCase(0)]
        [TestCase(-5)]
        [TestCase(1000000)]
        public void Words_isEmptyOutOfRange(int amount) => Assert.IsEmpty(SpokenAmount.Words(amount));
    }

    public class TutorialTests
    {
        [Test]
        public void TipFor_insuranceIsTheSameInEveryLesson()
        {
            for (var lesson = 0; lesson < Tutorial.Rounds; lesson++)
                Assert.AreEqual("coachInsuranceBody", Tutorial.TipFor(lesson, RoundPhase.Insurance).BodyKey);
        }

        [Test]
        public void Active_isQuietWhenDismissedOffTheTableOrFinished()
        {
            Assert.IsNull(Tutorial.Active(true, true, 0, RoundPhase.Betting));
            Assert.IsNull(Tutorial.Active(false, false, 0, RoundPhase.Betting));
            Assert.IsNull(Tutorial.Active(false, true, Tutorial.Rounds, RoundPhase.Betting));
            Assert.IsNotNull(Tutorial.Active(false, true, 0, RoundPhase.Betting));
        }

        [Test]
        public void TipFor_hasNoCardForAPhaseTheLessonSkips()
        {
            Assert.IsNull(Tutorial.TipFor(1, RoundPhase.Npcs));
            Assert.IsNull(Tutorial.TipFor(2, RoundPhase.Dealer));
        }

        [Test]
        public void TipFor_theBettingCardQuotesTheTableMinimum() =>
            Assert.IsTrue(Tutorial.TipFor(0, RoundPhase.Betting).UsesMinimum);

        [Test]
        public void ResultKey_mapsEveryHeadlineTheEngineProduces()
        {
            foreach (var headline in new[]
            {
                "Dealer has blackjack", "Blackjack! You win", "You win!", "Dealer wins", "Push",
                "Blackjack — you sweep", "You sweep the table",
            })
                Assert.IsNotNull(Guide.ResultKey(headline), headline);
        }
    }

    public class SavedGameTests
    {
        [Test]
        public void TrimmedHistory_keepsTheNewestFifty()
        {
            var history = Enumerable.Range(0, 60).Select(i => i < 10 ? RoundResult.Loss : RoundResult.Win).ToArray();
            var trimmed = new SavedGame { History = history }.TrimmedHistory;
            Assert.AreEqual(50, trimmed.Count);
            Assert.IsTrue(trimmed.All(r => r == RoundResult.Win));
        }
    }
}
