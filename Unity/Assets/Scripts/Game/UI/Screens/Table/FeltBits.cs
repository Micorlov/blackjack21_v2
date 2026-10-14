using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The small pieces every part of the Seat felt is made from: pills, chip stacks, bet rings, glows.</summary>
    public static class FeltBits
    {
        /// <summary>
        /// The dark pill every name, total and figure sits in. Darker than the design's 66%: a pill often lies over a
        /// cream card, and through 66% black that card washes ivory text out below 4.5:1.
        /// </summary>
        public static readonly Color PillFill = Color.black.WithAlpha(0.8f);

        private const float StackDiameter = 24f;
        private const int ChipsPerStack = 8;
        private const int MostStacks = 3;
        private static readonly int[] Denominations = { 1000, 500, 100, 50, 25 };

        /// <summary>Places a node by its top-centre (or <paramref name="pivot"/>) at canvas units (x right, y down).</summary>
        public static RectTransform At(this RectTransform rt, float x, float y, Vector2? pivot = null)
        {
            rt.anchorMin = rt.anchorMax = new Vector2(0, 1);
            rt.pivot = pivot ?? new Vector2(0.5f, 1f);
            rt.anchoredPosition = new Vector2(x, -y);
            return rt;
        }

        /// <summary>
        /// A content-sized pill with a row inside; returns the row. <paramref name="root"/> is the outermost node, to
        /// position or hide.
        /// </summary>
        public static RectTransform Pill(Transform parent, Color fill, out RectTransform root, Color? border = null,
            string name = "Pill", float hPad = Theme.Sm, float vPad = Theme.Xxs)
        {
            var card = Ui.Card(parent, fill, Theme.RadiusPill, border, 1, Ui.Pad(hPad, vPad), 0, false, name);
            root = border.HasValue ? (RectTransform)card.parent : card;
            root.FitContent(true, true);
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            return Ui.HStack(card, Theme.Xs, null, TextAnchor.MiddleCenter, false, "Row");
        }

        /// <summary>The chips a bet is made of, by colour: the biggest denominations first, a few stacks at most.</summary>
        public static List<(Color colour, int count)> StacksFor(int amount)
        {
            var stacks = new List<(Color, int)>();
            foreach (var d in Denominations)
            {
                var n = amount / d;
                if (n == 0) continue;
                amount -= n * d;
                stacks.Add((Theme.ChipColor(d), Mathf.Min(n, ChipsPerStack)));
                if (stacks.Count == MostStacks) break;
            }
            return stacks;
        }

        /// <summary>Side-on chip stacks standing on a common baseline, for a bet or a balance.</summary>
        public static RectTransform ChipStacks(Transform parent, IEnumerable<(Color colour, int count)> stacks, float diameter = StackDiameter)
        {
            var row = Ui.HStack(parent, 3, null, TextAnchor.LowerCenter, false, "Stacks");
            row.FitContent(true, true);
            foreach (var (colour, count) in stacks)
            {
                var sprite = Gfx.ChipStack(colour, count, diameter);
                var img = Ui.Box(row, Color.white, 0, "Stack");
                img.sprite = sprite;
                img.type = Image.Type.Simple;
                img.rectTransform.Size(diameter, diameter * sprite.rect.height / sprite.rect.width);
            }
            return row;
        }

        /// <summary>The ellipse a bet sits in.</summary>
        public static Image Ring(Transform parent, float width, float height, bool dashed, Color colour, string name = "Ring")
        {
            var img = Ui.Box(parent, colour, 0, name);
            img.sprite = Gfx.BetRing(width, height, dashed);
            img.type = Image.Type.Simple;
            img.rectTransform.Size(width, height);
            return img;
        }

        /// <summary>A soft glow behind something that has the stage (the acting seat, the hero's blackjack).</summary>
        public static RawImage Glow(Transform parent, float size, Color colour, string name = "Glow")
        {
            var glow = W.Raw(parent, Gfx.Glow(), name);
            glow.color = colour;
            glow.rectTransform.IgnoreLayout();
            glow.rectTransform.PinCentre(Vector2.zero, new Vector2(size, size));
            glow.rectTransform.SetAsFirstSibling();
            return glow;
        }

        /// <summary>A one-line label in a ramp style that keeps its natural width.</summary>
        public static UiText Label(Transform parent, string text, TextStyle style, Color colour, string name = "Text") =>
            Ui.Text(parent, text, style, colour, TextAlignmentOptions.Center, false, 0, name);
    }
}
