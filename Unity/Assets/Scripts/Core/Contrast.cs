using System;

namespace Blackjack.Core
{
    /// <summary>A colour in sRGB with straight alpha, each channel 0..1.</summary>
    public readonly struct Rgba
    {
        public readonly double R, G, B, A;

        public Rgba(double r, double g, double b, double a = 1)
        {
            R = r; G = g; B = b; A = a;
        }

        /// <summary>From 0xAARRGGBB, the form <c>Theme.Hex</c> takes.</summary>
        public static Rgba FromArgb(uint argb) => new Rgba(
            ((argb >> 16) & 0xFF) / 255.0, ((argb >> 8) & 0xFF) / 255.0, (argb & 0xFF) / 255.0, ((argb >> 24) & 0xFF) / 255.0);
    }

    /// <summary>
    /// WCAG 2.x relative luminance and contrast ratio. The design rules ask 4.5:1 for text and 3:1 for the
    /// outline that is a control's only boundary.
    /// </summary>
    public static class Contrast
    {
        public const double TextMinimum = 4.5;
        public const double GraphicMinimum = 3.0;

        private static double Linear(double channel) =>
            channel <= 0.04045 ? channel / 12.92 : Math.Pow((channel + 0.055) / 1.055, 2.4);

        /// <summary>Relative luminance, 0 (black) to 1 (white). Alpha is ignored; composite first with <see cref="Over"/>.</summary>
        public static double Luminance(Rgba c) => 0.2126 * Linear(c.R) + 0.7152 * Linear(c.G) + 0.0722 * Linear(c.B);

        /// <summary>The contrast ratio of two opaque colours, 1 (identical) to 21 (black on white), in either order.</summary>
        public static double Ratio(Rgba a, Rgba b)
        {
            var la = Luminance(a);
            var lb = Luminance(b);
            return (Math.Max(la, lb) + 0.05) / (Math.Min(la, lb) + 0.05);
        }

        /// <summary>What a translucent <paramref name="top"/> looks like drawn over an opaque <paramref name="under"/>.</summary>
        public static Rgba Over(Rgba top, Rgba under)
        {
            var a = Math.Clamp(top.A, 0, 1);
            return new Rgba(top.R * a + under.R * (1 - a), top.G * a + under.G * (1 - a), top.B * a + under.B * (1 - a));
        }

        /// <summary>The ratio of a possibly translucent foreground against an opaque background.</summary>
        public static double RatioOver(Rgba foreground, Rgba background) => Ratio(Over(foreground, background), background);
    }
}
