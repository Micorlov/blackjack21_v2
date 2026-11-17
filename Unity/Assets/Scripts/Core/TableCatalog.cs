using System.Linq;
using System.Text;

namespace Blackjack.Core
{
    public static class TableCatalog
    {
        public const int StartingChips = 1000;
        public const bool DealerHitsSoft17 = false;
        public const int OpponentSeats = 4;

        public static readonly int[] ChipDenoms = { 25, 50, 100, 500, 1000 };

        public static readonly TableStake[] Tables =
        {
            new TableStake("bronze", "Bronze Table", 25, 500),
            new TableStake("silver", "Silver Table", 100, 1000),
            new TableStake("vip", "VIP Table", 500, 5000),
            // Smaller rooms, listed after the classic ladder (which TableRecommendation walks).
            new TableStake("trio", "Trio Table", 50, 1000, Opponents: 2),
            new TableStake("headsup", "Heads-Up", 100, 2000, Opponents: 0, SweepPot: false),
        };

        /// <summary>The rooms that make up the classic 5-seat ladder: the ones the lobby recommends from.</summary>
        public static bool IsClassic(TableStake stake) => stake.Opponents == OpponentSeats;

        public static TableStake ByKey(string key) => Tables.FirstOrDefault(t => t.Key == key);

        /// <summary>Opponent seats at the room with this key; the classic count when there is no room (or an unknown key).</summary>
        public static int OpponentsFor(string key) => ByKey(key)?.Opponents ?? OpponentSeats;

        /// <summary>Whether the room pools a sweep pot. No stake (tests, tutorial) behaves as a classic room.</summary>
        public static bool HasSweepPot(TableStake stake) => stake?.SweepPot ?? true;

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
