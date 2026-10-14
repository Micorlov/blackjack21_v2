using System;
using System.Collections.Generic;
using Blackjack.Core;

namespace Blackjack.Game
{
    public enum LeaderboardPeriod { Hourly, Daily, AllTime }

    public enum StatsTab { Recent, AllTime }

    public sealed record ChatMessage(string Name, string Text, long Id);

    /// <summary>
    /// Everything the screens draw. The bankroll, stats and history live inside <see cref="Round"/>
    /// (they are part of the engine's state); the rest is app-level. Immutable — the controller
    /// replaces it wholesale.
    /// </summary>
    public sealed record AppState
    {
        public AppScreen Screen { get; init; } = AppScreen.Onboarding;
        public bool SignedIn { get; init; }
        public string DisplayName { get; init; } = "Guest";
        public string PhotoUrl { get; init; }

        public RoundState Round { get; init; } = new RoundState();

        public DateTime? LastDailyBonusClaimAt { get; init; }
        public int DailyBonusStreakDay { get; init; }

        public string Toast { get; init; } = "";
        public string ReactionFloat { get; init; } = "";
        public int ReactionId { get; init; }

        public IReadOnlyList<Friend> Friends { get; init; } = Roster.InitialFriends;
        public LeaderboardPeriod LeaderboardPeriod { get; init; } = LeaderboardPeriod.AllTime;
        public string FriendCodeInput { get; init; } = "";
        public StatsTab StatsTab { get; init; } = StatsTab.Recent;

        public bool HapticsOn { get; init; } = true;

        /// <summary>Your turn stands automatically after <see cref="GameController.TurnSeconds"/>, as at a casino table.</summary>
        public bool TurnTimerOn { get; init; } = true;
        public bool SoundOn { get; init; } = true;

        /// <summary>Spoken call-outs, nested under <see cref="SoundOn"/>: muting sound silences the voice too.</summary>
        public bool VoiceOn { get; init; } = true;

        /// <summary>ISO 639-1 code picked in Settings; null follows the device language.</summary>
        public string LanguageOverride { get; init; }

        public bool NotifSocial { get; init; } = true;
        public bool NotifLeaderboard { get; init; } = true;
        public bool NotifDaily { get; init; } = true;

        /// <summary>Avatar colour as 0xAARRGGBB; 0 means "never chose", which the UI renders as the first swatch.</summary>
        public int AvatarColor { get; init; }

        public int ReferralsCount { get; init; }
        public IReadOnlyList<ChatMessage> ChatMessages { get; init; } = Array.Empty<ChatMessage>();
        public bool TableMenuOpen { get; init; }
        public bool TableChatOpen { get; init; }

        public bool SocialReady { get; init; }
        public string GroupCode { get; init; }
        public int HeroHourlyPoints { get; init; }
        public int HeroDailyPoints { get; init; }
        public string HeroHourKey { get; init; } = "";
        public string HeroDayKey { get; init; } = "";
        public string HeroUid { get; init; }

        /// <summary>True once real friends have joined; with practice bots at the seats there is nothing to rank.</summary>
        public bool FriendsAreLive { get; init; }

        public int TutorialRoundsSeen { get; init; }
        public bool TutorialDismissed { get; init; }

        /// <summary>A join code parsed from a link before the social layer was ready. In-memory only.</summary>
        public string PendingJoinCode { get; init; }

        public bool JoinedViaLink { get; init; }
        public IReadOnlyList<string> RewardedReferralIds { get; init; } = Array.Empty<string>();
        public int PlayDayStreak { get; init; }
        public string LastPlayDayKey { get; init; } = "";
        public DateTime? LastRebuyAt { get; init; }
        public bool AnalyticsOn { get; init; } = true;
        public bool ReviewPromptShown { get; init; }
        public long ReviewLastAttemptAtMs { get; init; }
        public int ReviewRequestCount { get; init; }
        public bool ReviewLastRequestSucceeded { get; init; }
        public bool TutorialCompletionLogged { get; init; }

        public int Chips => Round.Chips;
    }
}
