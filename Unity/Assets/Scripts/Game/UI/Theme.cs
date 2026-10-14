using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>Design tokens, ported from the Flutter <c>AppColors</c> / <c>AppSpacing</c>.</summary>
    public static class Theme
    {
        public static Color Hex(uint argb)
        {
            var a = ((argb >> 24) & 0xFF) / 255f;
            var r = ((argb >> 16) & 0xFF) / 255f;
            var g = ((argb >> 8) & 0xFF) / 255f;
            var b = (argb & 0xFF) / 255f;
            return new Color(r, g, b, a);
        }

        public static Color WithAlpha(this Color c, float alpha) => new Color(c.r, c.g, c.b, alpha);

        // Shell / backgrounds
        public static readonly Color ShellBlack = Hex(0xFF0B0E0D);
        public static readonly Color Surface = Hex(0xFF131716);
        public static readonly Color Panel = Hex(0xFF1C2120);
        public static readonly Color NavSurface = Hex(0xFF171B1A);
        public static readonly Color Border = Hex(0xFF2B3230);
        public static readonly Color BorderStrong = Hex(0xFF6B7572);

        // Felt
        public static readonly Color Felt = Hex(0xFF175943);
        public static readonly Color FeltDark = Hex(0xFF0E3B2E);
        public static readonly Color FeltDarkest = Hex(0xFF0A2018);
        public static readonly Color FeltTableMid = Hex(0xFF123A2C);
        public static readonly Color FeltTableDark = Hex(0xFF0A1F18);

        // Text
        public static readonly Color TextPrimary = Hex(0xFFF5F1E8);
        public static readonly Color TextMuted = Hex(0xFFC7C3B7);
        public static readonly Color TextLabel = Hex(0xFFC2BEB2);
        public static readonly Color TextFaint = Hex(0xFF9AA79E);
        public static readonly Color TextBody = Hex(0xFFD8D3C6);

        // Gold accent
        public static readonly Color GoldLight = Hex(0xFFEBD7A0);
        public static readonly Color Gold = Hex(0xFFDCBF7A);
        public static readonly Color GoldDark = Hex(0xFFC9A75C);
        public static readonly Color GoldInk = Hex(0xFF1A1408);

        // Results
        public static readonly Color Win = Hex(0xFF4FAE8E);
        public static readonly Color WinLight = Hex(0xFF9FE6C9);
        public static readonly Color Lose = Hex(0xFFC1503F);
        public static readonly Color LoseLight = Hex(0xFFF2B0A5);
        public static readonly Color LoseSoft = Hex(0xFFE39084);
        public static readonly Color Push = Hex(0xFFC2BEB2);
        public static readonly Color PushOnFelt = Hex(0xFFC4C0B4);

        // Cards
        public static readonly Color CardFaceTop = Hex(0xFFFFFDF8);
        public static readonly Color CardFaceBottom = Hex(0xFFF0E9D9);
        public static readonly Color CardRed = Hex(0xFFB23A2E);
        public static readonly Color CardBlack = Hex(0xFF16130E);

        public static readonly Color Scrim = Hex(0xFF040806);

        public static Color ChipColor(int denomination) => denomination switch
        {
            25 => Win,
            50 => Lose,
            100 => TextPrimary,
            500 => Gold,
            1000 => Hex(0xFF9B7FD4),
            _ => Gold,
        };

        public static readonly Color[] SeatColors =
        {
            Hex(0xFFC86A9E), Hex(0xFF4FAE8E), Hex(0xFF8A9BB8), Hex(0xFFE0A050),
        };

        public static readonly Color[] AvatarSwatches =
        {
            Hex(0xFF1E7D5D), Gold, Hex(0xFFB23A2E), Hex(0xFF3E7FA8), Hex(0xFF8A6BB8), Win,
        };

        public static Color Medal(int rank) => rank switch
        {
            1 => Gold,
            2 => Hex(0xFFC7CCC9),
            3 => Hex(0xFFC98A4B),
            _ => Border,
        };

        // Spacing / radius
        public const float Xxs = 2, Xs = 4, Sm = 8, Md = 12, Lg = 16, Xl = 20, Xxl = 24, Xxxl = 32;
        public const float RadiusSm = 8, RadiusMd = 12, RadiusLg = 16, RadiusXl = 20, RadiusXxl = 24, RadiusPill = 999;
        public const float MinTarget = 48;
    }
}
