using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Newtonsoft.Json.Linq;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// The save blob as JSON, with the same keys as the Flutter app's <c>gameStateV1</c>. Reading is tolerant:
    /// a missing or wrongly-typed field falls back to its default rather than discarding the save.
    /// </summary>
    public static class SavedGameJson
    {
        public static string ToJson(SavedGame g)
        {
            var o = new JObject
            {
                ["v"] = SavedGame.SchemaVersion,
                ["chips"] = g.Chips,
                ["stats"] = new JObject
                {
                    ["handsPlayed"] = g.Stats.HandsPlayed,
                    ["wins"] = g.Stats.Wins,
                    ["losses"] = g.Stats.Losses,
                    ["pushes"] = g.Stats.Pushes,
                    ["blackjacks"] = g.Stats.Blackjacks,
                    ["currentStreak"] = g.Stats.CurrentStreak,
                    ["bestStreak"] = g.Stats.BestStreak,
                },
                ["history"] = new JArray(g.TrimmedHistory.Select(r => (object)r.ToString().ToLowerInvariant())),
                ["hourlyPoints"] = g.HourlyPoints,
                ["dailyPoints"] = g.DailyPoints,
                ["hourKey"] = g.HourKey,
                ["dayKey"] = g.DayKey,
                ["soundOn"] = g.SoundOn,
                ["voiceOn"] = g.VoiceOn,
                ["languageOverride"] = g.LanguageOverride,
                ["hapticsOn"] = g.HapticsOn,
                ["turnTimerOn"] = g.TurnTimerOn,
                ["notifSocial"] = g.NotifSocial,
                ["notifLeaderboard"] = g.NotifLeaderboard,
                ["notifDaily"] = g.NotifDaily,
                ["tutorialRoundsSeen"] = g.TutorialRoundsSeen,
                ["tutorialDismissed"] = g.TutorialDismissed,
                ["onboardingDone"] = g.OnboardingDone,
                ["avatarColor"] = g.AvatarColor,
                ["rewardedReferralIds"] = new JArray(g.RewardedReferralIds.Cast<object>()),
                ["playDayStreak"] = g.PlayDayStreak,
                ["lastPlayDayKey"] = g.LastPlayDayKey,
                ["lastRebuyAtMs"] = g.LastRebuyAtMs,
                ["analyticsOn"] = g.AnalyticsOn,
                ["reviewPromptShown"] = g.ReviewPromptShown,
                ["reviewLastAttemptAtMs"] = g.ReviewLastAttemptAtMs,
                ["reviewRequestCount"] = g.ReviewRequestCount,
                ["reviewLastRequestSucceeded"] = g.ReviewLastRequestSucceeded,
                ["tutorialCompletionLogged"] = g.TutorialCompletionLogged,
            };
            return o.ToString(Newtonsoft.Json.Formatting.None);
        }

        /// <summary>Null when the blob is unreadable or from another schema version.</summary>
        public static SavedGame FromJson(string json)
        {
            JObject o;
            try { o = JObject.Parse(json); }
            catch (Exception) { return null; }
            if (Int(o["v"], -1) != SavedGame.SchemaVersion) return null;

            var stats = o["stats"] as JObject ?? new JObject();
            var handsPlayed = Int(stats["handsPlayed"], 0);
            var defaults = new SavedGame();
            // A blob written before the tutorial existed has no progress to restore; hands played stands in for lessons seen.
            var tutorialSeen = Int(o["tutorialRoundsSeen"], Math.Min(handsPlayed, Tutorial.Rounds));

            return new SavedGame
            {
                Chips = Int(o["chips"], defaults.Chips),
                Stats = new StatsSummary(
                    handsPlayed, Int(stats["wins"], 0), Int(stats["losses"], 0), Int(stats["pushes"], 0),
                    Int(stats["blackjacks"], 0), Int(stats["currentStreak"], 0), Int(stats["bestStreak"], 0)),
                History = History(o["history"]),
                HourlyPoints = Int(o["hourlyPoints"], 0),
                DailyPoints = Int(o["dailyPoints"], 0),
                HourKey = Str(o["hourKey"], ""),
                DayKey = Str(o["dayKey"], ""),
                SoundOn = Bool(o["soundOn"], defaults.SoundOn),
                VoiceOn = Bool(o["voiceOn"], defaults.VoiceOn),
                LanguageOverride = o["languageOverride"]?.Type == JTokenType.String ? (string)o["languageOverride"] : null,
                HapticsOn = Bool(o["hapticsOn"], defaults.HapticsOn),
                TurnTimerOn = Bool(o["turnTimerOn"], defaults.TurnTimerOn),
                NotifSocial = Bool(o["notifSocial"], defaults.NotifSocial),
                NotifLeaderboard = Bool(o["notifLeaderboard"], defaults.NotifLeaderboard),
                NotifDaily = Bool(o["notifDaily"], defaults.NotifDaily),
                TutorialRoundsSeen = tutorialSeen,
                TutorialDismissed = Bool(o["tutorialDismissed"], false),
                // A blob from before this key existed belongs to someone who already got past the gate.
                OnboardingDone = Bool(o["onboardingDone"], true),
                AvatarColor = Int(o["avatarColor"], 0),
                RewardedReferralIds = Strings(o["rewardedReferralIds"]),
                PlayDayStreak = Int(o["playDayStreak"], 0),
                LastPlayDayKey = Str(o["lastPlayDayKey"], ""),
                LastRebuyAtMs = Long(o["lastRebuyAtMs"], 0),
                AnalyticsOn = Bool(o["analyticsOn"], true),
                ReviewPromptShown = Bool(o["reviewPromptShown"], false),
                ReviewLastAttemptAtMs = Long(o["reviewLastAttemptAtMs"], 0),
                ReviewRequestCount = Int(o["reviewRequestCount"], 0),
                ReviewLastRequestSucceeded = Bool(o["reviewLastRequestSucceeded"], false),
                TutorialCompletionLogged = Bool(o["tutorialCompletionLogged"], tutorialSeen >= Tutorial.Rounds),
            };
        }

        private static int Int(JToken t, int fallback) =>
            t != null && (t.Type == JTokenType.Integer) ? (int)(long)t : fallback;

        private static long Long(JToken t, long fallback) =>
            t != null && t.Type == JTokenType.Integer ? (long)t : fallback;

        private static bool Bool(JToken t, bool fallback) =>
            t != null && t.Type == JTokenType.Boolean ? (bool)t : fallback;

        private static string Str(JToken t, string fallback) =>
            t != null && t.Type == JTokenType.String ? (string)t : fallback;

        private static IReadOnlyList<string> Strings(JToken t) =>
            t is JArray a ? a.Where(e => e.Type == JTokenType.String).Select(e => (string)e).ToList() : new List<string>();

        private static IReadOnlyList<RoundResult> History(JToken t)
        {
            if (!(t is JArray a)) return new List<RoundResult>();
            var list = new List<RoundResult>();
            foreach (var e in a)
            {
                if (e.Type != JTokenType.String) continue;
                switch ((string)e)
                {
                    case "win": list.Add(RoundResult.Win); break;
                    case "loss": list.Add(RoundResult.Loss); break;
                    case "push": list.Add(RoundResult.Push); break;
                }
            }
            return list;
        }
    }
}
