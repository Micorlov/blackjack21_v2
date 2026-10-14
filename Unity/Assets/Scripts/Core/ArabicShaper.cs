using System.Collections.Generic;
using System.Text;

namespace Blackjack.Core
{
    /// <summary>
    /// Arabic letter shaping: replaces each letter with its isolated / final / initial / medial presentation form
    /// (U+FE70–FEFF) according to its neighbours, and joins lam+alef into their ligatures. The output stays in
    /// logical order; <see cref="Bidi"/> reorders it for display. Text engines that do not shape (uGUI's TextMesh
    /// Pro) show unshaped Arabic as disconnected isolated letters.
    /// </summary>
    public static class ArabicShaper
    {
        // isolated, final, initial, medial (0 where the letter does not join on that side)
        private static readonly Dictionary<char, char[]> Forms = new Dictionary<char, char[]>
        {
            ['ء'] = new[] { 'ﺀ', '\0', '\0', '\0' },
            ['آ'] = new[] { 'ﺁ', 'ﺂ', '\0', '\0' },
            ['أ'] = new[] { 'ﺃ', 'ﺄ', '\0', '\0' },
            ['ؤ'] = new[] { 'ﺅ', 'ﺆ', '\0', '\0' },
            ['إ'] = new[] { 'ﺇ', 'ﺈ', '\0', '\0' },
            ['ئ'] = new[] { 'ﺉ', 'ﺊ', 'ﺋ', 'ﺌ' },
            ['ا'] = new[] { 'ﺍ', 'ﺎ', '\0', '\0' },
            ['ب'] = new[] { 'ﺏ', 'ﺐ', 'ﺑ', 'ﺒ' },
            ['ة'] = new[] { 'ﺓ', 'ﺔ', '\0', '\0' },
            ['ت'] = new[] { 'ﺕ', 'ﺖ', 'ﺗ', 'ﺘ' },
            ['ث'] = new[] { 'ﺙ', 'ﺚ', 'ﺛ', 'ﺜ' },
            ['ج'] = new[] { 'ﺝ', 'ﺞ', 'ﺟ', 'ﺠ' },
            ['ح'] = new[] { 'ﺡ', 'ﺢ', 'ﺣ', 'ﺤ' },
            ['خ'] = new[] { 'ﺥ', 'ﺦ', 'ﺧ', 'ﺨ' },
            ['د'] = new[] { 'ﺩ', 'ﺪ', '\0', '\0' },
            ['ذ'] = new[] { 'ﺫ', 'ﺬ', '\0', '\0' },
            ['ر'] = new[] { 'ﺭ', 'ﺮ', '\0', '\0' },
            ['ز'] = new[] { 'ﺯ', 'ﺰ', '\0', '\0' },
            ['س'] = new[] { 'ﺱ', 'ﺲ', 'ﺳ', 'ﺴ' },
            ['ش'] = new[] { 'ﺵ', 'ﺶ', 'ﺷ', 'ﺸ' },
            ['ص'] = new[] { 'ﺹ', 'ﺺ', 'ﺻ', 'ﺼ' },
            ['ض'] = new[] { 'ﺽ', 'ﺾ', 'ﺿ', 'ﻀ' },
            ['ط'] = new[] { 'ﻁ', 'ﻂ', 'ﻃ', 'ﻄ' },
            ['ظ'] = new[] { 'ﻅ', 'ﻆ', 'ﻇ', 'ﻈ' },
            ['ع'] = new[] { 'ﻉ', 'ﻊ', 'ﻋ', 'ﻌ' },
            ['غ'] = new[] { 'ﻍ', 'ﻎ', 'ﻏ', 'ﻐ' },
            ['ف'] = new[] { 'ﻑ', 'ﻒ', 'ﻓ', 'ﻔ' },
            ['ق'] = new[] { 'ﻕ', 'ﻖ', 'ﻗ', 'ﻘ' },
            ['ك'] = new[] { 'ﻙ', 'ﻚ', 'ﻛ', 'ﻜ' },
            ['ل'] = new[] { 'ﻝ', 'ﻞ', 'ﻟ', 'ﻠ' },
            ['م'] = new[] { 'ﻡ', 'ﻢ', 'ﻣ', 'ﻤ' },
            ['ن'] = new[] { 'ﻥ', 'ﻦ', 'ﻧ', 'ﻨ' },
            ['ه'] = new[] { 'ﻩ', 'ﻪ', 'ﻫ', 'ﻬ' },
            ['و'] = new[] { 'ﻭ', 'ﻮ', '\0', '\0' },
            ['ى'] = new[] { 'ﻯ', 'ﻰ', '\0', '\0' },
            ['ي'] = new[] { 'ﻱ', 'ﻲ', 'ﻳ', 'ﻴ' },
        };

        // lam + alef variants: isolated and final ligature forms.
        private static readonly Dictionary<char, char[]> LamAlef = new Dictionary<char, char[]>
        {
            ['آ'] = new[] { 'ﻵ', 'ﻶ' },
            ['أ'] = new[] { 'ﻷ', 'ﻸ' },
            ['إ'] = new[] { 'ﻹ', 'ﻺ' },
            ['ا'] = new[] { 'ﻻ', 'ﻼ' },
        };

        private const int Isolated = 0, Final = 1, Initial = 2, Medial = 3;

        public static bool IsArabicLetter(char c) => Forms.ContainsKey(c);

        // Tashkeel (vowel marks) are transparent: they neither join nor break a join.
        private static bool IsMark(char c) => (c >= 'ً' && c <= 'ٟ') || c == 'ٰ';

        /// <summary>True if the character connects to the letter that follows it (in logical order).</summary>
        private static bool JoinsNext(char c) => Forms.TryGetValue(c, out var f) && f[Initial] != '\0';

        /// <summary>True if the character can connect to a letter before it.</summary>
        private static bool JoinsPrev(char c) => Forms.TryGetValue(c, out var f) && f[Final] != '\0';

        public static bool ContainsArabic(string text)
        {
            foreach (var c in text) if (Forms.ContainsKey(c)) return true;
            return false;
        }

        public static string Shape(string text)
        {
            if (string.IsNullOrEmpty(text) || !ContainsArabic(text)) return text;
            var sb = new StringBuilder(text.Length);
            for (var i = 0; i < text.Length; i++)
            {
                var c = text[i];
                if (!Forms.TryGetValue(c, out var forms)) { sb.Append(c); continue; }

                var prev = PreviousLetter(text, i);
                var joinsBefore = prev != '\0' && JoinsNext(prev);

                // lam followed (past any marks) by alef becomes a single ligature.
                if (c == 'ل')
                {
                    var next = NextIndex(text, i);
                    if (next >= 0 && LamAlef.TryGetValue(text[next], out var lig))
                    {
                        sb.Append(joinsBefore ? lig[1] : lig[0]);
                        // Keep any marks that sat between the two letters, then skip the alef.
                        for (var m = i + 1; m < next; m++) sb.Append(text[m]);
                        i = next;
                        continue;
                    }
                }

                var nextLetter = NextLetter(text, i);
                var joinsAfter = forms[Initial] != '\0' && nextLetter != '\0' && JoinsPrev(nextLetter);
                int form;
                if (joinsBefore && joinsAfter) form = Medial;
                else if (joinsBefore) form = Final;
                else if (joinsAfter) form = Initial;
                else form = Isolated;
                var shaped = forms[form];
                sb.Append(shaped != '\0' ? shaped : forms[Isolated]);
            }
            return sb.ToString();
        }

        private static char PreviousLetter(string text, int index)
        {
            for (var i = index - 1; i >= 0; i--)
            {
                if (IsMark(text[i])) continue;
                return Forms.ContainsKey(text[i]) ? text[i] : '\0';
            }
            return '\0';
        }

        private static char NextLetter(string text, int index)
        {
            var next = NextIndex(text, index);
            return next >= 0 && Forms.ContainsKey(text[next]) ? text[next] : '\0';
        }

        private static int NextIndex(string text, int index)
        {
            for (var i = index + 1; i < text.Length; i++)
            {
                if (IsMark(text[i])) continue;
                return i;
            }
            return -1;
        }
    }
}
