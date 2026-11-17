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

        /// <summary>Plays a video and pays out only if the player watched it through.</summary>
        public void WatchAdForChips()
        {
            if (!AdReward.IsReady(State.LastAdRewardAt, _now()) || !_svc.Ads.RewardedReady) return;
            _svc.Ads.ShowRewarded(earned =>
            {
                if (!earned) return;
                var at = _now();
                Set(s => s with
                {
                    Round = s.Round with { Chips = s.Round.Chips + AdReward.Chips },
                    LastAdRewardAt = at,
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
            _handsSinceAd++;
            var now = _now();
            var tutorialDone = State.TutorialDismissed || State.TutorialRoundsSeen >= Tutorial.Rounds;
            if (!AdPacing.IsDue(_handsSinceAd, _lastBreakAdAt, now, tutorialDone)) return;
            if (!_svc.Ads.InterstitialReady) return;
            SetAdBreak(true);
            _breakAdSafety = After(BreakAdSafetySeconds, () => SetAdBreak(false));
            _breakAdTimer = After(BreakAdDelaySeconds, ShowBreakAd);
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
