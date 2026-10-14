using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Blackjack.Core;
using Blackjack.Game.UI;
using NUnit.Framework;
using TMPro;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace Blackjack.PlayTests
{
    /// <summary>
    /// Holds every scenario, on four phone sizes, to the design rules (CLAUDE.md, "Design rules"):
    /// <list type="bullet">
    /// <item>text: every character at least <see cref="Blackjack.Game.UI.Type.Floor"/> units on screen, felt scale included;</item>
    /// <item>targets: every control at least <see cref="Theme.MinTarget"/> square on screen;</item>
    /// <item>contrast: text 4.5:1 and marked control outlines 3:1 against the pixels actually behind them.</item>
    /// </list>
    /// Known violations live in <c>rules-baseline.txt</c>. The baseline only shrinks: a new violation fails, and so
    /// does a fixed one whose line is still there. <c>BJ_RULES_BASELINE=write</c> rewrites the file from this run.
    /// </summary>
    public class RulesAudit
    {
        private static readonly Vector2Int[] Phones =
        {
            new Vector2Int(1080, 2340), new Vector2Int(720, 1600), new Vector2Int(1080, 1920), new Vector2Int(1600, 2560),
        };

        private const float SizeTolerance = 0.05f;
        private const float TargetTolerance = 0.5f;
        private const float HiddenAlpha = 0.05f;
        private const int MaxSamplesPerAxis = 8;

        private static string BaselinePath => Path.Combine(Application.dataPath, "Tests/PlayMode/rules-baseline.txt");

        private sealed class Finding
        {
            public string Key;
            public string Detail;
            public double Worst;
            public bool LowerIsWorse;
        }

        private readonly Dictionary<string, Finding> _found = new Dictionary<string, Finding>();

        [UnityTest, Timeout(3600000)]
        public IEnumerator EveryScenarioFollowsTheDesignRules()
        {
            foreach (var phone in Phones)
            foreach (var scenario in Scenarios.All)
            {
                var run = ScenarioRun.Start(scenario, phone.x, phone.y);
                try
                {
                    yield return run.Settle();
                    Audit(run, scenario.Name, phone);
                }
                finally
                {
                    run.Stop();
                }
                yield return null;
            }
            Compare();
        }

        // ---- the three rules ------------------------------------------------------------------------

        private void Audit(ScenarioRun run, string scenario, Vector2Int phone)
        {
            Canvas.ForceUpdateCanvases();
            var root = run.Stage.Root.transform;
            var layers = new Layers(root, run.Stage);
            var texts = root.GetComponentsInChildren<TMP_Text>(false).Where(t => Shown(t) && layers.InFront(t.transform)).ToList();
            foreach (var t in texts) t.ForceMeshUpdate();

            foreach (var t in texts) CheckTextSize(t, root, scenario, phone);
            foreach (var control in Controls(root).Where(c => layers.InFront(c))) CheckTarget(control, root, scenario, phone);
            CheckContrast(run, texts, layers, root, scenario, phone);
        }

        /// <summary>
        /// What covers what, from draw order (uGUI draws a canvas in hierarchy order). A dialog, sheet, menu or
        /// page puts a full-screen scrim or backdrop over the screen: what is drawn before the topmost one can be
        /// neither read nor tapped, so it is left to the scenarios that show that screen bare. Smaller opaque
        /// shapes drawn later (a toast, the next card in a fan) hide the glyphs under them from the contrast check.
        /// </summary>
        private sealed class Layers
        {
            private readonly Dictionary<Transform, int> _index = new Dictionary<Transform, int>();
            private readonly Dictionary<Transform, int> _subtreeEnd = new Dictionary<Transform, int>();
            private readonly List<(int index, Rect rect, List<Rect> clips)> _opaque = new List<(int, Rect, List<Rect>)>();
            private readonly int _cutoff = -1;

            public Layers(Transform root, Shots.Stage stage)
            {
                var order = root.GetComponentsInChildren<Transform>(false);
                for (var i = 0; i < order.Length; i++) _index[order[i]] = i;
                // A node's subtree ends where the next node that is not its descendant begins.
                for (var i = order.Length - 1; i >= 0; i--)
                {
                    var end = i;
                    for (var c = order[i].childCount - 1; c >= 0; c--)
                        if (_subtreeEnd.TryGetValue(order[i].GetChild(c), out var childEnd)) { end = childEnd; break; }
                    _subtreeEnd[order[i]] = end;
                }
                var screenArea = (float)stage.Width * stage.Height;
                for (var i = 0; i < order.Length; i++)
                {
                    var t = order[i];
                    if (!(t is RectTransform rt)) continue;
                    var rect = ScreenRect(rt, stage.Camera);
                    var graphic = t.GetComponent<Graphic>();
                    var solid = graphic != null && graphic.enabled && !(graphic is TMP_Text)
                                && Alpha(t, graphic.color.a) >= OpaqueAlpha;
                    var fullScreen = rect.width * rect.height >= FullScreenShare * screenArea;
                    if (fullScreen && (t.GetComponent<Pressable>() != null || (solid && graphic.raycastTarget))) _cutoff = i;
                    if (solid && !fullScreen) _opaque.Add((i, rect, Clips(t, stage.Camera)));
                }
            }

            public bool InFront(Transform t) => !_index.TryGetValue(t, out var i) || i > _cutoff;

            /// <summary>True when an opaque shape drawn after <paramref name="text"/> covers <paramref name="point"/>.</summary>
            public bool Covered(Transform text, Vector2 point)
            {
                if (!_subtreeEnd.TryGetValue(text, out var end)) return false;
                foreach (var (index, rect, clips) in _opaque)
                    if (index > end && rect.Contains(point) && clips.All(c => c.Contains(point))) return true;
                return false;
            }
        }

        private const float OpaqueAlpha = 0.9f;
        private const float FullScreenShare = 0.9f;

        private static Rect ScreenRect(RectTransform rt, Camera cam)
        {
            var corners = new Vector3[4];
            rt.GetWorldCorners(corners);
            var a = (Vector2)cam.WorldToScreenPoint(corners[0]);
            var b = (Vector2)cam.WorldToScreenPoint(corners[2]);
            return Rect.MinMaxRect(Mathf.Min(a.x, b.x), Mathf.Min(a.y, b.y), Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y));
        }

        private void CheckTextSize(TMP_Text t, Transform root, string scenario, Vector2Int phone)
        {
            var scale = TextFloor.OnScreenScale(t.transform);
            var info = t.textInfo;
            var smallest = float.MaxValue;
            for (var i = 0; i < info.characterCount; i++)
            {
                var ch = info.characterInfo[i];
                if (!ch.isVisible) continue;
                smallest = Mathf.Min(smallest, ch.pointSize * scale);
            }
            if (smallest == float.MaxValue || smallest >= Blackjack.Game.UI.Type.Floor - SizeTolerance) return;
            Report("text", scenario, Dump.PathOf(t.transform, root), smallest, true, phone,
                $"{smallest:0.#}u \"{Excerpt(t)}\"");
        }

        private void CheckTarget(RectTransform control, Transform root, string scenario, Vector2Int phone)
        {
            var scale = TextFloor.OnScreenScale(control);
            var size = control.rect.size * scale;
            var least = Mathf.Min(size.x, size.y);
            if (least >= Theme.MinTarget - TargetTolerance) return;
            Report("target", scenario, Dump.PathOf(control, root), least, true, phone, $"{size.x:0}x{size.y:0}u");
        }

        /// <summary>The same screen drawn twice: as it is, and with the labels and outlines under test faded out.</summary>
        private sealed class Frames
        {
            public Shots.Stage Stage;
            public Color32[] Shown;
            public Color32[] Background;
        }

        private void CheckContrast(ScenarioRun run, List<TMP_Text> texts, Layers layers, Transform root,
            string scenario, Vector2Int phone)
        {
            var borders = root.GetComponentsInChildren<ControlBorder>(false)
                .Where(b => layers.InFront(b.transform))
                .Select(b => b.GetComponent<Image>())
                .Where(img => img != null && img.enabled && !Disabled(img.transform) && Alpha(img.transform, img.color.a) > HiddenAlpha)
                .ToList();

            // The faded frame is the real background (shader felt, gradients, card art) each glyph and outline is
            // read against; comparing it with the normal frame tells whether the glyph shows at all, or is covered.
            var shown = Shots.Render(run.Stage);
            var hidden = new List<CanvasRenderer>();
            foreach (var t in texts) hidden.AddRange(t.GetComponentsInChildren<CanvasRenderer>(false));
            foreach (var b in borders) hidden.Add(b.canvasRenderer);
            foreach (var r in hidden) r.SetAlpha(0f);
            var background = Shots.Render(run.Stage);
            foreach (var r in hidden) r.SetAlpha(1f);
            var frames = new Frames { Stage = run.Stage, Shown = shown.GetPixels32(), Background = background.GetPixels32() };
            if (Environment.GetEnvironmentVariable("BJ_RULES_DEBUG") == "1")
                Shots.Save(background, $"debug_{scenario}_{phone.x}x{phone.y}_bg");
            UnityEngine.Object.Destroy(shown);
            UnityEngine.Object.Destroy(background);

            foreach (var t in texts)
            {
                if (Disabled(t.transform)) continue;
                var worst = WorstTextRatio(t, frames, layers);
                if (worst >= Contrast.TextMinimum) continue;
                Report("contrast", scenario, Dump.PathOf(t.transform, root), worst, true, phone, $"{worst:0.00}:1 \"{Excerpt(t)}\"");
            }
            foreach (var b in borders)
            {
                var ratio = BorderRatio(b, frames);
                if (ratio >= Contrast.GraphicMinimum) continue;
                Report("border", scenario, Dump.PathOf(b.transform, root), ratio, true, phone, $"{ratio:0.00}:1");
            }
        }

        private static double WorstTextRatio(TMP_Text t, Frames f, Layers layers)
        {
            var info = t.textInfo;
            var groupAlpha = Alpha(t.transform, 1f);
            var clips = Clips(t.transform, f.Stage.Camera);
            var worst = double.MaxValue;
            for (var i = 0; i < info.characterCount; i++)
            {
                var ch = info.characterInfo[i];
                if (!ch.isVisible) continue;
                var a = ScreenPoint(f.Stage.Camera, t.transform, ch.bottomLeft);
                var b = ScreenPoint(f.Stage.Camera, t.transform, ch.topRight);
                var box = Rect.MinMaxRect(Mathf.Min(a.x, b.x), Mathf.Min(a.y, b.y), Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y));
                if (!Visible(box.center, f.Stage, clips) || layers.Covered(t.transform, box.center)) continue;
                var c = (Color)ch.color;
                var ratio = RatioIfVisible(new Rgba(c.r, c.g, c.b, c.a * groupAlpha), box, f);
                if (ratio.HasValue) worst = Math.Min(worst, ratio.Value);
            }
            return worst;
        }

        private static double BorderRatio(Image ring, Frames f)
        {
            var rt = ring.rectTransform;
            var corners = new Vector3[4];
            rt.GetWorldCorners(corners);
            var lo = (Vector2)f.Stage.Camera.WorldToScreenPoint(corners[0]);
            var hi = (Vector2)f.Stage.Camera.WorldToScreenPoint(corners[2]);
            var band = Mathf.Max(1f, 1.5f * (hi.y - lo.y) / Mathf.Max(1f, rt.rect.height));
            // Sample the four edges at their midpoints, away from the rounded corners.
            var mid = (lo + hi) / 2f;
            var edges = new[]
            {
                new Rect(mid.x - 4, lo.y, 8, band), new Rect(mid.x - 4, hi.y - band, 8, band),
                new Rect(lo.x, mid.y - 4, band, 8), new Rect(hi.x - band, mid.y - 4, band, 8),
            };
            var c = ring.color;
            var outline = new Rgba(c.r, c.g, c.b, c.a * Alpha(ring.transform, 1f));
            var worst = double.MaxValue;
            foreach (var e in edges)
            {
                var ratio = RatioIfVisible(outline, e, f);
                if (ratio.HasValue) worst = Math.Min(worst, ratio.Value);
            }
            return worst;
        }

        /// <summary>
        /// The ratio of <paramref name="mark"/> over what lies under <paramref name="box"/>, or null when the mark
        /// is not actually on screen there: it should change the pixels clearly, and the shown frame barely does
        /// (a toast or menu drawn over it).
        /// </summary>
        private static double? RatioIfVisible(Rgba mark, Rect box, Frames f)
        {
            if (!Average(f.Background, f.Stage, box, out var under)) return null;
            var expected = Distance(Contrast.Over(mark, under), under);
            if (expected > CoveredExpectation && MeanDifference(f, box) < CoveredShare * expected) return null;
            return Contrast.RatioOver(mark, under);
        }

        private const double CoveredExpectation = 0.08;
        private const double CoveredShare = 0.05;

        private static double Distance(Rgba a, Rgba b) =>
            Math.Max(Math.Abs(a.R - b.R), Math.Max(Math.Abs(a.G - b.G), Math.Abs(a.B - b.B)));

        private static double MeanDifference(Frames f, Rect box)
        {
            // Every pixel, not a sample grid: a thin stroke ("1", "l") would fall between grid points.
            var (x0, x1, y0, y1, _, _) = Grid(f.Stage, box);
            double sum = 0;
            var n = 0;
            for (var y = y0; y <= y1; y++)
            for (var x = x0; x <= x1; x++)
            {
                var a = f.Shown[y * f.Stage.Width + x];
                var b = f.Background[y * f.Stage.Width + x];
                sum += Math.Max(Math.Abs(a.r - b.r), Math.Max(Math.Abs(a.g - b.g), Math.Abs(a.b - b.b))) / 255.0;
                n++;
            }
            return n == 0 ? 0 : sum / n;
        }

        // ---- what counts --------------------------------------------------------------------------

        private static bool Shown(TMP_Text t) =>
            t.enabled && t.isActiveAndEnabled && !string.IsNullOrWhiteSpace(t.text)
            && Alpha(t.transform, t.color.a) > HiddenAlpha;

        /// <summary>Every tap target: the app's own <see cref="Pressable"/> and any stock uGUI selectable.</summary>
        private static IEnumerable<RectTransform> Controls(Transform root)
        {
            var seen = new HashSet<Transform>();
            foreach (var p in root.GetComponentsInChildren<Pressable>(false))
                if (p.enabled && Alpha(p.transform, 1f) > HiddenAlpha && seen.Add(p.transform)) yield return (RectTransform)p.transform;
            foreach (var s in root.GetComponentsInChildren<Selectable>(false))
                if (s.enabled && Alpha(s.transform, 1f) > HiddenAlpha && seen.Add(s.transform)) yield return (RectTransform)s.transform;
        }

        /// <summary>Disabled controls are exempt from contrast (WCAG 1.4.3), though not from the size rules.</summary>
        private static bool Disabled(Transform t)
        {
            for (var p = t; p != null; p = p.parent)
            {
                var pressable = p.GetComponent<Pressable>();
                if (pressable != null && !pressable.Interactable) return true;
                var selectable = p.GetComponent<Selectable>();
                if (selectable != null && !selectable.interactable) return true;
            }
            return false;
        }

        /// <summary>The alpha a node is drawn with: its own times every CanvasGroup above it.</summary>
        private static float Alpha(Transform t, float own)
        {
            var alpha = own;
            for (var p = t; p != null; p = p.parent)
            {
                foreach (var g in p.GetComponents<CanvasGroup>())
                {
                    if (!g.enabled) continue;
                    alpha *= g.alpha;
                    if (g.ignoreParentGroups) return alpha;
                }
            }
            return alpha;
        }

        // ---- pixels -------------------------------------------------------------------------------

        private static Vector2 ScreenPoint(Camera cam, Transform t, Vector3 local) =>
            cam.WorldToScreenPoint(t.TransformPoint(local));

        private static List<Rect> Clips(Transform t, Camera cam)
        {
            var clips = new List<Rect>();
            var corners = new Vector3[4];
            for (var p = t.parent; p != null; p = p.parent)
            {
                var mask = p.GetComponent<RectMask2D>();
                if (mask == null || !mask.enabled) continue;
                ((RectTransform)p).GetWorldCorners(corners);
                var a = (Vector2)cam.WorldToScreenPoint(corners[0]);
                var b = (Vector2)cam.WorldToScreenPoint(corners[2]);
                clips.Add(Rect.MinMaxRect(Mathf.Min(a.x, b.x), Mathf.Min(a.y, b.y), Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y)));
            }
            return clips;
        }

        private static bool Visible(Vector2 point, Shots.Stage stage, List<Rect> clips) =>
            point.x >= 0 && point.y >= 0 && point.x < stage.Width && point.y < stage.Height && clips.All(c => c.Contains(point));

        private static (int x0, int x1, int y0, int y1, int stepX, int stepY) Grid(Shots.Stage stage, Rect box)
        {
            var x0 = Mathf.Clamp(Mathf.FloorToInt(box.xMin), 0, stage.Width - 1);
            var x1 = Mathf.Clamp(Mathf.CeilToInt(box.xMax), 0, stage.Width - 1);
            var y0 = Mathf.Clamp(Mathf.FloorToInt(box.yMin), 0, stage.Height - 1);
            var y1 = Mathf.Clamp(Mathf.CeilToInt(box.yMax), 0, stage.Height - 1);
            var stepX = Mathf.Max(1, (x1 - x0 + 1) / MaxSamplesPerAxis);
            var stepY = Mathf.Max(1, (y1 - y0 + 1) / MaxSamplesPerAxis);
            return (x0, x1, y0, y1, stepX, stepY);
        }

        private static bool Average(Color32[] pixels, Shots.Stage stage, Rect box, out Rgba colour)
        {
            colour = default;
            var (x0, x1, y0, y1, stepX, stepY) = Grid(stage, box);
            if (x1 < x0 || y1 < y0) return false;
            double r = 0, g = 0, b = 0;
            var n = 0;
            for (var y = y0; y <= y1; y += stepY)
            for (var x = x0; x <= x1; x += stepX)
            {
                var p = pixels[y * stage.Width + x];
                r += p.r; g += p.g; b += p.b;
                n++;
            }
            if (n == 0) return false;
            colour = new Rgba(r / n / 255.0, g / n / 255.0, b / n / 255.0);
            return true;
        }

        // ---- the ratchet ----------------------------------------------------------------------------

        private static string Excerpt(TMP_Text t)
        {
            var s = t.text.Replace("\n", " ");
            return s.Length > 32 ? s.Substring(0, 32) + "…" : s;
        }

        private void Report(string rule, string scenario, string path, double value, bool lowerIsWorse, Vector2Int phone, string detail)
        {
            var key = $"{rule}\t{scenario}\t{path}";
            var at = $"{detail} at {phone.x}x{phone.y}";
            if (_found.TryGetValue(key, out var known))
            {
                var worse = lowerIsWorse ? value < known.Worst : value > known.Worst;
                if (!worse) return;
                known.Worst = value;
                known.Detail = at;
                return;
            }
            _found[key] = new Finding { Key = key, Detail = at, Worst = value, LowerIsWorse = lowerIsWorse };
        }

        private void Compare()
        {
            var report = new StringBuilder();
            foreach (var f in _found.Values.OrderBy(f => f.Key, StringComparer.Ordinal)) report.Append(f.Key).Append("\t# ").AppendLine(f.Detail);
            File.WriteAllText(Path.Combine(Shots.OutDir, "rules-report.txt"), report.ToString());

            var filtered = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("BJ_SCENARIO"));
            if (Environment.GetEnvironmentVariable("BJ_RULES_BASELINE") == "write")
            {
                Assert.IsFalse(filtered, "Write the baseline from a full run, not one narrowed by BJ_SCENARIO.");
                var header = "# Known design-rule violations (RulesAudit). This file only shrinks: fix one, delete its line.\n"
                             + "# rule<TAB>scenario<TAB>path   — regenerate with BJ_RULES_BASELINE=write.\n";
                File.WriteAllText(BaselinePath, header + string.Join("\n", _found.Keys.OrderBy(k => k, StringComparer.Ordinal)) + "\n");
                Debug.Log($"RulesAudit: wrote {_found.Count} baseline entries to {BaselinePath}");
                return;
            }

            var baseline = File.Exists(BaselinePath)
                ? new HashSet<string>(File.ReadAllLines(BaselinePath).Select(l => l.Split('#')[0].TrimEnd()).Where(l => l.Length > 0))
                : new HashSet<string>();
            var fresh = _found.Values.Where(f => !baseline.Contains(f.Key)).OrderBy(f => f.Key, StringComparer.Ordinal).ToList();
            var fixedKeys = filtered ? new List<string>()
                : baseline.Where(k => !_found.ContainsKey(k)).OrderBy(k => k, StringComparer.Ordinal).ToList();

            var message = new StringBuilder();
            if (fresh.Count > 0)
            {
                message.AppendLine($"{fresh.Count} new design-rule violation(s):");
                foreach (var f in fresh) message.Append("  ").Append(f.Key.Replace('\t', ' ')).Append("  — ").AppendLine(f.Detail);
            }
            if (fixedKeys.Count > 0)
            {
                message.AppendLine($"{fixedKeys.Count} violation(s) are fixed; delete these lines from rules-baseline.txt:");
                foreach (var k in fixedKeys) message.Append("  ").AppendLine(k.Replace('\t', ' '));
            }
            Debug.Log($"RulesAudit: {_found.Count} violations, {baseline.Count} in the baseline, {fresh.Count} new, {fixedKeys.Count} fixed.");
            if (message.Length > 0) Assert.Fail(message.ToString());
        }
    }
}
