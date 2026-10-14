using System;
using System.Collections.Generic;
using Blackjack.Core;

namespace Blackjack.Game.Services
{
    public enum GameSfx { Chip, Deal, Win, Lose, Push, Blackjack, Turn, PotCelebration }

    public enum GameVoice
    {
        PlayerWin, PlayerLose, Push, PlayerBlackjack, PlayerBlackjackPot, PlayerPot, NpcStand, NpcBust,
    }

    /// <summary>Tone effects and queued spoken lines. Times are <c>Time.realtimeSinceStartupAsDouble</c> seconds.</summary>
    public interface ISoundService
    {
        void Play(GameSfx sfx);

        /// <summary>Queues a line behind whatever is speaking; returns when it will finish, or null if dropped.</summary>
        double? PlayVoice(GameVoice voice);

        /// <summary>Queues a spoken number/phrase built from word clips; returns when it will finish, or null.</summary>
        double? PlayWords(IReadOnlyList<string> words);

        void SilenceVoice();
    }

    public interface IHaptics
    {
        void Selection();
        void Light();
        void Medium();
        void Heavy();
        void Vibrate();
    }

    /// <summary>Local persistence: the save blob plus the daily-bonus keys, which live outside it.</summary>
    public interface ISaveStore
    {
        SavedGame Load();
        void Save(SavedGame game);
        DateTime? LoadLastClaim();
        int LoadStreakDay();
        void SaveClaim(DateTime claimedAt, int streakDay);
    }

    public interface ILocalNotifier
    {
        void Init();
        bool HasPermission { get; }

        /// <summary>Asks the OS for notification permission; reports whether the player can now be notified.</summary>
        void RequestPermission(Action<bool> granted);

        bool Show(string title, string body);
        void ScheduleDailyBonusReminder(TimeSpan after, int chips);
        void CancelDailyBonusReminder();
        void ScheduleStreakReminder(TimeSpan after, int streak);
        void CancelStreakReminder();
    }

    public interface IAnalytics
    {
        void SetEnabled(bool enabled);
        void LogEvent(string name, IReadOnlyDictionary<string, object> parameters = null);
        void LogScreen(string screen);
    }

    public static class AnalyticsEvent
    {
        public const string EntrySelected = "onboarding_entry_selected";
        public const string OnboardingComplete = "onboarding_complete";
        public const string FirstHand = "first_hand_completed";
        public const string TenHands = "ten_hands_completed";
        public const string TutorialComplete = "tutorial_completed";
        public const string TutorialSkipped = "tutorial_skipped";
        public const string ReviewRequestResult = "review_request_result";
        public const string HandPlayed = "hand_played";
        public const string DailyBonusClaimed = "daily_bonus_claimed";
        public const string TableEntered = "table_entered";
        public const string Rebuy = "rebuy";
        public const string InviteShared = "invite_shared";
        public const string OutOfChips = "out_of_chips";
        public const string ReviewPrompted = "review_prompted";
    }

    public interface IReviewPrompter
    {
        /// <summary>Asks the store for its review sheet; reports whether the request was actually made.</summary>
        void Request(Action<bool> completed);
    }

    /// <summary>OS integrations the game reaches for: sharing, links, clipboard, app version.</summary>
    public interface IPlatform
    {
        string PlatformName { get; }
        string CountryCode { get; }
        string AppVersion { get; }
        bool Share(string text);
        bool OpenUrl(string url);
        string GetClipboard();
        void SetClipboard(string text);
    }

    public enum JoinResult { NotFound, Joined, AlreadyMember, Failed }

    public sealed record GoogleProfile(string DisplayName, string PhotoUrl);

    /// <summary>The live friends group and leaderboard. All members of the group, never the hero.</summary>
    public interface ISocialService
    {
        bool Available { get; }
        string Uid { get; }

        void EnsureSignedIn(Action<bool> done);
        void FetchMyGroupCode(Action<string> done);
        void IsGroupCreator(string code, Action<bool> done);
        void CreateGroup(string displayName, Random rng, Action<string> done);
        void JoinGroup(string code, string displayName, Action<JoinResult> done);

        void ReportScore(string code, string name, int chips, int hourly, int daily, string hourKey, string dayKey,
            string tableKey, string appVersion, string platform, string country, int playSeconds);

        void AddPlayTime(int seconds);
        void EnsureCreatedAtStamped();

        /// <summary>Starts watching a group; the callback fires with every member except the hero. Returns a handle to stop.</summary>
        IDisposable WatchMembers(string code, Action<IReadOnlyList<Friend>> onUpdate);

        /// <summary>Interactive Google sign-in; links onto the anonymous user when there is one.</summary>
        void SignInWithGoogle(Action<GoogleProfile, string> done);

        void SignOut(Action done);
        void LoadFeatureFlags(Action<IReadOnlyDictionary<string, bool>> done);
        GoogleProfile RestoredProfile();
    }

    public static class FeatureFlag
    {
        public const string ReviewPrompt = "reviewPromptEnabled";
        public const string ReferralRewards = "referralRewardsEnabled";
    }
}
