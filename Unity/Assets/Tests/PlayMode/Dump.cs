using System.Text;
using UnityEngine;

namespace Blackjack.PlayTests
{
    /// <summary>Logs a RectTransform subtree with sizes, for debugging layouts from batch runs.</summary>
    internal static class Dump
    {
        public static string Tree(Transform root, int maxDepth = 6)
        {
            var sb = new StringBuilder();
            Walk(root, 0, maxDepth, sb);
            return sb.ToString();
        }

        /// <summary>
        /// A stable address for a node under <paramref name="root"/>: names joined by '/', with the sibling index
        /// added where siblings share a name (most labels are called "Text"). Used as the key in rules-baseline.txt.
        /// </summary>
        public static string PathOf(Transform node, Transform root)
        {
            var parts = new System.Collections.Generic.List<string>();
            for (var t = node; t != null && t != root; t = t.parent)
            {
                var name = t.name;
                var parent = t.parent;
                if (parent != null)
                {
                    var same = 0;
                    var index = 0;
                    for (var i = 0; i < parent.childCount; i++)
                    {
                        var sibling = parent.GetChild(i);
                        if (sibling.name != name) continue;
                        if (sibling == t) index = same;
                        same++;
                    }
                    if (same > 1) name += "[" + index + "]";
                }
                parts.Add(name);
            }
            parts.Reverse();
            return string.Join("/", parts);
        }

        private static void Walk(Transform t, int depth, int maxDepth, StringBuilder sb)
        {
            if (depth > maxDepth) return;
            var rt = t as RectTransform;
            var text = t.GetComponent<TMPro.TMP_Text>();
            var img = t.GetComponent<UnityEngine.UI.Image>();
            var fit = t.GetComponent<Blackjack.Game.UI.RoundedFit>();
            sb.Append(' ', depth * 2).Append(t.name)
                .Append(rt != null ? $" [{rt.rect.width:0}x{rt.rect.height:0} @{rt.anchoredPosition.x:0},{rt.anchoredPosition.y:0}]" : "")
                .Append(text != null ? $" \"{text.text}\"" : "")
                .Append(img != null ? $" img(type={img.type},mult={img.pixelsPerUnitMultiplier:0.##},prefH={img.preferredHeight:0.#},fit={(fit != null ? fit.Radius.ToString("0.#") : "none")})" : "")
                .Append(t.gameObject.activeSelf ? "" : " (off)").AppendLine();
            for (var i = 0; i < t.childCount; i++) Walk(t.GetChild(i), depth + 1, maxDepth, sb);
        }
    }
}
