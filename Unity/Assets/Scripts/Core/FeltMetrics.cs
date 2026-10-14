using System;

namespace Blackjack.Core
{
    /// <summary>
    /// The felt's vertical budget and scale, ported from the Flutter <c>FeltMetrics</c>. The felt is drawn on
    /// a virtual canvas in fixed units and scaled uniformly to the room it is given; the bands are sized so a
    /// 384x832 phone draws every phase at full scale.
    /// </summary>
    public sealed record FeltMetrics
    {
        public const float ReferenceWidth = 384f;
        public const float MaxScale = 1.4f;
        public const float MaxContentWidth = 560f;
        public const float MaxSeatWidth = 260f;
        public const float SeatColumnGap = 8f;
        public const float SeatBandGap = 6f;

        public const float CardWidth = 66f;
        public const float CardHeight = 96f;
        public const float CardGap = 6f;

        private const float DealerBandSpread = 198f;
        private const float DealerBandCompact = 102f;
        private const float SweepBannerBand = 56f;
        private const float SeatPitch = 78f;
        private const float SeatHeightUnits = 72f;
        private const float HeroBandWithCards = 182f;
        private const float HeroBandNoCards = 80f;
        private const float DealerBandTextShare = 0.45f;

        public float Scale { get; init; }
        public float CanvasWidth { get; init; }
        public float CanvasHeight { get; init; }
        public float Inset { get; init; }
        public float ContentWidth { get; init; }
        public float SeatWidth { get; init; }
        public float SeatHeight { get; init; }
        public float SeatRowTop { get; init; }
        public float SeatRowPitch { get; init; }
        public float HeroTop { get; init; }
        public bool Compact { get; init; }

        public float SeatTopOf(int row) => SeatRowTop + row * SeatRowPitch;
        public float OvalBleed => 58f * ContentWidth / ReferenceWidth;
        public float OvalHeight => 540f * ContentWidth / ReferenceWidth;

        /// <summary>The betting phase is "compact": no dealer cards, no hero fan, so those bands shrink.</summary>
        public static bool IsCompactPhase(RoundPhase phase) => phase == RoundPhase.Betting;

        public static float DealerCardStep(int count, float available)
        {
            if (count <= 1) return CardWidth + CardGap;
            var full = CardWidth + CardGap;
            if (CardWidth + (count - 1) * full <= available) return full;
            // Below this the corner index disappears under the next card.
            return Math.Max((available - CardWidth) / (count - 1), 20f);
        }

        public static FeltMetrics For(RoundPhase phase, bool heroHasCards, int sweepAmount,
            float availableWidth, float availableHeight, float textScale = 1f)
        {
            var compact = IsCompactPhase(phase);
            var rawDealerBand = (compact ? DealerBandCompact : DealerBandSpread) + (sweepAmount > 0 ? SweepBannerBand : 0f);
            var dealerBand = rawDealerBand * (1f + (textScale - 1f) * DealerBandTextShare);
            var seatsBottom = dealerBand + SeatPitch + SeatHeightUnits + SeatBandGap;

            // Settlement hides the hero's hand (the result card recaps it), so the felt keeps its full size.
            float heroBand;
            if (phase == RoundPhase.Settlement) heroBand = 0f;
            else if (compact) heroBand = HeroBandNoCards;
            else heroBand = heroHasCards ? HeroBandWithCards : HeroBandNoCards;
            var required = seatsBottom + heroBand;

            var fit = Math.Min(availableWidth / ReferenceWidth, availableHeight / required);
            var scale = Math.Min(fit, MaxScale);
            var canvasW = availableWidth / scale;
            var canvasH = availableHeight / scale;

            var contentWidth = Math.Min(canvasW, MaxContentWidth);
            var inset = (canvasW - contentWidth) / 2f;
            var seatWidth = Math.Min((contentWidth - SeatColumnGap) / 2f, MaxSeatWidth);

            return new FeltMetrics
            {
                Scale = scale, CanvasWidth = canvasW, CanvasHeight = canvasH, Inset = inset, ContentWidth = contentWidth,
                SeatWidth = seatWidth, SeatHeight = SeatHeightUnits, SeatRowTop = dealerBand, SeatRowPitch = SeatPitch,
                HeroTop = seatsBottom, Compact = compact,
            };
        }
    }

    /// <summary>Responsive table chrome sizes (gutter, landscape side rail), from the Flutter <c>TableLayout</c>.</summary>
    public static class TableLayout
    {
        public const float CompactMax = 600f;
        public const float MediumMax = 900f;

        public static float GutterOf(float width)
        {
            if (width < CompactMax) return 14f;
            if (width >= 900) return 48f;
            return 32f;
        }

        public static bool IsLandscape(float width, float height) => width > height;
        public static float RailWidthOf(float width) => Math.Clamp(width * 0.36f, 320f, 420f);
    }
}
