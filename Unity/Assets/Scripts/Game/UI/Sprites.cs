using System;
using System.Collections.Generic;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Sprites generated at runtime so the UI needs no art: a 9-sliced rounded rectangle, a circle,
    /// radial gradients and the four suit symbols (the bundled fonts have no suit glyphs).
    /// </summary>
    public static class Sprites
    {
        private const int RoundedSize = 128;
        private const int RoundedRadius = 48;
        private static Sprite _rounded;
        private static Sprite _circle;
        private static readonly Dictionary<string, Sprite> Suits = new Dictionary<string, Sprite>();

        /// <summary>
        /// A 9-sliced rounded rect. Use with Image.type = Sliced and set
        /// pixelsPerUnitMultiplier to <see cref="RoundedRadius"/> / desiredRadius (see <c>Ui.Box</c>).
        /// </summary>
        public static Sprite Rounded => _rounded ??= MakeRounded();

        public static float RoundedBorder => RoundedRadius;

        private static readonly Dictionary<int, Sprite> Rings = new Dictionary<int, Sprite>();

        /// <summary>
        /// A rounded-rect outline (transparent inside), 9-sliced like <see cref="Rounded"/>. Thickness is in
        /// texels of the 128px sprite and is quantised to half a texel so the cache stays small.
        /// </summary>
        public static Sprite RoundedRing(float thicknessTexels)
        {
            var key = Mathf.Clamp(Mathf.RoundToInt(thicknessTexels * 2f), 1, 60);
            if (Rings.TryGetValue(key, out var cached)) return cached;
            var t = key / 2f;
            var tex = NewTexture(RoundedSize, RoundedSize);
            var pixels = new Color32[RoundedSize * RoundedSize];
            var innerRadius = Mathf.Max(0.5f, RoundedRadius - t);
            for (var y = 0; y < RoundedSize; y++)
            for (var x = 0; x < RoundedSize; x++)
            {
                float px = x + 0.5f, py = y + 0.5f;
                var outer = CoverageOf(px, py, RoundedSize, RoundedSize, RoundedRadius);
                var inner = CoverageOf(px - t, py - t, RoundedSize - 2 * t, RoundedSize - 2 * t, innerRadius);
                pixels[y * RoundedSize + x] = new Color(1, 1, 1, Mathf.Clamp01(outer - inner));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            var sprite = Sprite.Create(tex, new Rect(0, 0, RoundedSize, RoundedSize), new Vector2(0.5f, 0.5f), 100f, 0,
                SpriteMeshType.FullRect, new Vector4(RoundedRadius, RoundedRadius, RoundedRadius, RoundedRadius));
            Rings[key] = sprite;
            return sprite;
        }

        private static float CoverageOf(float px, float py, float w, float h, float radius)
        {
            var cx = Mathf.Clamp(px, radius, w - radius);
            var cy = Mathf.Clamp(py, radius, h - radius);
            var d = Mathf.Sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
            return Mathf.Clamp01(radius - d + 0.5f);
        }

        public static Sprite Circle => _circle ??= MakeCircle(128);

        private static Texture2D NewTexture(int w, int h)
        {
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };
            return tex;
        }

        private static Sprite MakeRounded()
        {
            var tex = NewTexture(RoundedSize, RoundedSize);
            var pixels = new Color32[RoundedSize * RoundedSize];
            for (var y = 0; y < RoundedSize; y++)
            for (var x = 0; x < RoundedSize; x++)
            {
                float px = x + 0.5f, py = y + 0.5f;
                var cx = Mathf.Clamp(px, RoundedRadius, RoundedSize - RoundedRadius);
                var cy = Mathf.Clamp(py, RoundedRadius, RoundedSize - RoundedRadius);
                var d = Mathf.Sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
                var a = Mathf.Clamp01(RoundedRadius - d + 0.5f);
                pixels[y * RoundedSize + x] = new Color(1, 1, 1, a);
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, RoundedSize, RoundedSize), new Vector2(0.5f, 0.5f), 100f, 0,
                SpriteMeshType.FullRect, new Vector4(RoundedRadius, RoundedRadius, RoundedRadius, RoundedRadius));
        }

        private static Sprite MakeCircle(int size)
        {
            var tex = NewTexture(size, size);
            var pixels = new Color32[size * size];
            var r = size / 2f;
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var d = Mathf.Sqrt((x + 0.5f - r) * (x + 0.5f - r) + (y + 0.5f - r) * (y + 0.5f - r));
                pixels[y * size + x] = new Color(1, 1, 1, Mathf.Clamp01(r - d + 0.5f));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
        }

        /// <summary>A soft white glow (radial falloff), for shadows and highlights; tint with Image.color.</summary>
        public static Texture2D RadialGlow(int size = 128, float softness = 1f)
        {
            var tex = NewTexture(size, size);
            var pixels = new Color32[size * size];
            var r = size / 2f;
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var d = Mathf.Sqrt((x + 0.5f - r) * (x + 0.5f - r) + (y + 0.5f - r) * (y + 0.5f - r)) / r;
                var a = Mathf.Pow(Mathf.Clamp01(1f - d), softness);
                pixels[y * size + x] = new Color(1, 1, 1, a);
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return tex;
        }

        /// <summary>
        /// A radial gradient: <paramref name="stops"/> map from the centre (0) to the edge (1) of the
        /// ellipse the texture is stretched over. Centre is offset by <paramref name="centre"/> in -1..1.
        /// </summary>
        public static Texture2D RadialGradient(Color[] colors, float[] stops, Vector2 centre, float radius, int size = 256)
        {
            var tex = NewTexture(size, size);
            var pixels = new Color32[size * size];
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var nx = (x + 0.5f) / size * 2f - 1f;
                var ny = (y + 0.5f) / size * 2f - 1f;
                var t = Mathf.Sqrt((nx - centre.x) * (nx - centre.x) + (ny - centre.y) * (ny - centre.y)) / radius;
                pixels[y * size + x] = Ramp(colors, stops, Mathf.Clamp01(t));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return tex;
        }

        private static Color Ramp(Color[] colors, float[] stops, float t)
        {
            for (var i = 1; i < stops.Length; i++)
            {
                if (t > stops[i]) continue;
                var span = Mathf.Max(0.0001f, stops[i] - stops[i - 1]);
                return Color.Lerp(colors[i - 1], colors[i], (t - stops[i - 1]) / span);
            }
            return colors[colors.Length - 1];
        }

        /// <summary>A white suit silhouette ("♠", "♥", "♦", "♣"); tint with Image.color.</summary>
        public static Sprite Suit(string suit)
        {
            if (Suits.TryGetValue(suit, out var cached)) return cached;
            const int size = 128;
            var tex = NewTexture(size, size);
            var pixels = new Color32[size * size];
            Func<float, float, bool> inside = suit switch
            {
                "♥" => Heart,
                "♦" => Diamond,
                "♠" => Spade,
                _ => Club,
            };
            const int samples = 3;
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var hit = 0;
                for (var sy = 0; sy < samples; sy++)
                for (var sx = 0; sx < samples; sx++)
                {
                    var u = (x + (sx + 0.5f) / samples) / size * 2f - 1f;
                    var v = (y + (sy + 0.5f) / samples) / size * 2f - 1f;
                    if (inside(u, v)) hit++;
                }
                pixels[y * size + x] = new Color(1, 1, 1, hit / (float)(samples * samples));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            var sprite = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
            Suits[suit] = sprite;
            return sprite;
        }

        // Shapes live in -1..1, y up.

        private static bool Heart(float u, float v)
        {
            var x = u * 1.25f;
            var y = v * 1.25f + 0.1f;
            var a = x * x + y * y - 1f;
            return a * a * a - x * x * y * y * y <= 0f;
        }

        private static bool Diamond(float u, float v) => Mathf.Abs(u) / 0.72f + Mathf.Abs(v) / 0.95f <= 1f;

        private static bool Spade(float u, float v)
        {
            // An upside-down heart for the head, a flared stem for the foot.
            if (Heart(u * 1.05f, -(v - 0.2f) * 1.1f) && v > -0.45f) return true;
            return v <= -0.2f && v >= -0.92f && Mathf.Abs(u) <= 0.1f + (-0.2f - v) * 0.42f;
        }

        private static bool Club(float u, float v)
        {
            bool Disc(float cx, float cy, float r) => (u - cx) * (u - cx) + (v - cy) * (v - cy) <= r * r;
            if (Disc(0f, 0.42f, 0.36f) || Disc(-0.4f, -0.1f, 0.36f) || Disc(0.4f, -0.1f, 0.36f)) return true;
            return v <= 0.05f && v >= -0.92f && Mathf.Abs(u) <= 0.1f + (0.05f - v) * 0.38f;
        }
    }
}
