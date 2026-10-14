using System.Linq;
using System.Text;

namespace Blackjack.Core
{
    public static class TableCatalog
    {
        public const int StartingChips = 1000;
        public const bool DealerHitsSoft17 = false;
        public const int OpponentSeats = 4;

        /// <summary>
        /// How many opponent seats sit to the hero's right and act first. The hero takes the middle chair:
        /// Maya and Jordan (seats 0, 1) play before you, Sam and Priya (seats 2, 3) after you.
        /// </summary>
        public const int SeatsBeforeHero = 2;

        public static readonly int[] ChipDenoms = { 25, 50, 100, 500, 1000 };

        public static readonly TableStake[] Tables =
        {
            new TableStake("bronze", "Bronze Table", 25, 500),
            new TableStake("silver", "Silver Table", 100, 1000),
            new TableStake("vip", "VIP Table", 500, 5000),
        };

        /// <summary>
        /// The chips a table may offer. A chip worth more than the table maximum can never form a legal
        /// bet, so it is not shown; the smallest chip always survives so the tray is never empty.
        /// </summary>
        public static int[] ChipDenomsFor(TableStake stake)
        {
            if (stake == null) return ChipDenoms;
            var allowed = ChipDenoms.Where(d => d <= stake.Max).ToArray();
            return allowed.Length == 0 ? new[] { ChipDenoms[0] } : allowed;
        }

        /// <summary>Thousands-separated integer, equivalent to JS toLocaleString('en-US').</summary>
        public static string FormatChips(long n)
        {
            var digits = System.Math.Abs(n).ToString();
            var sb = new StringBuilder();
            for (var i = 0; i < digits.Length; i++)
            {
                if (i > 0 && (digits.Length - i) % 3 == 0) sb.Append(',');
                sb.Append(digits[i]);
            }
            return (n < 0 ? "-" : "") + sb;
        }
    }
}
