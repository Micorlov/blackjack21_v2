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

namespace Blackjack.Core.Tests
{
    public class FeltMetricsTests
    {
        private const float PhoneWidth = 384f;

        [Test]
        public void BettingPhaseIsDrawnAtFullScaleOnTheTargetPhone() =>
            Assert.AreEqual(1f, FeltMetrics.For(RoundPhase.Betting, false, 0, PhoneWidth, 388f).Scale);

        [Test]
        public void ThePlayedHandStaysNearFullScale() =>
            Assert.GreaterOrEqual(FeltMetrics.For(RoundPhase.Playing, true, 0, PhoneWidth, 475f).Scale, 0.85f);

        [Test]
        public void TheSettledFeltStaysReadableUnderTheResultCard() =>
            Assert.GreaterOrEqual(FeltMetrics.For(RoundPhase.Settlement, true, 300, PhoneWidth, 269f).Scale, 0.65f);

        [Test]
        public void SeatSlotsKeepTheirHeightInEveryPhase()
        {
            var betting = FeltMetrics.For(RoundPhase.Betting, false, 0, PhoneWidth, 800f);
            var playing = FeltMetrics.For(RoundPhase.Playing, true, 0, PhoneWidth, 800f);
            var settled = FeltMetrics.For(RoundPhase.Settlement, true, 0, PhoneWidth, 800f);
            Assert.AreEqual(betting.SeatHeight, playing.SeatHeight);
            Assert.AreEqual(betting.SeatHeight, settled.SeatHeight);
            Assert.AreEqual(betting.SeatRowPitch, playing.SeatRowPitch);
        }

        [Test]
        public void TheHeroBlockStartsWhereTheLowerSeatRowEnds()
        {
            var m = FeltMetrics.For(RoundPhase.Playing, true, 0, PhoneWidth, 800f);
            Assert.AreEqual(m.SeatTopOf(1) + m.SeatHeight + FeltMetrics.SeatBandGap, m.HeroTop, 0.001f);
        }

        [Test]
        public void WhenHeightWinsTheCanvasIsExactlyTheRequiredHeight()
        {
            var m = FeltMetrics.For(RoundPhase.Playing, true, 0, 320f, 279f);
            Assert.Less(m.Scale, 1f);
            Assert.AreEqual(279f, m.CanvasHeight * m.Scale, 0.01f);
            Assert.Less(m.HeroTop, m.CanvasHeight);
        }

        [Test]
        public void DealerCardsFanTighterWhenTheyWouldOverflow()
        {
            Assert.AreEqual(72f, FeltMetrics.DealerCardStep(3, 384f));
            Assert.Less(FeltMetrics.DealerCardStep(8, 300f), 72f);
            Assert.GreaterOrEqual(FeltMetrics.DealerCardStep(12, 100f), 20f);
        }

        [Test]
        public void WideScreensCapTheContentAndCentreIt()
        {
            var m = FeltMetrics.For(RoundPhase.Betting, false, 0, 1200f, 900f);
            Assert.LessOrEqual(m.ContentWidth, FeltMetrics.MaxContentWidth);
            Assert.Greater(m.Inset, 0f);
        }
    }
}
