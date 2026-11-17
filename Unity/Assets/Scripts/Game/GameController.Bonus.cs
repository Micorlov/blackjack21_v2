using System;
using System.Collections.Generic;
using Blackjack.Core;
using Blackjack.Game.Services;

namespace Blackjack.Game
{
    /// <summary>The once-a-day chip claim with its 7-day ladder, the play-day streak bonus, and their reminders.</summary>
    public sealed partial class GameController
    {
        /// <summary>Restores the persisted last claim, then re-arms the reminders (their fixed ids make that idempotent).</summary>
        private void RestoreDailyBonus()
        {
            var last = _svc.Store.LoadLastClaim();
            var streakDay = _svc.Store.LoadStreakDay();
            if (last == null) return;
            Set(s => s with { LastDailyBonusClaimAt = last, DailyBonusStreakDay = streakDay });
            SyncDailyBonusReminder();
            SyncStreakReminder();
        }

        /// <summary>Keeps at most one pending "daily chips ready" notification, matching the cooldown and the Settings toggle.</summary>
        private void SyncDailyBonusReminder()
        {
            var now = _now();
            var last = State.LastDailyBonusClaimAt;
            if (!State.NotifDaily || last == null || DailyBonus.IsReady(last, now))
            {
                _svc.Notifier.CancelDailyBonusReminder();
                return;
            }
            // Quote what a claim at the moment of unlock would pay: day 7 is worth 1,000, and a play streak still
            // standing then adds its own bonus on top.
            var unlockAt = last.Value.Add(DailyBonus.Cooldown);
            var dayAtUnlock = DailyBonus.NextStreakDay(State.DailyBonusStreakDay, last, unlockAt);
            _svc.Notifier.ScheduleDailyBonusReminder(unlockAt - now,
                DailyBonus.RewardForDay(dayAtUnlock) + PlayStreakBonusAt(unlockAt));
        }

        /// <summary>At most one pending "streak ends tonight" notification; shares the Daily reminder toggle.</summary>
        private void SyncStreakReminder()
        {
            var now = _now();
            var live = PlayStreak.Live(State.PlayDayStreak, State.LastPlayDayKey, now);
            var at = State.NotifDaily
                ? PlayStreak.ReminderAt(live, PlayStreak.PlayedToday(State.LastPlayDayKey, now), now)
                : null;
            if (at == null)
            {
                _svc.Notifier.CancelStreakReminder();
                return;
            }
            _svc.Notifier.ScheduleStreakReminder(at.Value - now, live);
        }

        /// <summary>Extra chips a live play-day streak adds on top of the claim ladder; the claim and its reminder both quote this.</summary>
        private int PlayStreakBonusAt(DateTime now) =>
            PlayStreak.BonusChips(PlayStreak.Live(State.PlayDayStreak, State.LastPlayDayKey, now));

        // ---- the 8 PM evening gift (separate from the claim ladder above) ----------------------------

        /// <summary>
        /// Keeps one repeating 8 PM notification pending, first firing at the next 20:00 on the device clock, or none when the
        /// Daily reminder switch is off. Run on launch, on every resume (which catches a new day, a time-zone change or a moved
        /// clock) and when the switch flips; the fixed id makes it replace whatever was pending.
        /// </summary>
        private void SyncEveningGift()
        {
            if (!State.NotifDaily) { _svc.Notifier.CancelEveningGift(); return; }
            _svc.Notifier.ScheduleEveningGift(EveningGift.NextFire(_now()));
        }

        /// <summary>If the app was opened from the gift notification, pay it (once a day) and re-arm the next one.</summary>
        private void CheckEveningGiftTap()
        {
            // A beat after launch or resume: the clock and the UI have not settled yet, and a toast raised at that instant
            // would expire before its first frame.
            Cancel(ref _giftTapTimer);
            _giftTapTimer = After(EveningGiftTapDelay, () =>
            {
                if (_svc.Notifier.ConsumeEveningGiftTap()) ClaimEveningGift();
            });
        }

        private const float EveningGiftTapDelay = 0.8f;
        private TimerHandle _giftTapTimer;

        /// <summary>+500 play chips once per local calendar date; a second tap the same day does nothing.</summary>
        public bool ClaimEveningGift()
        {
            var now = _now();
            if (!EveningGift.CanGrant(State.EveningGiftKey, now))
            {
                UnityEngine.Debug.Log("[Notif] evening gift already taken for " + EveningGift.KeyOf(now) + ", no credit");
                return false;
            }
            UnityEngine.Debug.Log("[Notif] evening gift credited +" + EveningGift.Chips + " for " + EveningGift.KeyOf(now)
                + " (balance " + State.Round.Chips + " -> " + (State.Round.Chips + EveningGift.Chips) + ")");
            Set(s => s with
            {
                Round = s.Round with { Chips = s.Round.Chips + EveningGift.Chips },
                EveningGiftKey = EveningGift.KeyOf(now),
            });
            ScheduleSave();
            ShowToast(Loc.Or("toastEveningGift", "+${chips} play chips — your evening gift!", ("chips", EveningGift.Chips)));
            PlaySfx(GameSfx.Win);
            HapticMedium();
            _svc.Analytics.LogEvent(AnalyticsEvent.EveningGiftClaimed);
            SyncEveningGift();
            return true;
        }

        /// <summary>
        /// After a won hand (never on first launch) offers the system notification dialog once, so the 8 PM gift can be delivered.
        /// Skipped while the review request is pending so two prompts never stack.
        /// </summary>
        private void MaybeAskNotifPermission()
        {
            if (_reviewPending) return;
            if (!NotifPermissionPrompt.ShouldAsk(true, State.Round.Stats.HandsPlayed, State.NotifPermissionAsked,
                    _svc.Notifier.HasPermission, State.NotifDaily)) return;
            Set(s => s with { NotifPermissionAsked = true });
            ScheduleSave();
            UnityEngine.Debug.Log("[Notif] asking for notification permission after a win");
            _svc.Analytics.LogEvent(AnalyticsEvent.NotifPermissionAsked);
            _svc.Notifier.RequestPermission(ok =>
            {
                if (ok) SyncEveningGift();
            });
        }

        /// <summary>Dev APK only (set by <c>QaNotifHook</c>, read under <c>BJ_QA_NOTIF</c>): every won hand counts as big. Always declared so the script layout matches across builds.</summary>
        [System.NonSerialized] public bool QaForceBigWin;

#if BJ_QA_NOTIF
        /// <summary>Dev APK only: pretend this install is three days old so the review prompt's first-day rule is out of the way.</summary>
        public void QaMakeSeasoned()
        {
            Set(s => s with { FirstSeenAtMs = new DateTimeOffset(_now().AddDays(-3)).ToUnixTimeMilliseconds() });
            ScheduleSave();
            UnityEngine.Debug.Log("[QA] install treated as 3 days old");
        }
#endif

        public void ClaimDailyBonus()
        {
            var now = _now();
            if (!DailyBonus.IsReady(State.LastDailyBonusClaimAt, now)) return;
            var day = DailyBonus.NextStreakDay(State.DailyBonusStreakDay, State.LastDailyBonusClaimAt, now);
            var streakBonus = PlayStreakBonusAt(now);
            var reward = DailyBonus.RewardForDay(day) + streakBonus;

            Set(s => s with
            {
                Round = s.Round with { Chips = s.Round.Chips + reward },
                LastDailyBonusClaimAt = now,
                DailyBonusStreakDay = day,
            });
            _svc.Store.SaveClaim(now, day);
            SyncDailyBonusReminder();
            ScheduleSave();

            var live = PlayStreak.Live(State.PlayDayStreak, State.LastPlayDayKey, now);
            ShowToast(streakBonus > 0
                ? Loc.Or("toastClaimStreak", "+{reward} chips claimed — day {day} of your streak, +{bonus} for playing {label}!",
                    ("reward", reward), ("day", day), ("bonus", streakBonus),
                    ("label", live == 1 ? "1 day in a row" : live + " days in a row"))
                : Loc.Or("toastClaim", "+{reward} chips claimed — day {day} of your streak!", ("reward", reward), ("day", day)));
            PlaySfx(GameSfx.Win);
            HapticMedium();
            _svc.Analytics.LogEvent(AnalyticsEvent.DailyBonusClaimed,
                new Dictionary<string, object> { ["day"] = day, ["reward"] = reward });
        }
    }
}
