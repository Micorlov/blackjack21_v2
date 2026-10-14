using System;
using System.Linq;
using System.Text.RegularExpressions;

namespace Blackjack.Core
{
    public static class InviteLink
    {
        public const string Host = "blackjack21-v2.web.app";
        public const string PlayStoreUrl = "https://play.google.com/store/apps/details?id=com.micorlov.blackjack21_v2";
        public const string CodeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
        public const int CodeLength = 6;

        private static readonly Regex UrlPattern = new Regex(@"https?://\S+", RegexOptions.Compiled);

        public static string UriFor(string code) => $"https://{Host}/join/{code}";

        public static bool IsValidCode(string code) =>
            code != null && code.Length == CodeLength && code.All(c => CodeAlphabet.IndexOf(c) >= 0);

        /// <summary>Reads a join code out of an invite URL (path, query, or fragment form); null if absent or not ours.</summary>
        public static string CodeFromUri(Uri uri)
        {
            if (!string.IsNullOrEmpty(uri.Host) && uri.Host != Host) return null;

            var query = ParseQuery(uri.Query);
            if (query.TryGetValue("code", out var fromQuery))
            {
                var upper = fromQuery.ToUpperInvariant();
                return IsValidCode(upper) ? upper : null;
            }

            var segments = uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries).ToList();
            var fragment = uri.Fragment.TrimStart('#');
            if (fragment.Length > 0)
                segments.AddRange(fragment.Split('?')[0].Split('/', StringSplitOptions.RemoveEmptyEntries));

            var joinIndex = segments.IndexOf("join");
            if (joinIndex == -1 || joinIndex + 1 >= segments.Count) return null;
            var code = segments[joinIndex + 1].ToUpperInvariant();
            return IsValidCode(code) ? code : null;
        }

        /// <summary>An app route such as "/join/ABC234" (no host) or a full URL.</summary>
        public static string CodeFromRoute(string route)
        {
            if (string.IsNullOrEmpty(route)) return null;
            // A leading slash is an app route, not a file path: .NET would read it as file:///.
            var absolute = route.StartsWith("/") ? "https://" + Host + route : route;
            if (!Uri.TryCreate(absolute, UriKind.Absolute, out var uri)) return null;
            return CodeFromUri(uri);
        }

        /// <summary>A code from pasted text: an invite URL anywhere in it, or the bare code.</summary>
        public static string CodeFromText(string text)
        {
            var trimmed = (text ?? "").Trim();
            if (trimmed.Length == 0) return null;

            var match = UrlPattern.Match(trimmed);
            if (match.Success && Uri.TryCreate(match.Value, UriKind.Absolute, out var uri))
            {
                var fromUrl = CodeFromUri(uri);
                if (fromUrl != null) return fromUrl;
            }

            var bare = trimmed.ToUpperInvariant();
            return IsValidCode(bare) ? bare : null;
        }

        private static System.Collections.Generic.Dictionary<string, string> ParseQuery(string query)
        {
            var result = new System.Collections.Generic.Dictionary<string, string>();
            foreach (var pair in query.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                var kv = pair.Split(new[] { '=' }, 2);
                if (!result.ContainsKey(kv[0])) result[kv[0]] = kv.Length > 1 ? Uri.UnescapeDataString(kv[1]) : "";
            }
            return result;
        }
    }
}
