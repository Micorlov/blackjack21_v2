using System;
using System.Collections.Generic;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>Baked art: card faces and backs, casino chips, soft shadows, and the felt table texture.</summary>
    public static partial class Gfx
    {
        private static readonly Dictionary<string, Sprite> SpriteCache = new Dictionary<string, Sprite>();
        private static readonly Dictionary<string, Texture2D> TextureCache = new Dictionary<string, Texture2D>();

        private static Texture2D NewTexture(int w, int h, bool repeat = false) => new Texture2D(w, h, TextureFormat.RGBA32, false)
        {
            filterMode = FilterMode.Bilinear,
            wrapMode = repeat ? TextureWrapMode.Repeat : TextureWrapMode.Clamp,
        };

        private static Color32 Over(Color32 baseColor, Color top)
        {
            var b = (Color)baseColor;
            var a = top.a;
            var outA = a + b.a * (1 - a);
            if (outA < 1e-5f) return new Color32(0, 0, 0, 0);
            var r = (top.r * a + b.r * b.a * (1 - a)) / outA;
            var g = (top.g * a + b.g * b.a * (1 - a)) / outA;
            var bl = (top.b * a + b.b * b.a * (1 - a)) / outA;
            return new Color(r, g, bl, outA);
        }

        // Coverage of a rounded rect (corner radius in texels) at pixel centre, 0..1 with a 1px edge.
        private static float RoundRectCoverage(float px, float py, float w, float h, float radius)
        {
            var cx = Mathf.Clamp(px, radius, w - radius);
            var cy = Mathf.Clamp(py, radius, h - radius);
            var d = Mathf.Sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
            return Mathf.Clamp01(radius - d + 0.5f);
        }

        // ---- gradients --------------------------------------------------------------------------------

        /// <summary>A 1xN vertical (top→bottom) or Nx1 gradient; stretch it with a RawImage.</summary>
        public static Texture2D Linear(Color[] colors, float[] stops, bool vertical = true, int n = 128)
        {
            var tex = vertical ? NewTexture(1, n) : NewTexture(n, 1);
            for (var i = 0; i < n; i++)
            {
                var t = i / (float)(n - 1);
                var c = colors[colors.Length - 1];
                for (var s = 1; s < stops.Length; s++)
                {
                    if (t > stops[s]) continue;
                    c = Color.Lerp(colors[s - 1], colors[s], (t - stops[s - 1]) / Mathf.Max(1e-4f, stops[s] - stops[s - 1]));
                    break;
                }
                // Texture row 0 is the bottom, so a top→bottom ramp is written reversed.
                if (vertical) tex.SetPixel(0, n - 1 - i, c); else tex.SetPixel(i, 0, c);
            }
            tex.Apply();
            return tex;
        }

        private static readonly Dictionary<string, Texture2D> Gradients = new Dictionary<string, Texture2D>();

        /// <summary>
        /// A circular radial gradient like Flutter's: <paramref name="centre"/> is an Alignment (-1..1, y down) and
        /// <paramref name="radius"/> a fraction of the shorter side, so it stays round whatever the rect's shape.
        /// </summary>
        public static Texture2D RadialCircular(string cacheKey, int texW, int texH, Vector2 centre, float radius, Color[] colors, float[] stops)
        {
            if (Gradients.TryGetValue(cacheKey, out var cached)) return cached;
            var tex = NewTexture(texW, texH);
            var pixels = new Color32[texW * texH];
            var cx = (centre.x + 1f) / 2f * texW;
            var cy = (centre.y + 1f) / 2f * texH;
            var radiusPx = radius * Mathf.Min(texW, texH);
            for (var y = 0; y < texH; y++)
            for (var x = 0; x < texW; x++)
            {
                var py = texH - 1 - y;                      // texture rows run bottom-up
                var d = Mathf.Sqrt((x + 0.5f - cx) * (x + 0.5f - cx) + (py + 0.5f - cy) * (py + 0.5f - cy)) / radiusPx;
                pixels[y * texW + x] = Ramp(colors, stops, Mathf.Clamp01(d));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            Gradients[cacheKey] = tex;
            return tex;
        }

        // ---- shadows ----------------------------------------------------------------------------------

        private const int ShadowSize = 128, ShadowCore = 40;

        /// <summary>A blurred rounded-rect shadow, 9-sliced. Tint black with the alpha you want.</summary>
        public static Sprite SoftShadow()
        {
            if (SpriteCache.TryGetValue("shadow", out var cached)) return cached;
            var tex = NewTexture(ShadowSize, ShadowSize);
            var pixels = new Color32[ShadowSize * ShadowSize];
            var half = ShadowSize / 2f;
            for (var y = 0; y < ShadowSize; y++)
            for (var x = 0; x < ShadowSize; x++)
            {
                float px = Mathf.Abs(x + 0.5f - half), py = Mathf.Abs(y + 0.5f - half);
                var qx = px - (half - ShadowCore - 24f); var qy = py - (half - ShadowCore - 24f);
                var d = Mathf.Sqrt(Mathf.Max(qx, 0) * Mathf.Max(qx, 0) + Mathf.Max(qy, 0) * Mathf.Max(qy, 0)) - 24f;
                var a = Mathf.Clamp01(0.5f - d / (ShadowCore * 1.2f));
                a = a * a * (3f - 2f * a);
                pixels[y * ShadowSize + x] = new Color(1, 1, 1, a);
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            var sprite = Sprite.Create(tex, new Rect(0, 0, ShadowSize, ShadowSize), new Vector2(0.5f, 0.5f), 100f, 0,
                SpriteMeshType.FullRect, new Vector4(ShadowCore + 20, ShadowCore + 20, ShadowCore + 20, ShadowCore + 20));
            SpriteCache["shadow"] = sprite;
            return sprite;
        }

        public static float ShadowBorder => ShadowCore + 20;

        // ---- felt -------------------------------------------------------------------------------------

        private static Material _feltMaterial;

        /// <summary>The felt shader's material (see Resources/Shaders/Felt.shader). Set _Canvas and _Oval on it.</summary>
        public static Material NewFeltMaterial() => new Material(Resources.Load<Shader>("Shaders/Felt"));

        private static Color Ramp(Color[] colors, float[] stops, float t)
        {
            for (var i = 1; i < stops.Length; i++)
            {
                if (t > stops[i]) continue;
                return Color.Lerp(colors[i - 1], colors[i], (t - stops[i - 1]) / Mathf.Max(1e-4f, stops[i] - stops[i - 1]));
            }
            return colors[colors.Length - 1];
        }
    }
}
