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
        public void SeatSlot_placesFirstBaseOnTheRightAndCurvesTowardTheHero()
        {
            var m = FeltMetrics.For(RoundPhase.Playing, true, 0, PhoneWidth, 800f);
            var centre = m.Inset + m.ContentWidth / 2f;
            var maya = m.SeatSlot(0);
            var jordan = m.SeatSlot(1);
            var sam = m.SeatSlot(2);
            var priya = m.SeatSlot(3);

            Assert.AreEqual(1, maya.Side, "first base sits on the dealer's left: the right of the screen");
            Assert.AreEqual(-1, priya.Side);
            Assert.Greater(maya.X, jordan.X, "the curve narrows toward the hero");
            Assert.Less(priya.X, sam.X);
            Assert.Greater(jordan.Y, maya.Y, "seats nearer the hero sit lower on the felt");
            Assert.AreEqual(maya.X - centre, centre - priya.X, 0.01f, "the table is symmetric");
            Assert.Less(maya.Tilt, 0f);
            Assert.Greater(priya.Tilt, 0f);
            for (var i = 0; i < TableCatalog.OpponentSeats; i++)
            {
                var seat = m.SeatSlot(i);
                Assert.GreaterOrEqual(seat.X - FeltMetrics.SeatCardWidth, m.Inset, $"seat {i} stays on the felt");
                Assert.LessOrEqual(seat.X + FeltMetrics.SeatCardWidth, m.Inset + m.ContentWidth, $"seat {i} stays on the felt");
            }
        }

        [Test]
        public void SeatSlot_widensWithTheTable()
        {
            var narrow = FeltMetrics.For(RoundPhase.Playing, true, 0, PhoneWidth, 800f);
            var wide = FeltMetrics.For(RoundPhase.Playing, true, 0, 900f, 900f);
            Assert.Greater(wide.SeatSlot(0).X - wide.SeatSlot(3).X, narrow.SeatSlot(0).X - narrow.SeatSlot(3).X);
        }

        [Test]
        public void CardSizesFollowTheDesignRules()
        {
            Assert.AreEqual(88f, FeltMetrics.HeroCardWidth);
            Assert.LessOrEqual(FeltMetrics.HeroCardWidth / FeltMetrics.CardWidth, 1.4f);
            Assert.AreEqual(FeltMetrics.CardHeight / FeltMetrics.CardWidth, FeltMetrics.HeroCardHeight / FeltMetrics.HeroCardWidth, 0.001f);
            Assert.GreaterOrEqual(FeltMetrics.SeatCardWidth, 42f);
            Assert.GreaterOrEqual(FeltMetrics.SeatCardHeight, 60f);
        }

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

    public class ContrastTests
    {
        private static readonly Rgba White = new Rgba(1, 1, 1);
        private static readonly Rgba Black = new Rgba(0, 0, 0);

        [Test]
        public void Ratio_blackOnWhiteIs21AndEitherOrder() =>
            Assert.AreEqual(21.0, Contrast.Ratio(Black, White), 0.01, "black on white");

        [Test]
        public void Ratio_ofAColourWithItselfIsOne() =>
            Assert.AreEqual(1.0, Contrast.Ratio(Rgba.FromArgb(0xFF175943), Rgba.FromArgb(0xFF175943)), 1e-9);

        [Test]
        public void Ratio_matchesTheWcagReferenceGrey()
        {
            // #767676 is the lightest grey that passes 4.5:1 on white.
            var grey = Rgba.FromArgb(0xFF767676);
            Assert.AreEqual(4.54, Contrast.Ratio(grey, White), 0.01);
            Assert.AreEqual(Contrast.Ratio(grey, White), Contrast.Ratio(White, grey), 1e-12);
        }

        [Test]
        public void Ratio_flagsTheFeltTokensTheRulesReplace()
        {
            var felt = Rgba.FromArgb(0xFF175943);
            Assert.Less(Contrast.Ratio(Rgba.FromArgb(0xFF9AA79E), felt), Contrast.TextMinimum, "TextFaint on Felt");
            Assert.GreaterOrEqual(Contrast.Ratio(Rgba.FromArgb(0xFFCBD4CD), felt), Contrast.TextMinimum, "TextFaintOnFelt");
            Assert.GreaterOrEqual(Contrast.Ratio(Rgba.FromArgb(0xFFFFB4A6), felt), Contrast.TextMinimum, "LoseOnFelt");
        }

        [Test]
        public void Over_blendsByAlphaAndKeepsOpaqueColours()
        {
            var half = Contrast.Over(new Rgba(1, 1, 1, 0.5), Black);
            Assert.AreEqual(0.5, half.R, 1e-9);
            Assert.AreEqual(1.0, half.A, 1e-9);
            Assert.AreEqual(0.2, Contrast.Over(new Rgba(0.2, 0.4, 0.6), White).R, 1e-9);
        }

        [Test]
        public void RatioOver_fadedTextLosesContrast()
        {
            var solid = Contrast.RatioOver(new Rgba(1, 1, 1, 1), Black);
            var faded = Contrast.RatioOver(new Rgba(1, 1, 1, 0.3), Black);
            Assert.AreEqual(21.0, solid, 0.01);
            Assert.Less(faded, solid);
            Assert.AreEqual(1.0, Contrast.RatioOver(new Rgba(1, 1, 1, 0), Black), 1e-9);
        }
    }
}
