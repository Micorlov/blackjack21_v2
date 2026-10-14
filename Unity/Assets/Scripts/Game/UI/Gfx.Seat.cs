using System;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The Seat's baked art (docs/design-concepts/the-seat): playing cards, casino chips seen from above and from
    /// the side, the dealer's chip tray, the shoe, the discard holder and the room behind the table. Each is drawn
    /// once into a texture and cached, so none of it costs anything per frame.
    /// </summary>
    public static partial class Gfx
    {
        /// <summary>Texels per canvas unit for the small fixtures, so they stay sharp up to the felt's 1.4x scale on a dense phone.</summary>
        private const float FixtureTexels = 4f;

        /// <summary>Bakes <paramref name="shade"/> (pixel centre, y down from the top) into a cached sprite.</summary>
        private static Sprite Bake(string key, int w, int h, Func<float, float, Color> shade, Vector4 border = default)
        {
            if (SpriteCache.TryGetValue(key, out var cached)) return cached;
            var tex = NewTexture(w, h);
            var pixels = new Color32[w * h];
            for (var y = 0; y < h; y++)
            for (var x = 0; x < w; x++)
                pixels[y * w + x] = shade(x + 0.5f, h - y - 0.5f);
            tex.SetPixels32(pixels);
            tex.Apply();
            var sprite = Sprite.Create(tex, new Rect(0, 0, w, h), new Vector2(0.5f, 0.5f), 100f, 0, SpriteMeshType.FullRect, border);
            SpriteCache[key] = sprite;
            return sprite;
        }

        private static Color WithA(Color c, float a) => new Color(c.r, c.g, c.b, a);

        private static Color Mix(Color under, Color over, float amount) => Color.Lerp(under, over, Mathf.Clamp01(amount));

        // ---- cards ------------------------------------------------------------------------------------

        // Big enough that an 88-unit hero card on a 1080-wide phone (about 2.6 px per unit) is drawn from texels.
        private const int CardW = 256, CardH = 372;
        private const float CardRadius = CardW * 0.075f;

        private static readonly Color CardTop = Theme.Hex(0xFFFFFEFA);
        private static readonly Color CardBottom = Theme.Hex(0xFFF4EEE0);
        private static readonly Color CardBackRed = Theme.Hex(0xFFA8202A);

        /// <summary>The cream face: a soft 170° gradient inside a hairline edge, with the design's 7.5% corner radius.</summary>
        public static Sprite CardFace() => Bake("seatCardFace", CardW, CardH, (px, py) =>
        {
            var cover = RoundRectCoverage(px, py, CardW, CardH, CardRadius);
            if (cover <= 0f) return Color.clear;
            var t = Mathf.Clamp01((py / CardH) * 0.98f + (px / CardW) * 0.17f);
            var c = Color.Lerp(CardTop, CardBottom, t);
            var inner = RoundRectCoverage(px - 2f, py - 2f, CardW - 4f, CardH - 4f, CardRadius - 2f);
            c = Color.Lerp(new Color(0.42f, 0.38f, 0.32f), c, Mathf.Lerp(0.28f, 1f, inner));
            return WithA(c, cover);
        });

        /// <summary>The back: a white border round a red field cross-hatched with fine white lines.</summary>
        public static Sprite CardBack() => Bake("seatCardBack", CardW, CardH, (px, py) =>
        {
            var cover = RoundRectCoverage(px, py, CardW, CardH, CardRadius);
            if (cover <= 0f) return Color.clear;
            var inset = CardW * 0.06f;
            var field = RoundRectCoverage(px - inset, py - inset, CardW - 2 * inset, CardH - 2 * inset, CardW * 0.04f);
            const float period = 17f, line = 4.3f;
            var a = Mathf.Repeat(px + py, period) < line ? 1f : 0f;
            var b = Mathf.Repeat(px - py, period) < line ? 1f : 0f;
            var red = Mix(CardBackRed, Color.white, Mathf.Max(a, b) * 0.32f);
            var c = Color.Lerp(CardTop, red, field);
            var edge = RoundRectCoverage(px - 2f, py - 2f, CardW - 4f, CardH - 4f, CardRadius - 2f);
            c = Color.Lerp(new Color(0.42f, 0.38f, 0.32f), c, Mathf.Lerp(0.28f, 1f, edge));
            return WithA(c, cover);
        });

        // ---- chips ------------------------------------------------------------------------------------

        private static readonly Color ChipEdgeWhite = Theme.Hex(0xFFF4EFE4);

        /// <summary>
        /// A casino chip from above: the colour field, a thin white ring, a coloured band, and eight white edge
        /// spots round the rim (the design's repeating conic stripe).
        /// </summary>
        public static Sprite Chip(Color color)
        {
            const int size = 192;
            return Bake("seatChip" + ColorUtility.ToHtmlStringRGB(color), size, size, (px, py) =>
            {
                var r = size / 2f;
                var dx = px - r;
                var dy = py - r;
                var dist = Mathf.Sqrt(dx * dx + dy * dy) / r;
                var cover = Mathf.Clamp01((1f - dist) * r + 0.5f);
                if (cover <= 0f) return Color.clear;
                Color c;
                if (dist < 0.46f) c = color;
                else if (dist < 0.505f) c = Mix(color, Color.white, 0.85f);
                else if (dist < 0.64f) c = color;
                else
                {
                    var angle = Mathf.Repeat(Mathf.Atan2(dy, dx) * Mathf.Rad2Deg + 90f, 45f);
                    c = angle < 14f ? ChipEdgeWhite : color;
                }
                // The inner edge of the rim and a hairline round the outside, as the design's inset shadow.
                c = Mix(c, Color.black, Mathf.Clamp01(1f - Mathf.Abs(dist - 0.645f) * r) * 0.25f);
                c = Mix(c, Color.black, Mathf.Clamp01((dist - 0.97f) * 30f) * 0.25f);
                return WithA(c, cover);
            });
        }

        /// <summary>
        /// A stack of <paramref name="count"/> chips seen from the side, <paramref name="diameter"/> units wide: ridged
        /// coloured slices with white edge marks, shaded at the sides, under an elliptical top face.
        /// </summary>
        public static Sprite ChipStack(Color color, int count, float diameter)
        {
            count = Mathf.Clamp(count, 1, 12);
            const float slice = 4f;
            var capHalf = diameter * 0.18f;
            var w = Mathf.CeilToInt(diameter * FixtureTexels);
            var h = Mathf.CeilToInt((count * slice + 2f * capHalf) * FixtureTexels);
            var key = $"stack{ColorUtility.ToHtmlStringRGB(color)}x{count}@{diameter:0}";
            return Bake(key, w, h, (px, py) =>
            {
                var u = px / FixtureTexels;           // units across
                var v = py / FixtureTexels;           // units down
                var rx = diameter / 2f;
                var nx = (u - rx) / rx;               // -1..1 across the chip
                var bodyTop = capHalf;
                var bodyBottom = capHalf + count * slice;
                // The bottom is the lower half of an ellipse, like the cap.
                var bottomEdge = bodyBottom + capHalf * Mathf.Sqrt(Mathf.Max(0f, 1f - nx * nx));
                Color c = Color.clear;
                if (v >= bodyTop && v <= bottomEdge && Mathf.Abs(nx) <= 1f)
                {
                    var across = u / diameter;
                    var mark = (across > 0.16f && across < 0.26f) || (across > 0.74f && across < 0.84f);
                    c = mark ? ChipEdgeWhite : color;
                    if (Mathf.Repeat(v - bodyTop, slice) > slice * 0.8f) c = Mix(c, Color.black, 0.4f);
                    var shade = across < 0.3f ? (0.3f - across) / 0.3f * 0.35f : across > 0.65f ? (across - 0.65f) / 0.35f * 0.4f : 0f;
                    c = WithA(Mix(c, Color.black, shade), 1f);
                }
                // The top face: an ellipse with the chip's ring.
                var ey = (v - capHalf) / capHalf;
                var e = nx * nx + ey * ey;
                if (e <= 1f)
                {
                    var rr = Mathf.Sqrt(e);
                    var top = rr < 0.44f ? color : rr < 0.53f ? ChipEdgeWhite : color;
                    top = Mix(top, Color.black, Mathf.Clamp01((rr - 0.92f) * 12f) * 0.3f);
                    c = WithA(top, 1f);
                }
                return c;
            });
        }

        // ---- table fixtures -----------------------------------------------------------------------------

        /// <summary>The colours racked in the dealer's tray, left to right.</summary>
        public static readonly Color[] TrayColours =
        {
            Theme.Hex(0xFFF4EFE4), Theme.ChipRed, Theme.ChipRed, Theme.ChipGreen, Theme.ChipGreen,
            Theme.ChipBlack, Theme.ChipBlack, Theme.ChipPurple, Theme.ChipYellow,
        };

        public const float TrayColumnWidth = 12f, TrayColumnHeight = 20f, TrayGap = 2f, TrayPadX = 5f, TrayPadY = 4f;

        public static Vector2 TraySize => new Vector2(
            TrayColours.Length * TrayColumnWidth + (TrayColours.Length - 1) * TrayGap + 2 * TrayPadX, TrayColumnHeight + 2 * TrayPadY);

        /// <summary>The dealer's chip tray: racked columns of chips in a dark well.</summary>
        public static Sprite ChipTray()
        {
            var size = TraySize;
            var w = Mathf.CeilToInt(size.x * FixtureTexels);
            var h = Mathf.CeilToInt(size.y * FixtureTexels);
            return Bake("seatTray", w, h, (px, py) =>
            {
                var cover = RoundRectCoverage(px, py, w, h, 4f * FixtureTexels);
                if (cover <= 0f) return Color.clear;
                var u = px / FixtureTexels;
                var v = py / FixtureTexels;
                var well = Color.Lerp(Theme.Hex(0xFF0D0D0D), Theme.Hex(0xFF2A2A2A), v / size.y);
                well = Mix(well, Color.black, Mathf.Clamp01(1f - v / 3f) * 0.6f);
                var col = (u - TrayPadX) / (TrayColumnWidth + TrayGap);
                var index = Mathf.FloorToInt(col);
                var within = (u - TrayPadX) - index * (TrayColumnWidth + TrayGap);
                if (index >= 0 && index < TrayColours.Length && within < TrayColumnWidth && v > TrayPadY && v < size.y - TrayPadY)
                {
                    var c = Mathf.Repeat(v - TrayPadY, 3.2f) < 2.6f ? TrayColours[index] : Mix(TrayColours[index], Color.black, 0.45f);
                    var x = within / TrayColumnWidth;
                    var shade = x < 0.4f ? (0.4f - x) / 0.4f * 0.35f : x > 0.55f ? -(1f - Mathf.Abs(x - 0.55f) / 0.45f) * 0.18f : 0f;
                    c = shade >= 0 ? Mix(c, Color.black, shade) : Mix(c, Color.white, -shade);
                    return WithA(c, cover);
                }
                return WithA(well, cover);
            });
        }

        public static readonly Vector2 ShoeSize = new Vector2(46f, 36f);

        /// <summary>The card shoe on the dealer's right: a dark box with the edges of the deck showing at its mouth.</summary>
        public static Sprite Shoe()
        {
            var w = Mathf.CeilToInt(ShoeSize.x * FixtureTexels);
            var h = Mathf.CeilToInt(ShoeSize.y * FixtureTexels);
            return Bake("seatShoe", w, h, (px, py) =>
            {
                var cover = RoundRectCoverage(px, py, w, h, 6f * FixtureTexels);
                if (cover <= 0f) return Color.clear;
                var u = px / FixtureTexels;
                var v = py / FixtureTexels;
                var c = Color.Lerp(Theme.Hex(0xFF3A3A3A), Theme.Hex(0xFF0E0E0E), Mathf.Clamp01((u / ShoeSize.x) * 0.35f + (v / ShoeSize.y) * 0.65f));
                if (u > 6f && u < ShoeSize.x - 8f && v > ShoeSize.y - 15f && v < ShoeSize.y - 6f)
                    c = Mathf.Repeat(u, 2f) < 1f ? Theme.Hex(0xFFF4EEE0) : Theme.Hex(0xFFCFC6B2);
                return WithA(c, cover);
            });
        }

        public static readonly Vector2 DiscardSize = new Vector2(34f, 30f);

        /// <summary>The discard holder on the dealer's left: a smoked box with the used cards stacked edge-on.</summary>
        public static Sprite DiscardHolder()
        {
            var w = Mathf.CeilToInt(DiscardSize.x * FixtureTexels);
            var h = Mathf.CeilToInt(DiscardSize.y * FixtureTexels);
            return Bake("seatDiscard", w, h, (px, py) =>
            {
                var cover = RoundRectCoverage(px, py, w, h, 3f * FixtureTexels);
                if (cover <= 0f) return Color.clear;
                var u = px / FixtureTexels;
                var v = py / FixtureTexels;
                var edge = RoundRectCoverage(px - FixtureTexels, py - FixtureTexels, w - 2 * FixtureTexels, h - 2 * FixtureTexels, 2f * FixtureTexels);
                var c = Color.Lerp(new Color(1f, 1f, 1f, 0.12f), new Color(0f, 0f, 0f, 0.45f), edge);
                if (u > 5f && u < DiscardSize.x - 5f && v > 5f && v < DiscardSize.y - 9f)
                    c = Mathf.Repeat(v, 3f) < 1f ? Theme.Hex(0xFFF4EEE0) : CardBackRed;
                return new Color(c.r, c.g, c.b, c.a * cover);
            });
        }

        // ---- bet spots ----------------------------------------------------------------------------------

        /// <summary>
        /// The ellipse a bet sits in, <paramref name="width"/> x <paramref name="height"/> units with a 1.5-unit white
        /// line (tint it). Dashed for an empty spot or a seat that bust.
        /// </summary>
        public static Sprite BetRing(float width, float height, bool dashed)
        {
            var w = Mathf.CeilToInt(width * FixtureTexels);
            var h = Mathf.CeilToInt(height * FixtureTexels);
            const float line = 1.5f;
            return Bake($"ring{width:0}x{height:0}{(dashed ? "d" : "")}", w, h, (px, py) =>
            {
                var rx = w / 2f - line * FixtureTexels / 2f;
                var ry = h / 2f - line * FixtureTexels / 2f;
                var dx = (px - w / 2f) / rx;
                var dy = (py - h / 2f) / ry;
                var k = Mathf.Sqrt(dx * dx + dy * dy);
                // Distance from the ellipse in texels, near enough for a thin line.
                var d = Mathf.Abs(k - 1f) * Mathf.Min(rx, ry);
                var cover = Mathf.Clamp01(line * FixtureTexels / 2f - d + 0.5f);
                if (dashed && Mathf.Repeat(Mathf.Atan2(dy, dx) * Mathf.Rad2Deg + 180f, 20f) > 11f) cover = 0f;
                return new Color(1f, 1f, 1f, cover);
            });
        }

        /// <summary>A soft round glow, white at the centre fading to nothing; tint it (the acting seat, a blackjack).</summary>
        public static Texture2D Glow() => RadialCircular("seatGlow", 64, 64, Vector2.zero, 0.5f,
            new[] { Color.white, new Color(1f, 1f, 1f, 0.35f), new Color(1f, 1f, 1f, 0f) }, new[] { 0f, 0.4f, 1f });

        // ---- the room -----------------------------------------------------------------------------------

        private static readonly (float x, float y, float core, float glow, uint argb)[] Bokeh =
        {
            // Dimmer than the design's lamps: the table title sits over them and must keep 4.5:1.
            (0.12f, 0.04f, 5f, 14f, 0x4DFFC46E),
            (0.30f, 0.09f, 4f, 12f, 0x38FFDC96),
            (0.64f, 0.03f, 6f, 16f, 0x45FFB45A),
            (0.86f, 0.08f, 4f, 12f, 0x38FFD28C),
        };

        /// <summary>
        /// The dark room around the table: a warm glow from above, out-of-focus lights at the top, falling to near
        /// black. Drawn at half the 384x832 design size and stretched; it is all soft gradients.
        /// </summary>
        public static Texture2D Room()
        {
            const string key = "seatRoom";
            if (TextureCache.TryGetValue(key, out var cached)) return cached;
            const int w = 192, h = 416;
            const float unit = 0.5f;                           // texels per design unit
            var tex = NewTexture(w, h);
            var pixels = new Color32[w * h];
            for (var y = 0; y < h; y++)
            for (var x = 0; x < w; x++)
            {
                float px = x + 0.5f, py = h - y - 0.5f;      // y down
                var c = Color.Lerp(Theme.Room, Theme.RoomDeep, Mathf.Clamp01(py / (h * 0.3f)));
                var gx = (px / w - 0.5f) / 0.7f;
                var gy = (py / h) / 0.22f;
                c = Mix(c, Theme.Hex(0xFF783C14), Mathf.Clamp01(1f - Mathf.Sqrt(gx * gx + gy * gy)) * 0.55f);
                foreach (var (bx, by, core, glow, argb) in Bokeh)
                {
                    var light = Theme.Hex(argb);
                    var d = Vector2.Distance(new Vector2(px, py), new Vector2(bx * w, by * h)) / unit;
                    var a = d <= core ? 1f : Mathf.Clamp01(1f - (d - core) / (glow - core));
                    c = Mix(c, new Color(light.r, light.g, light.b), a * light.a);
                }
                pixels[y * w + x] = c;
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            TextureCache[key] = tex;
            return tex;
        }
    }
}
