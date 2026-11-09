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

        /// <summary>
        /// Called as a finished hand clears. Nothing is dealt or timed at this point, so the ad interrupts nothing, and
        /// a hand counts towards the next one whether or not an ad is ready.
        /// </summary>
        private void MaybeShowBreakAd()
        {
            _handsSinceAd++;
            var now = _now();
            var tutorialDone = State.TutorialDismissed || State.TutorialRoundsSeen >= Tutorial.Rounds;
            if (!AdPacing.IsDue(_handsSinceAd, _lastBreakAdAt, now, tutorialDone)) return;
            if (!_svc.Ads.ShowInterstitial()) return;
            _handsSinceAd = 0;
            _lastBreakAdAt = now;
            _svc.Analytics.LogEvent(AnalyticsEvent.BreakAdShown);
        }
    }
}
