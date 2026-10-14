using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>A step of the type ramp: the size in canvas units, the face, and the tracking.</summary>
    public readonly struct TextStyle
    {
        public readonly float Size;
        public readonly FontKind Font;
        public readonly float Tracking;

        public TextStyle(float size, FontKind font, float tracking = 0f)
        {
            Size = size;
            Font = font;
            Tracking = tracking;
        }

        public TextStyle WithFont(FontKind font) => new TextStyle(Size, font, Tracking);
        public TextStyle WithTracking(float tracking) => new TextStyle(Size, Font, tracking);
    }

    /// <summary>
    /// The app's type ramp. Every size a screen uses is one of these; nothing is drawn below <see cref="Floor"/>
    /// on screen, which <c>RulesAudit</c> checks with the felt's scale included.
    /// </summary>
    public static class Type
    {
        /// <summary>The smallest size any character may have on screen, in canvas units.</summary>
        public const float Floor = 12f;

        public static readonly TextStyle Display = new TextStyle(40, FontKind.SerifItalic);
        public static readonly TextStyle H1 = new TextStyle(32, FontKind.SerifItalic);
        public static readonly TextStyle H2 = new TextStyle(24, FontKind.SerifItalic);
        public static readonly TextStyle Title = new TextStyle(17, FontKind.SoraBold);

        /// <summary>Button captions: a title's size, tracked out a little, written in caps in <c>en.json</c>.</summary>
        public static readonly TextStyle Button = new TextStyle(17, FontKind.SoraBold, 0.2f);

        public static readonly TextStyle Body = new TextStyle(15, FontKind.Sora);
        public static readonly TextStyle BodySm = new TextStyle(13, FontKind.Sora);
        public static readonly TextStyle Caption = new TextStyle(Floor, FontKind.SoraSemiBold);

        /// <summary>Figures (chips, totals, timers) in Space Mono, never below the floor.</summary>
        public static TextStyle Numeral(float size, bool bold = true) =>
            new TextStyle(Mathf.Max(Floor, size), bold ? FontKind.MonoBold : FontKind.Mono);
    }
}
