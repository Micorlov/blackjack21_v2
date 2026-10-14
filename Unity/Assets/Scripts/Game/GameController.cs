using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game.Services;
using UnityEngine;

namespace Blackjack.Game
{
    /// <summary>A cancellable one-shot timer driven by <see cref="GameController"/> (Dart's <c>Timer</c>).</summary>
    public sealed class TimerHandle
    {
        internal double At;
        internal Action Fire;
        public bool Cancelled { get; private set; }
        public bool Fired { get; internal set; }
        public bool Active => !Cancelled && !Fired;
        public void Cancel() => Cancelled = true;
    }

    /// <summary>The bundle of platform services the controller talks to; tests and the editor use the null versions.</summary>
    public sealed class GameServices
    {
        public ISoundService Sound = new NullSound();
        public IHaptics Haptics = new NullHaptics();
        public ISaveStore Store = new MemorySaveStore();
        public ILocalNotifier Notifier = new NullNotifier();
        public IAnalytics Analytics = new NullAnalytics();
        public IReviewPrompter Review = new NullReview();
        public IPlatform Platform = new NullPlatform();
        public ISocialService Social = new NullSocial();
    }

    /// <summary>
    /// The game's brain — the Unity counterpart of the Flutter <c>GameNotifier</c>. Owns the immutable
    /// <see cref="AppState"/>, runs the round with paced timers on top of <see cref="RoundEngine"/>, and
    /// speaks to the platform through <see cref="GameServices"/>. Split across partial files by concern.
    /// </summary>
    public sealed partial class GameController : MonoBehaviour
    {
        private const float SaveDebounce = 0.6f;
        private const float ToastSeconds = 2.2f;
        private const float ReactionSeconds = 1.6f;
        private const int ChatLogLimit = 30;

        private GameServices _svc = new GameServices();
        private System.Random _rng = new System.Random();
        private Shoe _shoe;
        private Func<DateTime> _now = () => DateTime.Now;
        private readonly List<TimerHandle> _timers = new List<TimerHandle>();
        private PlayTimeTracker _playTime = new PlayTimeTracker();

        public AppState State { get; private set; } = new AppState();

        /// <summary>Raised after every state change, on the main thread.</summary>
        public event Action<AppState> Changed;

        public RoundState Round => State.Round;

        /// <summary>Set by the UI: closes the topmost dialog/sheet and returns true, or returns false when none is open.</summary>
        public Func<bool> OverlayBack;

        public GameServices Services => _svc;

        /// <summary>Wires services and starts loading the saved game. Call once, right after creating the controller.</summary>
        public void Init(GameServices services, Func<DateTime> now = null, System.Random rng = null, bool boot = true)
        {
            _svc = services ?? _svc;
            _now = now ?? _now;
            _rng = rng ?? _rng;
            _shoe = new Shoe(_rng);
            if (boot) Boot();
        }

        /// <summary>Replaces the shoe (tests stack it to force a specific deal).</summary>
        public void UseShoe(Shoe shoe) => _shoe = shoe;

        // ---- state plumbing -----------------------------------------------------------------------

        public void Set(Func<AppState, AppState> change)
        {
            State = change(State);
            Changed?.Invoke(State);
        }

        private void SetRound(Func<RoundState, RoundState> change) =>
            Set(s => s with { Round = change(s.Round) });

        /// <summary>For tests and the screenshot harness: replaces the whole state without side effects.</summary>
        public void Force(AppState state)
        {
            State = state;
            Changed?.Invoke(State);
        }

        // ---- timers ---------------------------------------------------------------------------------

        public TimerHandle After(double seconds, Action fire)
        {
            var handle = new TimerHandle { At = Clock() + seconds, Fire = fire };
            _timers.Add(handle);
            return handle;
        }

        private static void Cancel(ref TimerHandle handle)
        {
            handle?.Cancel();
            handle = null;
        }

        /// <summary>Seconds on the timer clock; real time in the game, a fake in tests.</summary>
        private Func<double> _clock = () => Time.realtimeSinceStartupAsDouble;

        private double Clock() => _clock();

        /// <summary>Replaces the timer clock (tests advance it by hand and call <see cref="Tick"/>).</summary>
        public void UseClock(Func<double> clock) => _clock = clock;

        private void Update() => Tick();

        /// <summary>Fires every timer that is due. Called each frame; tests call it after moving their clock.</summary>
        public void Tick()
        {
            if (_timers.Count == 0) return;
            var now = Clock();
            List<TimerHandle> due = null;
            for (var i = _timers.Count - 1; i >= 0; i--)
            {
                var t = _timers[i];
                if (t.Cancelled || t.Fired) { _timers.RemoveAt(i); continue; }
                if (t.At <= now) (due ??= new List<TimerHandle>()).Add(t);
            }
            if (due == null) return;
            due.Sort((a, b) => a.At.CompareTo(b.At));
            foreach (var t in due)
            {
                if (t.Cancelled) continue;
                t.Fired = true;
                _timers.Remove(t);
                t.Fire?.Invoke();
            }
        }

        // ---- persistence ----------------------------------------------------------------------------

        private TimerHandle _saveTimer;

        /// <summary>Coalesces the writes a fast player generates into one disk write.</summary>
        private void ScheduleSave()
        {
            Cancel(ref _saveTimer);
            _saveTimer = After(SaveDebounce, () => _svc.Store.Save(Snapshot()));
        }

        public void FlushSave()
        {
            if (_saveTimer != null && _saveTimer.Active)
            {
                Cancel(ref _saveTimer);
                _svc.Store.Save(Snapshot());
            }
        }

        private SavedGame Snapshot()
        {
            var s = State;
            return new SavedGame
            {
                Chips = s.Round.Chips,
                Stats = s.Round.Stats,
                History = s.Round.History,
                HourlyPoints = s.HeroHourlyPoints,
                DailyPoints = s.HeroDailyPoints,
                HourKey = s.HeroHourKey,
                DayKey = s.HeroDayKey,
                SoundOn = s.SoundOn,
                VoiceOn = s.VoiceOn,
                LanguageOverride = s.LanguageOverride,
                HapticsOn = s.HapticsOn,
                NotifSocial = s.NotifSocial,
                NotifLeaderboard = s.NotifLeaderboard,
                NotifDaily = s.NotifDaily,
                TutorialRoundsSeen = s.TutorialRoundsSeen,
                TutorialDismissed = s.TutorialDismissed,
                // Anywhere past the gate counts as done: the player got in, signed in or as a guest.
                OnboardingDone = s.Screen != AppScreen.Onboarding,
                AvatarColor = s.AvatarColor,
                RewardedReferralIds = s.RewardedReferralIds,
                PlayDayStreak = s.PlayDayStreak,
                LastPlayDayKey = s.LastPlayDayKey,
                LastRebuyAtMs = s.LastRebuyAt.HasValue ? new DateTimeOffset(s.LastRebuyAt.Value).ToUnixTimeMilliseconds() : 0,
                AnalyticsOn = s.AnalyticsOn,
                ReviewPromptShown = s.ReviewPromptShown,
                ReviewLastAttemptAtMs = s.ReviewLastAttemptAtMs,
                ReviewRequestCount = s.ReviewRequestCount,
                ReviewLastRequestSucceeded = s.ReviewLastRequestSucceeded,
                TutorialCompletionLogged = s.TutorialCompletionLogged,
            };
        }

        private void Hydrate()
        {
            var saved = _svc.Store.Load();
            if (saved == null) return;
            var now = _now();
            var hourKey = Points.HourKeyOf(now);
            var dayKey = Points.DayKeyOf(now);
            // A legacy blob that recorded "shown" but never an attempt time starts its cooldown now.
            var legacyReview = saved.ReviewPromptShown && saved.ReviewLastAttemptAtMs == 0;
            Set(s => s with
            {
                Round = s.Round with { Chips = saved.Chips, Stats = saved.Stats, History = saved.History },
                // Points from an earlier hour/day are worth nothing now.
                HeroHourlyPoints = Points.Rolled(saved.HourlyPoints, saved.HourKey, hourKey),
                HeroDailyPoints = Points.Rolled(saved.DailyPoints, saved.DayKey, dayKey),
                HeroHourKey = hourKey,
                HeroDayKey = dayKey,
                SoundOn = saved.SoundOn,
                VoiceOn = saved.VoiceOn,
                LanguageOverride = saved.LanguageOverride,
                HapticsOn = saved.HapticsOn,
                NotifSocial = saved.NotifSocial,
                NotifLeaderboard = saved.NotifLeaderboard,
                NotifDaily = saved.NotifDaily,
                TutorialRoundsSeen = saved.TutorialRoundsSeen,
                TutorialDismissed = saved.TutorialDismissed,
                // `screen` itself is never persisted: dropping someone onto the felt mid-round is not "where I left off".
                Screen = saved.OnboardingDone ? AppScreen.Lobby : s.Screen,
                AvatarColor = saved.AvatarColor,
                RewardedReferralIds = saved.RewardedReferralIds,
                PlayDayStreak = saved.PlayDayStreak,
                LastPlayDayKey = saved.LastPlayDayKey,
                LastRebuyAt = saved.LastRebuyAtMs == 0 ? (DateTime?)null : DateTimeOffset.FromUnixTimeMilliseconds(saved.LastRebuyAtMs).LocalDateTime,
                AnalyticsOn = saved.AnalyticsOn,
                ReviewPromptShown = saved.ReviewPromptShown,
                ReviewLastAttemptAtMs = legacyReview ? new DateTimeOffset(now).ToUnixTimeMilliseconds() : saved.ReviewLastAttemptAtMs,
                ReviewRequestCount = legacyReview ? 1 : saved.ReviewRequestCount,
                ReviewLastRequestSucceeded = saved.ReviewLastRequestSucceeded || legacyReview,
                TutorialCompletionLogged = saved.TutorialCompletionLogged,
            });
            Loc.Use(saved.LanguageOverride);
            _svc.Analytics.SetEnabled(saved.AnalyticsOn);
            if (legacyReview) _svc.Store.Save(Snapshot());
        }

        // ---- boot ----------------------------------------------------------------------------------

        private void Boot()
        {
            Hydrate();
            _svc.Notifier.Init();
            RestoreDailyBonus();
            InitSocial();
        }

        private void OnApplicationPause(bool paused)
        {
            if (paused) OnAppPaused(); else OnAppResumed();
        }

        private void OnApplicationQuit() => FlushSave();

        public void OnAppResumed()
        {
            _playTime.Resume();
            if (!State.SocialReady) return;
            Heartbeat();
            SyncDailyBonusReminder();
            SyncStreakReminder();
            if (State.PendingJoinCode != null) JoinCode(State.PendingJoinCode, viaLink: true);
        }

        public void OnAppPaused()
        {
            FlushSave();
            _playTime.Pause();
            if (State.SocialReady) _svc.Social.AddPlayTime(_playTime.TakeSeconds());
        }

        // ---- navigation -----------------------------------------------------------------------------

        public void GoLobby() => Navigate(AppScreen.Lobby);
        public void GoStats() => Navigate(AppScreen.Stats);
        public void GoSettings() => Navigate(AppScreen.Settings);

        public void GoFriends()
        {
            Navigate(AppScreen.Friends);
            PrefillJoinFromClipboard();
        }

        private void Navigate(AppScreen screen)
        {
            Set(s => s with { Screen = screen });
            _svc.Analytics.LogScreen(screen.ToString().ToLowerInvariant());
        }

        /// <summary>The Android back button: closes the topmost thing, or steps back one screen. True when handled.</summary>
        public bool HandleBack()
        {
            var s = State;
            // Dialogs and sheets live in the UI layer and take the back press first.
            if (OverlayBack != null && OverlayBack()) return true;
            if (s.TableChatOpen) { ToggleTableChat(); return true; }
            if (s.TableMenuOpen) { ToggleTableMenu(); return true; }
            switch (s.Screen)
            {
                case AppScreen.Table: ExitTable(); return true;
                case AppScreen.Stats:
                case AppScreen.Friends:
                case AppScreen.Settings: GoLobby(); return true;
                default: return false;
            }
        }

        // ---- toasts / reactions / chat --------------------------------------------------------------

        private TimerHandle _toastTimer, _reactTimer;

        public void ShowToast(string text)
        {
            Set(s => s with { Toast = text });
            Cancel(ref _toastTimer);
            _toastTimer = After(ToastSeconds, () => Set(s => s with { Toast = "" }));
        }

        public void SendReaction(string label)
        {
            Set(s => s with { ReactionFloat = label, ReactionId = s.ReactionId + 1 });
            Cancel(ref _reactTimer);
            _reactTimer = After(ReactionSeconds, () => Set(s => s with { ReactionFloat = "" }));
        }

        /// <summary>A quick-reply chip: posts a "You" bubble into the table chat and floats it over the felt. Canned only.</summary>
        public void SendChatMessage(string text)
        {
            var messages = State.ChatMessages
                .Append(new ChatMessage("You", text, DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()))
                .ToList();
            Set(s => s with { ChatMessages = Trim(messages) });
            SendReaction(text);
            _svc.Haptics.Selection();
        }

        private static IReadOnlyList<ChatMessage> Trim(List<ChatMessage> messages) =>
            messages.Count > ChatLogLimit ? messages.GetRange(messages.Count - ChatLogLimit, ChatLogLimit) : messages;

        public void ToggleTableMenu() => Set(s => s with { TableMenuOpen = !s.TableMenuOpen });
        public void ToggleTableChat() => Set(s => s with { TableChatOpen = !s.TableChatOpen, TableMenuOpen = false });

        // ---- settings -------------------------------------------------------------------------------

        public void SelectAvatarColor(int argb)
        {
            Set(s => s with { AvatarColor = argb });
            ScheduleSave();
        }

        public void ToggleHaptics()
        {
            var next = !State.HapticsOn;
            Set(s => s with { HapticsOn = next });
            if (next) _svc.Haptics.Medium();
            ScheduleSave();
        }

        /// <summary>Muting takes the voice queue with it — a call-out already queued is waiting there, not on a timer.</summary>
        public void ToggleSound()
        {
            var next = !State.SoundOn;
            Set(s => s with { SoundOn = next });
            if (next) _svc.Sound.Play(GameSfx.Chip);
            else { CancelVoiceTimers(); _svc.Sound.SilenceVoice(); }
            ScheduleSave();
        }

        /// <summary>Turning voice back on answers in the voice itself — "You have twenty one".</summary>
        public void ToggleVoice()
        {
            var next = !State.VoiceOn;
            Set(s => s with { VoiceOn = next });
            if (!next) { CancelVoiceTimers(); _svc.Sound.SilenceVoice(); }
            else if (State.SoundOn)
                _svc.Sound.PlayWords(new[] { "you_have" }.Concat(SpokenAmount.Words(21)).ToList());
            ScheduleSave();
        }

        public void SetLanguage(string code)
        {
            Set(s => s with { LanguageOverride = code });
            Loc.Use(code);
            ScheduleSave();
        }

        /// <summary>
        /// Turning a notification switch on is the consent moment: ask the OS then. If it is declined the
        /// switch stays off rather than sitting there lit while nothing can be delivered.
        /// </summary>
        private void EnsureNotifPermission(Action granted)
        {
            if (_svc.Notifier.HasPermission) { granted(); return; }
            _svc.Notifier.RequestPermission(ok =>
            {
                if (ok) granted();
                else ShowToast(Loc.Or("notifPermissionOff", "Notifications are off for this app in system settings"));
            });
        }

        public void ToggleNotifSocial()
        {
            void Flip() { Set(s => s with { NotifSocial = !s.NotifSocial }); ScheduleSave(); }
            if (State.NotifSocial) Flip(); else EnsureNotifPermission(Flip);
        }

        public void ToggleNotifLeaderboard()
        {
            void Flip() { Set(s => s with { NotifLeaderboard = !s.NotifLeaderboard }); ScheduleSave(); }
            if (State.NotifLeaderboard) Flip(); else EnsureNotifPermission(Flip);
        }

        public void ToggleNotifDaily()
        {
            void Flip()
            {
                Set(s => s with { NotifDaily = !s.NotifDaily });
                // Off cancels both pending reminders; on re-arms whichever applies.
                SyncDailyBonusReminder();
                SyncStreakReminder();
                ScheduleSave();
            }
            if (State.NotifDaily) Flip(); else EnsureNotifPermission(Flip);
        }

        public void SetAnalytics(bool on)
        {
            Set(s => s with { AnalyticsOn = on });
            _svc.Analytics.SetEnabled(on);
            ScheduleSave();
        }

        public void SetStatsTab(StatsTab tab) => Set(s => s with { StatsTab = tab });
        public void SetLeaderboardPeriod(LeaderboardPeriod period) => Set(s => s with { LeaderboardPeriod = period });
        public void OnFriendCodeInput(string value) => Set(s => s with { FriendCodeInput = (value ?? "").ToUpperInvariant() });
    }
}
