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
