using System.Collections.Generic;
using System.Linq;

namespace Blackjack.Core
{
    /// <summary>
    /// Everything that survives a relaunch. Mirrors the Flutter <c>SavedGame</c> field for field so the
    /// two apps could share a blob; the screen, the live round and the social state are never saved.
    /// </summary>
    public sealed record SavedGame
    {
        public const int SchemaVersion = 1;
        public const int HistoryLimit = 50;

        public int Chips { get; init; } = TableCatalog.StartingChips;
        public StatsSummary Stats { get; init; } = new StatsSummary();
        public IReadOnlyList<RoundResult> History { get; init; } = new RoundResult[0];
        public int HourlyPoints { get; init; }
        public int DailyPoints { get; init; }
        public string HourKey { get; init; } = "";
        public string DayKey { get; init; } = "";
        public bool SoundOn { get; init; } = true;
        public bool VoiceOn { get; init; } = true;
        public string LanguageOverride { get; init; }
        public bool HapticsOn { get; init; } = true;

        /// <summary>The 20-second auto-stand on the hero's turn. Older saves lack the key and get it on.</summary>
        public bool TurnTimerOn { get; init; } = true;
        public bool NotifSocial { get; init; } = true;
        public bool NotifLeaderboard { get; init; } = true;
        public bool NotifDaily { get; init; } = true;
        public int TutorialRoundsSeen { get; init; }
        public bool TutorialDismissed { get; init; }
        public bool OnboardingDone { get; init; }
        public int AvatarColor { get; init; }
        public IReadOnlyList<string> RewardedReferralIds { get; init; } = new string[0];
        public int PlayDayStreak { get; init; }
        public string LastPlayDayKey { get; init; } = "";
        public long LastRebuyAtMs { get; init; }
        public long LastAdRewardAtMs { get; init; }
        public int AdRewardsToday { get; init; }
        public string AdRewardsDayKey { get; init; } = "";
        /// <summary>Comeback Boost (a stronger opening hand when short-stacked or on a losing streak). On unless the player turned it off.</summary>
        public bool ComebackOn { get; init; } = true;
        public bool AnalyticsOn { get; init; } = true;
        /// <summary>True once the player has used the switch; until then <see cref="AnalyticsOn"/> is just the default (on).</summary>
        public bool AnalyticsChoiceMade { get; init; }
        public bool ReviewPromptShown { get; init; }
        public long ReviewLastAttemptAtMs { get; init; }
        public int ReviewRequestCount { get; init; }
        public bool ReviewLastRequestSucceeded { get; init; }
        public bool TutorialCompletionLogged { get; init; }
        /// <summary>When this install first opened; 0 in saves from before it was tracked (those players count as long-standing).</summary>
        public long FirstSeenAtMs { get; init; }
        /// <summary>Local date key of the last evening gift taken.</summary>
        public string EveningGiftKey { get; init; } = "";
        /// <summary>The notification-permission dialog is only ever offered once.</summary>
        public bool NotifPermissionAsked { get; init; }

        /// <summary>The newest <see cref="HistoryLimit"/> results; older ones are dropped on save.</summary>
        public IReadOnlyList<RoundResult> TrimmedHistory =>
            History.Count > HistoryLimit ? History.Skip(History.Count - HistoryLimit).ToList() : History;
    }
}
