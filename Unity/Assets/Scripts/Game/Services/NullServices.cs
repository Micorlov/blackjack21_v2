using System;
using System.Collections.Generic;
using Blackjack.Core;

namespace Blackjack.Game.Services
{
    public sealed class NullSound : ISoundService
    {
        public readonly List<GameSfx> Tones = new List<GameSfx>();
        public readonly List<GameVoice> Voices = new List<GameVoice>();
        public readonly List<string> Spoken = new List<string>();

        public void Play(GameSfx sfx) => Tones.Add(sfx);
        public double? PlayVoice(GameVoice voice) { Voices.Add(voice); return null; }
        public double? PlayWords(IReadOnlyList<string> words) { Spoken.Add(string.Join(" ", words)); return null; }
        public void SilenceVoice() { }
    }

    public sealed class NullHaptics : IHaptics
    {
        public void Selection() { }
        public void Light() { }
        public void Medium() { }
        public void Heavy() { }
        public void Vibrate() { }
    }

    public sealed class MemorySaveStore : ISaveStore
    {
        public SavedGame Saved;
        public DateTime? LastClaim;
        public int StreakDay;

        public SavedGame Load() => Saved;
        public void Save(SavedGame game) => Saved = game;
        public DateTime? LoadLastClaim() => LastClaim;
        public int LoadStreakDay() => StreakDay;
        public void SaveClaim(DateTime claimedAt, int streakDay) { LastClaim = claimedAt; StreakDay = streakDay; }
    }

    public sealed class NullNotifier : ILocalNotifier
    {
        public readonly List<string> Shown = new List<string>();
        public TimeSpan? DailyAfter;
        public int DailyChips;

        public bool HasPermission => true;
        public void Init() { }
        public void RequestPermission(Action<bool> granted) => granted(true);
        public bool Show(string title, string body) { Shown.Add(title + "|" + body); return true; }
        public void ScheduleDailyBonusReminder(TimeSpan after, int chips) { DailyAfter = after; DailyChips = chips; }
        public void CancelDailyBonusReminder() => DailyAfter = null;
        public void ScheduleStreakReminder(TimeSpan after, int streak) { }
        public void CancelStreakReminder() { }
    }

    public sealed class NullAnalytics : IAnalytics
    {
        public readonly List<string> Events = new List<string>();
        public void SetEnabled(bool enabled) { }
        public void LogEvent(string name, IReadOnlyDictionary<string, object> parameters = null) => Events.Add(name);
        public void LogScreen(string screen) { }
    }

    public sealed class NullReview : IReviewPrompter
    {
        public void Request(Action<bool> completed) => completed(false);
    }

    public sealed class NullPlatform : IPlatform
    {
        public string Clipboard = "";
        public string PlatformName => "test";
        public string CountryCode => "";
        public string AppVersion => "0.0.0";
        public bool Share(string text) => true;
        public bool OpenUrl(string url) => true;
        public string GetClipboard() => Clipboard;
        public void SetClipboard(string text) => Clipboard = text;
    }

    /// <summary>Offline mode: no sign-in, no group. The game plays fine with practice bots.</summary>
    public sealed class NullSocial : ISocialService
    {
        public bool Available => false;
        public string Uid => null;
        public void EnsureSignedIn(Action<bool> done) => done(false);
        public void FetchMyGroupCode(Action<string> done) => done(null);
        public void IsGroupCreator(string code, Action<bool> done) => done(false);
        public void CreateGroup(string displayName, Random rng, Action<string> done) => done(null);
        public void JoinGroup(string code, string displayName, Action<JoinResult> done) => done(JoinResult.Failed);
        public void ReportScore(string code, string name, int chips, int hourly, int daily, string hourKey, string dayKey,
            string tableKey, string appVersion, string platform, string country, int playSeconds) { }
        public void AddPlayTime(int seconds) { }
        public void EnsureCreatedAtStamped() { }
        public IDisposable WatchMembers(string code, Action<IReadOnlyList<Friend>> onUpdate) => new Nop();
        public void SignInWithGoogle(Action<GoogleProfile, string> done) => done(null, "unavailable");
        public void SignOut(Action done) => done();
        public void LoadFeatureFlags(Action<IReadOnlyDictionary<string, bool>> done) => done(new Dictionary<string, bool>());
        public GoogleProfile RestoredProfile() => null;

        private sealed class Nop : IDisposable { public void Dispose() { } }
    }
}
