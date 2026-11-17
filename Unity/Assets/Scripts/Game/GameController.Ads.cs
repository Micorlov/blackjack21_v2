using System;
using System.Collections.Generic;
using Blackjack.Core;
using Blackjack.Game.Services;

namespace Blackjack.Game
{
    /// <summary>The two ads in the game: a video the player chooses to watch for chips, and a paced break between hands.</summary>
    public sealed partial class GameController
    {
        private int _handsSinceAd;
        private DateTime? _lastBreakAdAt;

        /// <summary>True when a rewarded video can be offered right now: cooled down, under the daily cap, and one is loaded.</summary>
        public bool RewardedOfferAvailable =>
            AdReward.IsAvailable(State.LastAdRewardAt, State.AdRewardsToday, State.AdRewardsDayKey, _now()) && _svc.Ads.RewardedReady;

        /// <summary>Raised, between hands, when the stack is low and a video could top it up. The UI shows a sheet the player can dismiss.</summary>
        public event Action LowChipsOffer;

        private bool _lowChipsOffered;

        /// <summary>
        /// Offers, once per dip, a rewarded video when the stack is under <see cref="AdReward.LowChipsBets"/> minimum bets. Never during
        /// a hand, never alongside a between-hands ad, never twice until the stack has recovered. Only an offer: nothing plays unless tapped.
        /// </summary>
        private void MaybeOfferLowChips(bool adBreakScheduled)
        {
            var stake = State.Round.Stake;
            var minBet = stake?.Min ?? TableCatalog.ChipDenoms[0];
            var low = State.Round.Chips < minBet * AdReward.LowChipsBets;
            if (!low) { _lowChipsOffered = false; return; }
            if (_lowChipsOffered || adBreakScheduled || State.Round.Phase != RoundPhase.Betting) return;
            if (!RewardedOfferAvailable) return;
            _lowChipsOffered = true;
            LowChipsOffer?.Invoke();
        }

        /// <summary>Plays a video and pays out only if the player watched it through.</summary>
        public void WatchAdForChips()
        {
            var now0 = _now();
            if (!AdReward.IsAvailable(State.LastAdRewardAt, State.AdRewardsToday, State.AdRewardsDayKey, now0) || !_svc.Ads.RewardedReady) return;
            _svc.Ads.ShowRewarded(earned =>
            {
                if (!earned) return;
                var at = _now();
                var paid = AdReward.PaidToday(State.AdRewardsToday, State.AdRewardsDayKey, at) + 1;
                Set(s => s with
                {
                    Round = s.Round with { Chips = s.Round.Chips + AdReward.Chips },
                    LastAdRewardAt = at,
                    AdRewardsToday = paid,
                    AdRewardsDayKey = Points.DayKeyOf(at),
                });
                ScheduleSave();
                ShowToast(Loc.Or("toastAdChips", "+{chips} chips", ("chips", TableCatalog.FormatChips(AdReward.Chips))));
                PlaySfx(GameSfx.Win);
                HapticMedium();
                _svc.Analytics.LogEvent(AnalyticsEvent.AdRewardEarned);
            });
        }

        /// <summary>Pause between the Next Hand tap and the ad, so the ad never opens under the player's finger.</summary>
        public const double BreakAdDelaySeconds = 1.0;
        private const double BreakAdSafetySeconds = 120;
        private TimerHandle _breakAdTimer, _breakAdSafety;

        /// <summary>
        /// Called as a finished hand clears. A hand counts towards the next ad whether or not one is ready. When an ad is due
        /// and loaded, the next hand is still dealt at once, but the ad waits <see cref="BreakAdDelaySeconds"/> and input is
        /// swallowed until it has closed. With no ad due or ready nothing is delayed.
        /// </summary>
        private void MaybeShowBreakAd()
        {
            var scheduled = TryScheduleBreakAd();
            MaybeOfferLowChips(scheduled);
        }

        private bool TryScheduleBreakAd()
        {
            _handsSinceAd++;
            var now = _now();
            var tutorialDone = State.TutorialDismissed || State.TutorialRoundsSeen >= Tutorial.Rounds;
            if (!AdPacing.IsDue(_handsSinceAd, _lastBreakAdAt, now, tutorialDone)) return false;
            if (!_svc.Ads.InterstitialReady) return false;
            SetAdBreak(true);
            _breakAdSafety = After(BreakAdSafetySeconds, () => SetAdBreak(false));
            _breakAdTimer = After(BreakAdDelaySeconds, ShowBreakAd);
            return true;
        }

        private void ShowBreakAd()
        {
            _breakAdTimer = null;
            if (!_svc.Ads.ShowInterstitial(() => SetAdBreak(false)))
            {
                SetAdBreak(false);
                return;
            }
            _handsSinceAd = 0;
            _lastBreakAdAt = _now();
            _svc.Analytics.LogEvent(AnalyticsEvent.BreakAdShown);
        }

        private void SetAdBreak(bool on)
        {
            if (!on) { Cancel(ref _breakAdTimer); Cancel(ref _breakAdSafety); }
            if (State.AdBreakActive != on) Set(s => s with { AdBreakActive = on });
        }
    }
}
