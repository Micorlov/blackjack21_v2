using System;
using System.Collections.Generic;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Icons as sprites drawn from a handful of vector primitives (strokes, discs, rings, rounded rects),
    /// rasterised once with supersampling. Coordinates are -1..1 with y up. White; tint with Image.color.
    /// </summary>
    public static class Icons
    {
        private interface IShape { float Dist(float x, float y); }

        private sealed class Stroke : IShape
        {
            private readonly float _x0, _y0, _x1, _y1, _half;
            private readonly bool _round;
            public Stroke(float x0, float y0, float x1, float y1, float width, bool round = true)
            { _x0 = x0; _y0 = y0; _x1 = x1; _y1 = y1; _half = width / 2; _round = round; }

            public float Dist(float x, float y)
            {
                var dx = _x1 - _x0; var dy = _y1 - _y0;
                var len2 = dx * dx + dy * dy;
                var t = len2 < 1e-6f ? 0 : ((x - _x0) * dx + (y - _y0) * dy) / len2;
                if (!_round && (t < 0 || t > 1)) return float.MaxValue;
                t = Mathf.Clamp01(t);
                var px = _x0 + t * dx; var py = _y0 + t * dy;
                return Mathf.Sqrt((x - px) * (x - px) + (y - py) * (y - py)) - _half;
            }
        }

        private sealed class Disc : IShape
        {
            private readonly float _cx, _cy, _r;
            public Disc(float cx, float cy, float r) { _cx = cx; _cy = cy; _r = r; }
            public float Dist(float x, float y) => Mathf.Sqrt((x - _cx) * (x - _cx) + (y - _cy) * (y - _cy)) - _r;
        }

        private sealed class Ring : IShape
        {
            private readonly float _cx, _cy, _r, _half;
            public Ring(float cx, float cy, float r, float width) { _cx = cx; _cy = cy; _r = r; _half = width / 2; }
            public float Dist(float x, float y) =>
                Mathf.Abs(Mathf.Sqrt((x - _cx) * (x - _cx) + (y - _cy) * (y - _cy)) - _r) - _half;
        }

        private sealed class RoundRect : IShape
        {
            private readonly float _cx, _cy, _hw, _hh, _r;
            public RoundRect(float cx, float cy, float w, float h, float r) { _cx = cx; _cy = cy; _hw = w / 2; _hh = h / 2; _r = r; }
            public float Dist(float x, float y)
            {
                var qx = Mathf.Abs(x - _cx) - (_hw - _r);
                var qy = Mathf.Abs(y - _cy) - (_hh - _r);
                var outside = Mathf.Sqrt(Mathf.Max(qx, 0) * Mathf.Max(qx, 0) + Mathf.Max(qy, 0) * Mathf.Max(qy, 0));
                return outside + Mathf.Min(Mathf.Max(qx, qy), 0) - _r;
            }
        }

        private sealed class Tri : IShape
        {
            private readonly float _ax, _ay, _bx, _by, _cx, _cy;
            public Tri(float ax, float ay, float bx, float by, float cx, float cy) { _ax = ax; _ay = ay; _bx = bx; _by = by; _cx = cx; _cy = cy; }
            public float Dist(float x, float y)
            {
                float Sign(float px, float py, float ax, float ay, float bx, float by) => (px - bx) * (ay - by) - (ax - bx) * (py - by);
                var d1 = Sign(x, y, _ax, _ay, _bx, _by);
                var d2 = Sign(x, y, _bx, _by, _cx, _cy);
                var d3 = Sign(x, y, _cx, _cy, _ax, _ay);
                var neg = d1 < 0 || d2 < 0 || d3 < 0;
                var pos = d1 > 0 || d2 > 0 || d3 > 0;
                return neg && pos ? 1f : -1f;
            }
        }

        // A drawing is a union of "add" shapes minus a union of "cut" shapes.
        private sealed class Drawing
        {
            public readonly List<IShape> Add = new List<IShape>();
            public readonly List<IShape> Cut = new List<IShape>();
            public Drawing A(IShape s) { Add.Add(s); return this; }
            public Drawing C(IShape s) { Cut.Add(s); return this; }

            public bool Inside(float x, float y)
            {
                var hit = false;
                foreach (var s in Add) if (s.Dist(x, y) <= 0) { hit = true; break; }
                if (!hit) return false;
                foreach (var s in Cut) if (s.Dist(x, y) <= 0) return false;
                return true;
            }
        }

        private static readonly Dictionary<string, Sprite> Cache = new Dictionary<string, Sprite>();

        public static Sprite Get(string name)
        {
            if (Cache.TryGetValue(name, out var cached)) return cached;
            var sprite = Rasterise(Build(name));
            Cache[name] = sprite;
            return sprite;
        }

        private static Drawing Build(string name)
        {
            var d = new Drawing();
            switch (name)
            {
                case "chevron_left":
                    return d.A(new Stroke(0.35f, 0.7f, -0.3f, 0f, 0.2f)).A(new Stroke(-0.3f, 0f, 0.35f, -0.7f, 0.2f));
                case "chevron_right":
                    return d.A(new Stroke(-0.35f, 0.7f, 0.3f, 0f, 0.2f)).A(new Stroke(0.3f, 0f, -0.35f, -0.7f, 0.2f));
                case "more_vert":
                    return d.A(new Disc(0, 0.62f, 0.17f)).A(new Disc(0, 0, 0.17f)).A(new Disc(0, -0.62f, 0.17f));
                case "check":
                    return d.A(new Stroke(-0.62f, -0.02f, -0.2f, -0.46f, 0.22f)).A(new Stroke(-0.2f, -0.46f, 0.66f, 0.5f, 0.22f));
                case "close":
                    return d.A(new Stroke(-0.55f, 0.55f, 0.55f, -0.55f, 0.2f)).A(new Stroke(-0.55f, -0.55f, 0.55f, 0.55f, 0.2f));
                case "chat":
                    return d.A(new RoundRect(0, 0.12f, 1.7f, 1.25f, 0.28f)).A(new Tri(-0.6f, -0.4f, -0.2f, -0.4f, -0.7f, -0.85f))
                        .C(new RoundRect(0, 0.12f, 1.38f, 0.93f, 0.16f)).A(new Stroke(-0.4f, 0.12f, 0.4f, 0.12f, 0.14f));
                case "home":
                    return d.A(new Stroke(-0.85f, 0.05f, 0f, 0.82f, 0.18f)).A(new Stroke(0f, 0.82f, 0.85f, 0.05f, 0.18f))
                        .A(new RoundRect(0, -0.38f, 1.34f, 0.9f, 0.1f)).C(new RoundRect(0, -0.5f, 0.42f, 0.7f, 0.06f));
                case "bar_chart":
                    return d.A(new RoundRect(-0.55f, -0.3f, 0.32f, 0.9f, 0.06f)).A(new RoundRect(0f, 0.05f, 0.32f, 1.6f, 0.06f))
                        .A(new RoundRect(0.55f, -0.12f, 0.32f, 1.25f, 0.06f));
                case "people":
                    return d.A(new Disc(-0.3f, 0.38f, 0.3f)).A(new Disc(-0.3f, -0.62f, 0.62f)).A(new Disc(0.5f, 0.28f, 0.24f))
                        .A(new Disc(0.55f, -0.5f, 0.45f)).C(new RoundRect(0, -1.3f, 3f, 1.3f, 0f));
                case "settings":
                    d.A(new Disc(0, 0, 0.62f)).C(new Disc(0, 0, 0.25f));
                    for (var i = 0; i < 8; i++)
                    {
                        var a = i * Mathf.PI / 4f;
                        d.A(new Stroke(Mathf.Cos(a) * 0.5f, Mathf.Sin(a) * 0.5f, Mathf.Cos(a) * 0.88f, Mathf.Sin(a) * 0.88f, 0.3f, false));
                    }
                    return d;
                case "gift":
                    return d.A(new RoundRect(0, -0.28f, 1.5f, 1.05f, 0.1f)).A(new RoundRect(0, 0.45f, 1.7f, 0.42f, 0.08f))
                        .C(new Stroke(0, -0.8f, 0, 0.75f, 0.16f, false))
                        .A(new Ring(-0.28f, 0.82f, 0.22f, 0.12f)).A(new Ring(0.28f, 0.82f, 0.22f, 0.12f));
                case "replay":
                    return d.A(new Ring(0, 0, 0.6f, 0.2f)).C(new Tri(0f, 0.5f, 0.95f, 0.95f, 0.95f, -0.1f))
                        .A(new Tri(0.05f, 0.95f, 0.05f, 0.1f, 0.78f, 0.55f));
                case "person_add":
                    return d.A(new Disc(-0.25f, 0.4f, 0.32f)).A(new Disc(-0.25f, -0.62f, 0.66f)).C(new RoundRect(0, -1.3f, 3f, 1.3f, 0f))
                        .A(new Stroke(0.55f, 0.1f, 0.55f, 0.7f, 0.16f)).A(new Stroke(0.25f, 0.4f, 0.85f, 0.4f, 0.16f));
                case "remove":
                    return d.A(new Stroke(-0.5f, 0f, 0.5f, 0f, 0.2f));
                case "volume_up":
                    d.A(new RoundRect(-0.62f, 0f, 0.4f, 0.6f, 0.06f)).A(new Tri(-0.45f, 0.3f, 0.15f, 0.8f, 0.15f, -0.8f))
                        .A(new Tri(-0.45f, -0.3f, 0.15f, -0.8f, 0.15f, 0.8f));
                    foreach (var radius in new[] { 0.45f, 0.8f })
                        for (var i = 0; i < 6; i++)
                        {
                            var a0 = (-40f + i * 16f) * Mathf.Deg2Rad;
                            var a1 = (-40f + (i + 1) * 16f) * Mathf.Deg2Rad;
                            d.A(new Stroke(0.2f + Mathf.Cos(a0) * radius, Mathf.Sin(a0) * radius,
                                0.2f + Mathf.Cos(a1) * radius, Mathf.Sin(a1) * radius, 0.14f));
                        }
                    return d;
                case "volume_off":
                    d.A(new RoundRect(-0.62f, 0f, 0.4f, 0.6f, 0.06f)).A(new Tri(-0.45f, 0.3f, 0.15f, 0.8f, 0.15f, -0.8f))
                        .A(new Tri(-0.45f, -0.3f, 0.15f, -0.8f, 0.15f, 0.8f));
                    d.A(new Stroke(0.45f, 0.3f, 0.95f, -0.3f, 0.14f)).A(new Stroke(0.45f, -0.3f, 0.95f, 0.3f, 0.14f));
                    return d;
                case "group_add":
                    return d.A(new Disc(-0.3f, 0.38f, 0.3f)).A(new Disc(-0.3f, -0.62f, 0.62f)).C(new RoundRect(0, -1.3f, 3f, 1.3f, 0f))
                        .A(new Stroke(0.55f, 0.1f, 0.55f, 0.7f, 0.16f)).A(new Stroke(0.25f, 0.4f, 0.85f, 0.4f, 0.16f));
                case "style":
                    return d.A(new RoundRect(-0.15f, 0.05f, 1f, 1.4f, 0.12f)).C(new RoundRect(-0.15f, 0.05f, 0.7f, 1.1f, 0.06f))
                        .A(new RoundRect(0.35f, -0.1f, 1f, 1.4f, 0.12f));
                case "dot":
                    return d.A(new Disc(0, 0, 0.9f));
                default:
                    return d.A(new Ring(0, 0, 0.6f, 0.2f));
            }
        }

        private static Sprite Rasterise(Drawing drawing)
        {
            const int size = 96;
            const int samples = 3;
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };
            var pixels = new Color32[size * size];
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var hit = 0;
                for (var sy = 0; sy < samples; sy++)
                for (var sx = 0; sx < samples; sx++)
                {
                    var u = (x + (sx + 0.5f) / samples) / size * 2f - 1f;
                    var v = (y + (sy + 0.5f) / samples) / size * 2f - 1f;
                    if (drawing.Inside(u, v)) hit++;
                }
                pixels[y * size + x] = new Color(1, 1, 1, hit / (float)(samples * samples));
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f);
        }
    }
}
