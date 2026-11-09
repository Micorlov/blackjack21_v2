using System;
using System.Collections.Generic;
using Blackjack.Core;
using Blackjack.Game.Services;

namespace Blackjack.Game
{
    /// <summary>The opted-in rewarded video and the paced break between hands. The banner is reserved by the UI.</summary>
    public sealed partial class GameController
    {
        private int _handsSinceAd;
        private DateTime? _lastBreakAdAt;

        /// <summary>Plays a video and pays out only if the player watched it through.</summary>
        public void WatchAdForChips()
        {
            if (!AdReward.IsReady(State.LastAdRewardAt, _now()) || !_svc.Ads.RewardedReady) return;
            var paid = false;
            _svc.Ads.ShowRewarded(earned =>
            {
                // The SDK can report close and failure both; chips are paid once.
                if (paid || !earned) return;
                paid = true;
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

        /// <summary>
        /// Called once the player asks for the next hand, which is waiting on a bet: no cards are in play and the
        /// turn clock is not running. A hand counts towards the next ad whether or not one is ready.
        /// </summary>
        private void MaybeShowBreakAd()
        {
            _handsSinceAd++;
            var now = _now();
            var tutorialDone = State.TutorialDismissed || State.TutorialRoundsSeen >= Tutorial.Rounds;
            if (!AdPacing.IsDue(_handsSinceAd, _lastBreakAdAt, now, tutorialDone)) return;
            if (State.Round.Phase != RoundPhase.Betting) return;
            if (!_svc.Ads.ShowInterstitial()) return;
            _handsSinceAd = 0;
            _lastBreakAdAt = now;
            _svc.Analytics.LogEvent(AnalyticsEvent.BreakAdShown);
        }
    }
}
