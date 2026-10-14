using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace Blackjack.Core
{
    /// <summary>Hour/day bucket keys and the points that roll over with them.</summary>
    public static class Points
    {
        public static string DayKeyOf(DateTime t) =>
            t.Year.ToString("0000", CultureInfo.InvariantCulture) + "-"
            + t.Month.ToString("00", CultureInfo.InvariantCulture) + "-"
            + t.Day.ToString("00", CultureInfo.InvariantCulture);

        public static string HourKeyOf(DateTime t) =>
            DayKeyOf(t) + "T" + t.Hour.ToString("00", CultureInfo.InvariantCulture);

        /// <summary>A bucket's points count only while its key is the current one; otherwise they reset.</summary>
        public static int Rolled(int points, string bucketKey, string currentKey) =>
            bucketKey == currentKey ? points : 0;
    }

    public sealed record RankedPlayer(string Id, string Name, int Points);

    public static class Ranking
    {
        public static int RankOf(string heroId, IReadOnlyList<RankedPlayer> players)
        {
            var hero = players.FirstOrDefault(p => p.Id == heroId);
            if (hero == null) return players.Count + 1;
            return players.Count(p => p.Id != heroId && p.Points > hero.Points) + 1;
        }

        /// <summary>Players who were not ahead of the hero before and now are.</summary>
        public static IReadOnlyList<RankedPlayer> Overtakers(
            IReadOnlyList<RankedPlayer> before, IReadOnlyList<RankedPlayer> after, string heroId)
        {
            int PointsOf(string id, IReadOnlyList<RankedPlayer> list, int orElse) =>
                list.FirstOrDefault(p => p.Id == id)?.Points ?? orElse;

            var heroBefore = PointsOf(heroId, before, 0);
            var heroAfter = PointsOf(heroId, after, heroBefore);
            // Absent from "before" (just joined) counts as previously not ahead.
            return after.Where(p => p.Id != heroId && p.Points > heroAfter
                                    && PointsOf(p.Id, before, heroBefore) <= heroBefore).ToList();
        }
    }

    public static class DailyBonus
    {
        public const int Chips = 250;
        public const int Day7Chips = 1000;
        public const int StreakDays = 7;
        public static readonly TimeSpan Cooldown = TimeSpan.FromHours(24);
        public static readonly TimeSpan StreakWindow = TimeSpan.FromHours(48);

        /// <summary>The streak day a claim made at <paramref name="now"/> lands on (1..7).</summary>
        public static int NextStreakDay(int lastStreakDay, DateTime? lastClaimAt, DateTime now)
        {
            if (lastClaimAt == null || lastStreakDay <= 0) return 1;
            if (now - lastClaimAt.Value > StreakWindow) return 1;
            return lastStreakDay >= StreakDays ? 1 : lastStreakDay + 1;
        }

        public static int RewardForDay(int day) => day >= StreakDays ? Day7Chips : Chips;

        public static bool IsReady(DateTime? lastClaimAt, DateTime now) =>
            lastClaimAt == null || now - lastClaimAt.Value >= Cooldown;

        public static DateTime? NextAt(DateTime? lastClaimAt) => lastClaimAt?.Add(Cooldown);

        public static string CountdownLabel(DateTime lastClaimAt, DateTime now) =>
            Countdown.Label(lastClaimAt.Add(Cooldown) - now);
    }

    public static class Rebuy
    {
        public static readonly TimeSpan Cooldown = TimeSpan.FromHours(4);
        public const int Chips = 1000;

        public static bool IsReady(DateTime? lastRebuyAt, DateTime now) =>
            lastRebuyAt == null || now - lastRebuyAt.Value >= Cooldown;

        public static string CountdownLabel(DateTime lastRebuyAt, DateTime now) =>
            Countdown.Label(lastRebuyAt.Add(Cooldown) - now);
    }

    public static class Countdown
    {
        /// <summary>"3h 12m" / "45m", rounded up to the minute; empty once the time has passed.</summary>
        public static string Label(TimeSpan left)
        {
            if (left <= TimeSpan.Zero) return "";
            var minutes = (int)Math.Ceiling(left.TotalSeconds / 60);
            var h = minutes / 60;
            var m = minutes % 60;
            return h > 0 ? $"{h}h {m}m" : $"{m}m";
        }
    }

    public static class PlayStreak
    {
        public const int BonusStep = 50;
        public const int BonusCapDays = 5;
        public const int ReminderHour = 20;

        public static string PreviousDayKey(DateTime now) => Points.DayKeyOf(now.Date.AddDays(-1));

        public static bool PlayedToday(string lastDayKey, DateTime now) => lastDayKey == Points.DayKeyOf(now);

        /// <summary>The streak after a hand is settled at <paramref name="now"/>.</summary>
        public static (int Streak, string DayKey) Advance(int streak, string lastDayKey, DateTime now)
        {
            var today = Points.DayKeyOf(now);
            if (lastDayKey == today) return (streak, today);
            if (lastDayKey == PreviousDayKey(now)) return (streak + 1, today);
            return (1, today);
        }

        /// <summary>The streak as it stands now — it lapses if neither today nor yesterday was played.</summary>
        public static int Live(int streak, string lastDayKey, DateTime now)
        {
            var today = Points.DayKeyOf(now);
            return lastDayKey == today || lastDayKey == PreviousDayKey(now) ? streak : 0;
        }

        public static int BonusChips(int liveStreak) => Math.Min(liveStreak, BonusCapDays) * BonusStep;

        /// <summary>When to nag about a streak ending, or null when there is nothing to remind about.</summary>
        public static DateTime? ReminderAt(int liveStreak, bool playedToday, DateTime now)
        {
            if (liveStreak == 0) return null;
            var todayAt = now.Date.AddHours(ReminderHour);
            if (playedToday) return todayAt.AddDays(1);
            return now < todayAt ? todayAt : (DateTime?)null;
        }
    }

    public static class ReviewPrompt
    {
        public const int MinHands = 10;
        public const int MaxRequests = 3;
        public static readonly TimeSpan FailureCooldown = TimeSpan.FromDays(7);
        public static readonly TimeSpan SuccessCooldown = TimeSpan.FromDays(90);

        public static bool ShouldPrompt(
            int handsPlayed, DateTime now, long lastAttemptAtMs, int completedRequests, bool lastRequestSucceeded)
        {
            if (handsPlayed < MinHands || completedRequests >= MaxRequests) return false;
            if (lastAttemptAtMs <= 0) return true;
            var last = DateTimeOffset.FromUnixTimeMilliseconds(lastAttemptAtMs).LocalDateTime;
            return now - last >= (lastRequestSucceeded ? SuccessCooldown : FailureCooldown);
        }
    }

    public static class TableRecommendation
    {
        public const int HandsOfHeadroom = 4;

        /// <summary>The highest table whose minimum the stack covers at least four times over.</summary>
        public static TableStake For(int chips)
        {
            var best = TableCatalog.Tables[0];
            foreach (var t in TableCatalog.Tables)
                if (chips >= t.Min * HandsOfHeadroom) best = t;
            return best;
        }
    }

    public static class Flags
    {
        private static readonly string[] Pool =
        {
            "🇺🇸", "🇬🇧", "🇨🇦", "🇦🇺", "🇩🇪", "🇫🇷", "🇮🇹", "🇪🇸", "🇧🇷", "🇯🇵",
            "🇰🇷", "🇮🇳", "🇲🇽", "🇳🇱", "🇸🇪", "🇮🇱", "🇿🇦", "🇦🇷", "🇹🇷", "🇵🇱",
        };

        /// <summary>A stable flag for an id — the same hash the Flutter app uses.</summary>
        public static string ForId(string id)
        {
            if (string.IsNullOrEmpty(id)) return Pool[0];
            var hash = 0;
            foreach (var unit in id) hash = (hash * 31 + unit) & 0x7fffffff;
            return Pool[hash % Pool.Length];
        }
    }

    /// <summary>Counts whole seconds of foreground play, pausing when the app is backgrounded.</summary>
    public sealed class PlayTimeTracker
    {
        private readonly Func<TimeSpan> _clock;
        private TimeSpan? _since;
        private TimeSpan _banked = TimeSpan.Zero;

        public PlayTimeTracker(Func<TimeSpan> clock = null)
        {
            if (clock == null)
            {
                var watch = System.Diagnostics.Stopwatch.StartNew();
                clock = () => watch.Elapsed;
            }
            _clock = clock;
            _since = _clock();
        }

        public void Resume() => _since ??= _clock();

        public void Pause()
        {
            if (_since == null) return;
            _banked += _clock() - _since.Value;
            _since = null;
        }

        /// <summary>Whole seconds accumulated since the last call; the fraction carries over.</summary>
        public int TakeSeconds()
        {
            var now = _clock();
            var total = _banked + (_since == null ? TimeSpan.Zero : now - _since.Value);
            var whole = (int)total.TotalSeconds;
            _banked = total - TimeSpan.FromSeconds(whole);
            if (_since != null) _since = now;
            return whole;
        }
    }
}
