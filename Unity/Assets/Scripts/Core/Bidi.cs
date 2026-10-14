using System;
using System.Collections.Generic;
using System.Text;

namespace Blackjack.Core
{
    /// <summary>
    /// A small bidirectional reorderer for right-to-left paragraphs (Hebrew, Arabic): turns text in logical order
    /// into the order glyphs are laid out left to right. Hebrew/Arabic letters read right to left; Latin words and
    /// numbers (with their currency signs, separators and percent signs) keep their own left-to-right order.
    /// This is the subset of the Unicode bidi algorithm the game's strings need.
    /// </summary>
    public static class Bidi
    {
        private enum Kind { Rtl, Ltr, Number, Neutral }

        public static bool IsRtlLetter(char c) =>
            (c >= '֐' && c <= 'ࣿ') || (c >= 'יִ' && c <= '﷿') || (c >= 'ﹰ' && c <= '﻿');

        public static bool ContainsRtl(string text)
        {
            if (string.IsNullOrEmpty(text)) return false;
            foreach (var c in text) if (IsRtlLetter(c)) return true;
            return false;
        }

        private static bool IsDigit(char c) => (c >= '0' && c <= '9') || (c >= '٠' && c <= '٩') || (c >= '۰' && c <= '۹');

        private static Kind Classify(char c)
        {
            if (IsDigit(c)) return Kind.Number;
            if (IsRtlLetter(c)) return c >= 'ً' && c <= 'ٟ' ? Kind.Neutral : Kind.Rtl;   // marks follow their letter
            if (char.IsLetter(c)) return Kind.Ltr;
            return Kind.Neutral;
        }

        /// <summary>The text reordered for left-to-right layout inside a right-to-left paragraph.</summary>
        public static string Visual(string logical)
        {
            if (string.IsNullOrEmpty(logical) || !ContainsRtl(logical)) return logical;

            var n = logical.Length;
            var kind = new Kind[n];
            for (var i = 0; i < n; i++) kind[i] = Classify(logical[i]);
            AttachNumberAffixes(logical, kind);

            // Embedding levels in an RTL paragraph: RTL text sits at level 1, LTR runs and numbers at level 2.
            var level = new int[n];
            for (var i = 0; i < n; i++) level[i] = kind[i] == Kind.Rtl ? 1 : kind[i] == Kind.Neutral ? 0 : 2;
            ResolveNeutrals(kind, level);

            // Marks (diacritics) take the level of the letter they follow, so they stay attached through reordering.
            for (var i = 1; i < n; i++)
                if (logical[i] >= 'ً' && logical[i] <= 'ٟ' || logical[i] == 'ٰ') level[i] = level[i - 1];

            var order = new int[n];
            for (var i = 0; i < n; i++) order[i] = i;
            for (var l = 2; l >= 1; l--) ReverseRuns(order, level, l);

            var sb = new StringBuilder(n);
            foreach (var index in order)
            {
                var c = logical[index];
                // Mirrored glyphs: brackets at an RTL level face the other way.
                sb.Append(level[index] % 2 == 1 ? Mirror(c) : c);
            }
            return sb.ToString();
        }

        // Currency/sign characters just before a digit and a percent sign just after belong to the number, and so do
        // the separators between digits ("1,250", "3.5", "12:30").
        private static void AttachNumberAffixes(string s, Kind[] kind)
        {
            for (var i = 0; i < s.Length; i++)
            {
                var c = s[i];
                if ("$€£¢+-−".IndexOf(c) >= 0 && i + 1 < s.Length && kind[i + 1] == Kind.Number) kind[i] = Kind.Number;
                else if (c == '%' && i > 0 && kind[i - 1] == Kind.Number) kind[i] = Kind.Number;
                else if (",.:/".IndexOf(c) >= 0 && i > 0 && i + 1 < s.Length && kind[i - 1] == Kind.Number && kind[i + 1] == Kind.Number)
                    kind[i] = Kind.Number;
            }
        }

        // A neutral between two LTR/number runs joins them (level 2); otherwise it follows the paragraph (level 1).
        private static void ResolveNeutrals(Kind[] kind, int[] level)
        {
            var n = kind.Length;
            for (var i = 0; i < n; i++)
            {
                if (kind[i] != Kind.Neutral) continue;
                var start = i;
                while (i < n && kind[i] == Kind.Neutral) i++;
                var before = start > 0 ? level[start - 1] : 1;
                var after = i < n ? level[i] : 1;
                var resolved = before == 2 && after == 2 ? 2 : 1;
                for (var k = start; k < i; k++) level[k] = resolved;
                i--;
            }
        }

        // Reverse every maximal run of characters at `minLevel` or above, reordering `order` in place.
        private static void ReverseRuns(int[] order, int[] level, int minLevel)
        {
            var n = order.Length;
            var i = 0;
            while (i < n)
            {
                if (level[order[i]] < minLevel) { i++; continue; }
                var start = i;
                while (i < n && level[order[i]] >= minLevel) i++;
                Array.Reverse(order, start, i - start);
            }
        }

        private static char Mirror(char c)
        {
            switch (c)
            {
                case '(': return ')';
                case ')': return '(';
                case '[': return ']';
                case ']': return '[';
                case '{': return '}';
                case '}': return '{';
                case '<': return '>';
                case '>': return '<';
                case '«': return '»';
                case '»': return '«';
                default: return c;
            }
        }
    }
}
