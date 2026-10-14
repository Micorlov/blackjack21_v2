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
