using System;

namespace Blackjack.Core
{
    /// <summary>
    /// The Seat's felt: one design canvas, 384 x 520 units (docs/design-concepts/the-seat), scaled uniformly to the
    /// room it is given. A short room first squeezes the gaps above the hero's cards (to
    /// <see cref="MinVerticalFit"/>) so nothing changes size, and everything from the hero's cards down keeps its
    /// spacing (the bet ring must stay clear of 128-unit cards); only past that does the whole felt scale down. A
    /// tall room spreads every gap a little (to <see cref="MaxVerticalFit"/>) and leaves the rest below the rail.
    /// </summary>
    public sealed record FeltMetrics
    {
        public const float ReferenceWidth = 384f;
        public const float DesignHeight = 520f;
        public const float MaxScale = 1.4f;
        public const float MaxContentWidth = 560f;
        public const float MinVerticalFit = 0.85f;
        public const float MaxVerticalFit = 1.15f;

        /// <summary>The dealer's cards, and the size every other card is measured against.</summary>
        public const float CardWidth = 66f;
        public const float CardHeight = 96f;

        /// <summary>The dealer's cards overlap by 30% of a card, as in the design.</summary>
        public const float DealerOverlap = 0.3f;

        /// <summary>The hero's own cards: larger than the dealer's (88 vs 66), no more than 1.4x.</summary>
        public const float HeroCardWidth = 88f;
        public const float HeroCardHeight = HeroCardWidth * CardHeight / CardWidth;
        public const float HeroOverlap = 0.48f;

        /// <summary>The other seats' cards: never smaller than this, so their rank stays readable.</summary>
        public const float SeatCardWidth = 42f;
        public const float SeatCardHeight = 60f;
        public const float SeatOverlap = 0.4f;

        // Where each opponent sits on the curve of the felt, for a 384-unit-wide table: horizontal offset from the
        // centre line, depth below the top seats, and how far its cards turn toward the dealer.
        // First base (the dealer's left) is on the right of the screen in every language.
        private static readonly (float x, float y, float tilt)[] SeatCurve =
        {
            (144f, 0f, -14f),   // first base
            (124f, 96f, -7f),
            (-124f, 96f, 7f),
            (-144f, 0f, 14f),   // third base
        };

        // Design rows, in units below the wooden edge (the mockup's screen y minus 100).
        public const float WoodEdge = 10f;
        public const float FixturesTop = 4f;
        public const float PlacardTop = 46f;
        public const float DealerTop = 50f;
        public const float CallTop = 82f;
        public const float PotTop = 154f;
        public const float PrintTop = 186f;
        public const float SeatsTop = 226f;
        public const float HeroBadgeTop = 232f;
        public const float SplitLabelTop = 248f;
        public const float HeroCardsTop = 276f;
        public const float BetTop = 406f;
        public const float RailSide = 332f;
        public const float RailMiddle = 478f;
        public const float RailChipsTop = 450f;
        public const float BalanceTop = 488f;

        public float Scale { get; init; }
        public float CanvasWidth { get; init; }
        public float CanvasHeight { get; init; }
        public float Inset { get; init; }
        public float ContentWidth { get; init; }

        /// <summary>How the design's vertical gaps are stretched (above 1) or squeezed (below 1) to fill the room.</summary>
        public float VerticalFit { get; init; }

        /// <summary>The middle of the table, in canvas units.</summary>
        public float CentreX => Inset + ContentWidth / 2f;

        /// <summary>The least room the felt needs before it has to scale: the upper gaps fully squeezed.</summary>
        public const float SqueezedHeight = HeroCardsTop * MinVerticalFit + (DesignHeight - HeroCardsTop);

        /// <summary>A design row's y on this canvas.</summary>
        public float Y(float designY) => VerticalFit >= 1f || designY <= HeroCardsTop
            ? designY * VerticalFit
            : HeroCardsTop * VerticalFit + (designY - HeroCardsTop);

        /// <summary>A design x offset from the centre line, widened with the table.</summary>
        public float X(float designOffset) => CentreX + designOffset * ContentWidth / ReferenceWidth;

        /// <summary>
        /// Where opponent seat <paramref name="index"/> (casino order: 0 and 1 act before the hero, 2 and 3 after)
        /// sits: the centre line of its column, the top of its name pill, the tilt of its fan, and its side
        /// (+1 right, -1 left).
        /// </summary>
        public SeatPlace SeatSlot(int index)
        {
            var (x, y, tilt) = SeatCurve[Math.Clamp(index, 0, SeatCurve.Length - 1)];
            return new SeatPlace(X(x), Y(SeatsTop + y), tilt, Math.Sign(x));
        }

        /// <summary>The step between the dealer's cards: the design's 30% overlap, tightened only if a long hand would not fit.</summary>
        public static float DealerCardStep(int count, float available)
        {
            var full = CardWidth * (1f - DealerOverlap);
            if (count <= 1 || CardWidth + (count - 1) * full <= available) return full;
            // Below this the corner index disappears under the next card.
            return Math.Max((available - CardWidth) / (count - 1), 20f);
        }

        public static FeltMetrics For(float availableWidth, float availableHeight)
        {
            var scale = Math.Min(Math.Min(availableWidth / ReferenceWidth, availableHeight / SqueezedHeight), MaxScale);
            var canvasW = availableWidth / scale;
            var canvasH = availableHeight / scale;
            var contentWidth = Math.Min(canvasW, MaxContentWidth);
            // Squeezing only takes from the rows above the hero's cards; stretching spreads every row.
            var fit = canvasH >= DesignHeight ? canvasH / DesignHeight : (canvasH - (DesignHeight - HeroCardsTop)) / HeroCardsTop;
            return new FeltMetrics
            {
                Scale = scale, CanvasWidth = canvasW, CanvasHeight = canvasH,
                Inset = (canvasW - contentWidth) / 2f, ContentWidth = contentWidth,
                VerticalFit = Math.Clamp(fit, MinVerticalFit, MaxVerticalFit),
            };
        }
    }

    /// <summary>An opponent's place on the felt canvas (units, y down from the top), from <see cref="FeltMetrics.SeatSlot"/>.</summary>
    public readonly struct SeatPlace
    {
        public readonly float X, Y, Tilt;
        public readonly int Side;

        public SeatPlace(float x, float y, float tilt, int side)
        {
            X = x; Y = y; Tilt = tilt; Side = side;
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
