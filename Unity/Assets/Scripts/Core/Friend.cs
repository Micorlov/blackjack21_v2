using System;
using System.Collections.Generic;
using System.Linq;

namespace Blackjack.Core
{
    public sealed record Friend(
        string Id,
        string Name,
        int Chips,
        bool Online,
        int DailyScore,
        int HourlyScore,
        string InvitedBy = null,
        string TableKey = null)
    {
        public string FirstName => Name.Split(' ')[0];
        public string Initial => string.IsNullOrEmpty(Name) ? "?" : Name.Substring(0, 1).ToUpperInvariant();
    }

    public static class Roster
    {
        /// <summary>The practice bots that pad the table when a group is small.</summary>
        public static readonly IReadOnlyList<Friend> InitialFriends = new[]
        {
            new Friend("f1", "Maya T.", 2450, true, 320, 45),
            new Friend("f2", "Jordan K.", 1820, true, 210, 80),
            new Friend("f3", "Sam R.", 990, false, -60, 15),
            new Friend("f4", "Priya N.", 3120, false, 540, 0),
        };

        /// <summary>
        /// The 4 opponents seated for the round. Real friends fill seats first (those actually at this
        /// stake before the rest); practice bots pad whatever a small group leaves empty.
        /// </summary>
        public static IReadOnlyList<Friend> TableSeats(IReadOnlyList<Friend> friends, string tableKey)
        {
            var real = tableKey == null
                ? friends.ToList()
                : friends.OrderBy(f => f.TableKey == tableKey ? 0 : 1).ToList(); // stable
            if (real.Count >= TableCatalog.OpponentSeats) return real.Take(TableCatalog.OpponentSeats).ToList();
            var seated = real.Select(f => f.Id).ToHashSet();
            return real.Concat(InitialFriends.Where(f => !seated.Contains(f.Id)))
                .Take(TableCatalog.OpponentSeats).ToList();
        }

        public static IReadOnlyList<Friend> AtTable(IReadOnlyList<Friend> friends, string tableKey) =>
            friends.Where(f => f.TableKey == tableKey).ToList();

        public static string PresenceLabel(IReadOnlyList<Friend> here)
        {
            if (here.Count == 0) return "";
            if (here.Count == 1) return $"{here[0].FirstName} is here";
            if (here.Count == 2) return $"{here[0].FirstName} & {here[1].FirstName} are here";
            return $"{here[0].FirstName}, {here[1].FirstName} +{here.Count - 2} here";
        }

        public static string PresenceCta(IReadOnlyList<Friend> here)
        {
            if (here.Count == 0) return "";
            return here.Count == 1 ? $"Join {here[0].FirstName}" : $"Join {here.Count} friends";
        }
    }

    public static class Referrals
    {
        public const int WelcomeChips = 200;
        public const int JoinChips = 100;

        public static IReadOnlyList<Friend> ReferredBy(IReadOnlyList<Friend> group, string heroUid) =>
            group.Where(f => f.InvitedBy == heroUid).ToList();

        public static int Count(IReadOnlyList<Friend> group, string heroUid) => ReferredBy(group, heroUid).Count;

        public static IReadOnlyList<Friend> Unrewarded(
            IReadOnlyList<Friend> group, string heroUid, IReadOnlyList<string> rewardedIds)
        {
            var rewarded = rewardedIds.ToHashSet();
            return ReferredBy(group, heroUid).Where(f => !rewarded.Contains(f.Id)).ToList();
        }
    }
}
