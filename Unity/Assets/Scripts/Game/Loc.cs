using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

namespace Blackjack.Game
{
    /// <summary>
    /// Localised strings from Resources/Locales/&lt;code&gt;.json (converted from the Flutter ARB files).
    /// Missing keys fall back to English, then to the key itself. Placeholders are <c>{name}</c>.
    /// </summary>
    public static class Loc
    {
        public static readonly string[] Supported = { "en", "es", "fr", "de", "pt", "ru", "zh", "ja", "he", "ar" };

        private static readonly Dictionary<string, Dictionary<string, string>> Tables =
            new Dictionary<string, Dictionary<string, string>>();

        private static string _code = "en";

        public static event Action Changed;

        public static string Code => _code;

        public static bool IsRtl => _code == "he" || _code == "ar";

        /// <summary>Applies an explicit choice, or the device language when <paramref name="overrideCode"/> is null.</summary>
        public static void Use(string overrideCode)
        {
            var code = overrideCode ?? DeviceCode();
            if (Array.IndexOf(Supported, code) < 0) code = "en";
            if (code == _code) return;
            _code = code;
            UI.Fonts.EnsureScript(code);
            // Every string of the language goes into the font atlases now, so text measures correctly on first draw.
            UI.Fonts.Prewarm(string.Concat(Table(code).Values));
            Changed?.Invoke();
        }

        public static string DeviceCode() => Application.systemLanguage switch
        {
            SystemLanguage.Spanish => "es",
            SystemLanguage.French => "fr",
            SystemLanguage.German => "de",
            SystemLanguage.Portuguese => "pt",
            SystemLanguage.Russian => "ru",
            SystemLanguage.Chinese or SystemLanguage.ChineseSimplified or SystemLanguage.ChineseTraditional => "zh",
            SystemLanguage.Japanese => "ja",
            SystemLanguage.Hebrew => "he",
            SystemLanguage.Arabic => "ar",
            _ => "en",
        };

        private static Dictionary<string, string> Table(string code)
        {
            if (Tables.TryGetValue(code, out var table)) return table;
            var asset = Resources.Load<TextAsset>("Locales/" + code);
            table = asset == null
                ? new Dictionary<string, string>()
                : JsonConvert.DeserializeObject<Dictionary<string, string>>(asset.text);
            Tables[code] = table;
            return table;
        }

        /// <summary>The localised string if the key exists, otherwise <paramref name="english"/> (copy the Flutter app never localised).</summary>
        public static string Or(string key, string english, params (string name, object value)[] args)
        {
            var text = Has(key) ? T(key, args) : english;
            if (!Has(key))
                foreach (var (name, value) in args)
                    text = text.Replace("{" + name + "}", Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture));
            return text;
        }

        public static bool Has(string key) => Table(_code).ContainsKey(key) || Table("en").ContainsKey(key);

        public static string T(string key, params (string name, object value)[] args)
        {
            if (!Table(_code).TryGetValue(key, out var text) && !Table("en").TryGetValue(key, out text))
                return key;
            foreach (var (name, value) in args)
                text = text.Replace("{" + name + "}", Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture));
            return text;
        }

        /// <summary>Several keys joined with " / " — the coach cards title a card with two button names.</summary>
        public static string Joined(IEnumerable<string> keys)
        {
            var parts = new List<string>();
            foreach (var k in keys) parts.Add(T(k));
            return string.Join(" / ", parts);
        }
    }
}
