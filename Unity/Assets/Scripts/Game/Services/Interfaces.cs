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

        /// <summary>Schedules the daily 8 PM evening-gift notification (replacing the pending one) first firing at <paramref name="firstAt"/>.</summary>
        void ScheduleEveningGift(DateTime firstAt);
        void CancelEveningGift();

        /// <summary>True once if the app was opened by tapping the evening-gift notification; the tap is consumed so it cannot count twice.</summary>
        bool ConsumeEveningGiftTap();
    }

    public interface IAnalytics
    {
        void SetEnabled(bool enabled);
        /// <summary>Passes the player's consent answer on as Google consent mode (analytics_storage, ad_storage, ad_user_data, ad_personalization).</summary>
        void SetConsent(ConsentSignals consent);
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
        public const string EveningGiftClaimed = "evening_gift_claimed";
        public const string NotifPermissionAsked = "notif_permission_asked";
        public const string TableEntered = "table_entered";
        public const string Rebuy = "rebuy";
        public const string InviteShared = "invite_shared";
        public const string OutOfChips = "out_of_chips";
        public const string ReviewPrompted = "review_prompted";
        public const string AdRewardEarned = "ad_reward_earned";
        public const string BreakAdShown = "break_ad_shown";
        /// <summary>GA4's recommended name for a completed sign-in.</summary>
        public const string Login = "login";
        public const string SignInFailed = "sign_in_failed";
    }

    public interface IReviewPrompter
    {
        /// <summary>Asks the store for its review sheet; reports whether the request was actually made.</summary>
        void Request(Action<bool> completed);
    }

    /// <summary>Full-screen ads. Nothing here may hold the game up: no SDK, no consent or no fill just means no ad.</summary>
    public interface IAds
    {
        /// <summary>Asks for consent where the law requires it, then starts the ad SDK. Call once at launch.</summary>
        void Init();

        bool RewardedReady { get; }

        /// <summary>Plays a rewarded video; reports, once it closes, whether it was watched through.</summary>
        void ShowRewarded(Action<bool> done);

        /// <summary>Shows a loaded interstitial; returns false, showing nothing, when there is none. <paramref name="closed"/> runs once it is dismissed or fails.</summary>
        bool ShowInterstitial(Action closed = null);

        /// <summary>True while an interstitial is loaded and can be shown.</summary>
        bool InterstitialReady { get; }

        /// <summary>The player's answer to Google's consent platform; null until it has answered (or where the SDK is absent).</summary>
        ConsentSignals? Consent { get; }

        /// <summary>Raised when <see cref="Consent"/> may have changed: after the launch check and after the privacy options form.</summary>
        event Action ConsentChanged;

        /// <summary>Height in screen pixels of the banner docked at the bottom of the screen; 0 while none is showing.</summary>
        float BannerHeightPixels { get; }

        /// <summary>True where the player must be able to change their consent, which Settings then offers.</summary>
        bool PrivacyOptionsRequired { get; }

        void ShowPrivacyOptions();
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

    /// <summary>How "Delete account and data" ended.</summary>
    public enum DeleteOutcome
    {
        Deleted, Unavailable, SignInFailed,
        /// <summary>Nothing of the player's own was deleted; it is safe to try again.</summary>
        CloudFailed,
        /// <summary>The cloud records are gone but the sign-in record is still there.</summary>
        RecordsDeletedAccountKept,
        /// <summary>The deletion did not report back in time, so it may or may not have happened. Trying again is safe.</summary>
        Unknown,
    }

    /// <summary>How removing the player's online records ended.</summary>
    public enum CloudDeleteResult
    {
        Done,
        /// <summary>It stopped before the player's own records were touched (offline, refused, or a failed transaction, which writes nothing).</summary>
        NothingDeleted,
        /// <summary>The player's own records may already be gone: the outcome could not be confirmed.</summary>
        MaybeDeleted,
    }

    public sealed record GoogleProfile(string DisplayName, string PhotoUrl);

    /// <summary>How the last step of deleting the sign-in record ended.</summary>
    public enum DeleteStep { Done, RecentLoginNeeded, Failed }

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

        // ---- account and data deletion ------------------------------------------------------------

        /// <summary>True when the current account is signed in with Google (not the anonymous guest account).</summary>
        bool IsGoogleLinked { get; }

        /// <summary>Asks the Google user to sign in again, which Firebase requires shortly before an account is deleted.</summary>
        void Reauthenticate(Action<bool> done);

        /// <summary>
        /// Removes the signed-in user's own online records and every reference to their uid, using only writes the security rules
        /// allow a user on their own data: clears their uid from other members' invitedBy (set to "deleted"), then in one atomic
        /// transaction replaces createdBy of groups they created with "deleted" and deletes their member rows, players/{uid} and
        /// leaderboard/{uid}. It first waits for queued writes so none can land afterwards. Idempotent, so a retry is always safe.
        /// <paramref name="commitStarted"/> fires just before the first change; until then nothing has been touched.
        /// </summary>
        void DeleteCloudRecords(string groupCode, Action commitStarted, Action<CloudDeleteResult> done);

        /// <summary>Deletes the Firebase Authentication user itself. Run after <see cref="DeleteCloudRecords"/>.</summary>
        void DeleteAuthUser(Action<DeleteStep> done);
    }

    public static class FeatureFlag
    {
        public const string ReviewPrompt = "reviewPromptEnabled";
        public const string ReferralRewards = "referralRewardsEnabled";
    }
}
