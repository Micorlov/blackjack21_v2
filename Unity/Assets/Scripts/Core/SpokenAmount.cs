using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>
    /// A number as the words to say it ("one hundred twenty five" → one, hundred, twenty, five), each
    /// word naming a clip in Resources/Sfx/num. Empty for 0 or anything past <see cref="Max"/>.
    /// </summary>
    public static class SpokenAmount
    {
        public const int Max = 999999;

        private static readonly string[] Ones =
        {
            "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
            "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
        };

        private static readonly string[] Tens =
        {
            "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety",
        };

        public static IReadOnlyList<string> Words(int amount)
        {
            if (amount <= 0 || amount > Max) return new string[0];
            var words = new List<string>();
            var thousands = amount / 1000;
            if (thousands > 0)
            {
                words.AddRange(UnderThousand(thousands));
                words.Add("thousand");
            }
            words.AddRange(UnderThousand(amount % 1000));
            return words;
        }

        private static IEnumerable<string> UnderThousand(int n)
        {
            var words = new List<string>();
            var rest = n;
            if (rest >= 100)
            {
                words.Add(Ones[rest / 100]);
                words.Add("hundred");
                rest %= 100;
            }
            if (rest >= 20)
            {
                words.Add(Tens[rest / 10]);
                rest %= 10;
                if (rest > 0) words.Add(Ones[rest]);
            }
            else if (rest > 0)
            {
                words.Add(Ones[rest]);
            }
            return words;
        }
    }
}
