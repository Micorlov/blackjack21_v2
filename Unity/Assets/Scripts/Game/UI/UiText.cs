using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// A TextMeshPro label that reads right-to-left languages correctly. uGUI's TMP neither shapes Arabic nor
    /// reorders bidirectional text, so in Hebrew/Arabic this shapes letters, breaks the paragraph into lines
    /// itself (in reading order) and reorders each line for display. Everything else uses plain TMP.
    /// Assign <see cref="text"/> as usual — it holds the logical string.
    /// </summary>
    public sealed class UiText : TextMeshProUGUI
    {
        private string _logical = "";
        private TextAlignmentOptions _logicalAlignment = TextAlignmentOptions.TopLeft;
        private float _logicalSpacing;
        private float _wrappedAt = -1f;

        /// <summary>The string as authored (logical order), regardless of what is displayed.</summary>
        public string Logical => _logical;

        public override string text
        {
            get => _logical;
            set
            {
                _logical = value ?? "";
                Reflow();
            }
        }

        /// <summary>Sets the alignment as authored for left-to-right; right-to-left languages get the mirror image.</summary>
        public void SetAlignment(TextAlignmentOptions logical)
        {
            _logicalAlignment = logical;
            alignment = Loc.IsRtl ? Mirror(logical) : logical;
        }

        public void SetSpacing(float spacing)
        {
            _logicalSpacing = spacing;
            // Extra tracking would pull Arabic's joined letters apart.
            characterSpacing = Loc.Code == "ar" ? 0f : spacing;
        }

        protected override void OnRectTransformDimensionsChange()
        {
            base.OnRectTransformDimensionsChange();
            if (!Loc.IsRtl || textWrappingMode != TextWrappingModes.Normal) return;
            var width = rectTransform.rect.width;
            if (Mathf.Abs(width - _wrappedAt) < 0.5f) return;
            Reflow();
        }

        private void Reflow()
        {
            if (!Loc.IsRtl || _logical.IndexOf('<') >= 0)
            {
                base.text = _logical;
                return;
            }
            var shaped = ArabicShaper.Shape(_logical);
            if (!Bidi.ContainsRtl(shaped))
            {
                base.text = shaped;
                return;
            }
            var width = rectTransform.rect.width;
            _wrappedAt = width;
            base.text = textWrappingMode == TextWrappingModes.Normal && width > 1f
                ? string.Join("\n", Wrap(shaped, width).Select(Bidi.Visual))
                : Bidi.Visual(shaped);
        }

        // Greedy line breaking on spaces, in logical order, using TMP's own measurement of an unwrapped line.
        private List<string> Wrap(string shaped, float width)
        {
            var lines = new List<string>();
            var current = "";
            foreach (var word in shaped.Split(' '))
            {
                var candidate = current.Length == 0 ? word : current + " " + word;
                var measured = GetPreferredValues(candidate, 100000f, 100000f).x;
                if (measured <= width || current.Length == 0) current = candidate;
                else { lines.Add(current); current = word; }
            }
            lines.Add(current);
            return lines;
        }

        public static TextAlignmentOptions Mirror(TextAlignmentOptions a)
        {
            switch (a)
            {
                case TextAlignmentOptions.TopLeft: return TextAlignmentOptions.TopRight;
                case TextAlignmentOptions.TopRight: return TextAlignmentOptions.TopLeft;
                case TextAlignmentOptions.Left: return TextAlignmentOptions.Right;
                case TextAlignmentOptions.Right: return TextAlignmentOptions.Left;
                case TextAlignmentOptions.BottomLeft: return TextAlignmentOptions.BottomRight;
                case TextAlignmentOptions.BottomRight: return TextAlignmentOptions.BottomLeft;
                case TextAlignmentOptions.BaselineLeft: return TextAlignmentOptions.BaselineRight;
                case TextAlignmentOptions.BaselineRight: return TextAlignmentOptions.BaselineLeft;
                default: return a;
            }
        }
    }
}
