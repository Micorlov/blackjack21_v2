using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.TextCore.LowLevel;

namespace Blackjack.Game.UI
{
    public enum FontKind { Sora, SoraSemiBold, SoraBold, SerifItalic, Mono, MonoBold }

    /// <summary>
    /// TextMeshPro font assets built at runtime from the bundled TTFs (Resources/Fonts), with the
    /// phone's own Noto fonts as fallbacks for Hebrew, Arabic and CJK so no script needs bundling.
    /// </summary>
    public static class Fonts
    {
        private static readonly Dictionary<FontKind, TMP_FontAsset> Cache = new Dictionary<FontKind, TMP_FontAsset>();
        private static readonly List<TMP_FontAsset> _fallbacks = new List<TMP_FontAsset>();

        private static readonly Dictionary<FontKind, string> Files = new Dictionary<FontKind, string>
        {
            { FontKind.Sora, "Fonts/Sora-Regular" },
            { FontKind.SoraSemiBold, "Fonts/Sora-SemiBold" },
            { FontKind.SoraBold, "Fonts/Sora-Bold" },
            { FontKind.SerifItalic, "Fonts/InstrumentSerif-Italic" },
            { FontKind.Mono, "Fonts/SpaceMono-Regular" },
            { FontKind.MonoBold, "Fonts/SpaceMono-Bold" },
        };

        // File-name fragments of the system fonts that cover each script we localise into. System fonts
        // can be tens of MB, so a script's font is only opened once its language is actually in use.
        private static readonly Dictionary<string, string[]> ScriptHints = new Dictionary<string, string[]>
        {
            { "ar", new[] { "notosansarabic", "notonaskharabic", "geezamix" } },
            { "he", new[] { "notosanshebrew" } },
            { "ja", new[] { "notosanscjkjp", "notosansjp", "notosanscjk", "droidsansfallback" } },
            { "zh", new[] { "notosanscjksc", "notosanssc", "notosanscjk", "droidsansfallback" } },
        };

        private static readonly HashSet<string> LoadedScripts = new HashSet<string>();

        public static TMP_FontAsset Get(FontKind kind)
        {
            if (Cache.TryGetValue(kind, out var cached)) return cached;
            var font = Resources.Load<Font>(Files[kind]);
            var asset = TMP_FontAsset.CreateFontAsset(font, 90, 9, GlyphRenderMode.SDFAA, 1024, 1024,
                AtlasPopulationMode.Dynamic, true);
            asset.name = kind.ToString();
            asset.fallbackFontAssetTable = new List<TMP_FontAsset>(_fallbacks);
            Cache[kind] = asset;
            return asset;
        }

        /// <summary>
        /// Makes sure glyphs for the language's script can be drawn, adding the phone's own font for it as a
        /// fallback on every font already built (and on any built later). No-op for Latin/Cyrillic languages.
        /// </summary>
        public static void EnsureScript(string languageCode)
        {
            if (!ScriptHints.TryGetValue(languageCode, out var hints) || !LoadedScripts.Add(languageCode)) return;

            string[] paths;
            try { paths = Font.GetPathsToOSFonts(); }
            catch (System.Exception e)
            {
                Debug.LogWarning("No OS font list: " + e.Message);
                return;
            }

            foreach (var hint in hints)
            {
                foreach (var path in paths)
                {
                    var file = System.IO.Path.GetFileName(path).ToLowerInvariant().Replace("-", "").Replace("_", "").Replace(" ", "");
                    if (!file.Contains(hint) || file.Contains("italic") || file.Contains("bold")) continue;
                    try
                    {
                        var asset = TMP_FontAsset.CreateFontAsset(new Font(path), 90, 9, GlyphRenderMode.SDFAA, 1024, 1024,
                            AtlasPopulationMode.Dynamic, true);
                        if (asset == null) continue;
                        asset.name = "System:" + System.IO.Path.GetFileName(path);
                        _fallbacks.Add(asset);
                        foreach (var built in Cache.Values) built.fallbackFontAssetTable.Add(asset);
                        return;
                    }
                    catch (System.Exception e)
                    {
                        Debug.LogWarning("Skipping system font " + path + ": " + e.Message);
                    }
                }
            }
        }
    }
}
