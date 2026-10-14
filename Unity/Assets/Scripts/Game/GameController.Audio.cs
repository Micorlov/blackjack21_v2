using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game.Services;
using UnityEngine;

namespace Blackjack.Game
{
    /// <summary>Sound, voice and haptic cueing — the timings are the Flutter game's, kept verbatim.</summary>
    public sealed partial class GameController
    {
        // Held back so the settlement tone plays out first and the spoken result follows it.
        public const float VoiceLead = 0.7f;
        public const float HandTotalVoiceLead = 0.35f;
        public const float TurnVoiceLead = 0.7f;
        public const float PostPotPause = 1f;
        public const float DealerVoiceLead = 0.2f;
        public const float DealerRevealVoiceLead = 0.5f;
        public const float DealerVoiceTail = 0.25f;
        private const float HoleCardFlipPause = 0.5f;

        private TimerHandle _voiceTimer, _potTimer, _celebrationTimer, _handTotalTimer, _dealerTotalTimer;

        private bool VoiceAllowed => State.SoundOn && State.VoiceOn;

        private void CancelVoiceTimers()
        {
            Cancel(ref _voiceTimer);
            Cancel(ref _potTimer);
            Cancel(ref _handTotalTimer);
            Cancel(ref _celebrationTimer);
        }

        private void PlaySfx(GameSfx sfx)
        {
            if (State.SoundOn) _svc.Sound.Play(sfx);
        }

        /// <summary>
        /// A round-outcome tone. <paramref name="afterFlip"/> holds it until the hole-card flip has finished:
        /// a natural reveals the card and settles in the same beat, and the tone must not beat the flip.
        /// </summary>
        private void PlayOutcomeTone(GameSfx sfx, bool afterFlip)
        {
            if (!afterFlip) { PlaySfx(sfx); return; }
            After(HoleCardFlipPause, () => PlaySfx(sfx));
        }

        /// <summary>An opponent seat's "Stand"/"Bust" line, queued behind whatever is already speaking.</summary>
        private void PlaySpokenVoice(GameVoice voice)
        {
            if (VoiceAllowed) _svc.Sound.PlayVoice(voice);
        }

        /// <summary>With voice off there is no call-out to clear, so the pot flourish follows the tone directly.</summary>
        private void CelebrateSweep()
        {
            if (!State.SoundOn || VoiceAllowed) return;
            Cancel(ref _celebrationTimer);
            _celebrationTimer = After(VoiceLead, () => PlaySfx(GameSfx.PotCelebration));
        }

        /// <summary>
        /// Speaks the hand's result <see cref="VoiceLead"/> after the outcome tone. When <paramref name="celebrate"/>
        /// the sweep drum is scheduled from the moment the words actually finish.
        /// </summary>
        private void PlayVoice(GameVoice voice, bool celebrate = false)
        {
            if (!VoiceAllowed) return;
            Cancel(ref _voiceTimer);
            _voiceTimer = After(VoiceLead, () =>
            {
                if (!VoiceAllowed) return;
                var endsAt = _svc.Sound.PlayVoice(voice);
                if (!celebrate || endsAt == null || !State.SoundOn) return;
                Cancel(ref _celebrationTimer);
                var wait = Math.Max(0, endsAt.Value - Clock());
                _celebrationTimer = After(wait, () => PlaySfx(GameSfx.PotCelebration));
            });
        }

        private void HapticSelection() { if (State.HapticsOn) _svc.Haptics.Selection(); }
        private void HapticLight() { if (State.HapticsOn) _svc.Haptics.Light(); }
        private void HapticMedium() { if (State.HapticsOn) _svc.Haptics.Medium(); }

        /// <summary>A roll of taps building to one heavy hit, for a natural or a table sweep.</summary>
        private void HapticCelebrate()
        {
            if (!State.HapticsOn) return;
            _svc.Haptics.Medium();
            for (var i = 1; i <= 2; i++) After(0.09 * i, () => { if (State.HapticsOn) _svc.Haptics.Medium(); });
            After(0.32, () => { if (State.HapticsOn) _svc.Haptics.Heavy(); });
        }

        /// <summary>A longer, distinct buzz so the player notices when action returns to them.</summary>
        private void HapticTurnAlert()
        {
            if (!State.HapticsOn) return;
            _svc.Haptics.Vibrate();
            After(0.22, () => { if (State.HapticsOn) _svc.Haptics.Vibrate(); });
        }

        private void NotifyPlayerTurn()
        {
            PlaySfx(GameSfx.Turn);
            HapticTurnAlert();
            AnnounceTurn();
        }

        /// <summary>What the table is playing for, then a beat, then the hand the hero has to play it with.</summary>
        private void AnnounceTurn()
        {
            if (!VoiceAllowed) return;
            var cards = Round.ActiveHand.Cards;
            var pot = PotWords();

            Cancel(ref _potTimer);
            _potTimer = After(TurnVoiceLead, () =>
            {
                if (!VoiceAllowed) return;
                var endsAt = _svc.Sound.PlayWords(pot);
                // The pot line's length depends on the figure, so the pause is measured from when it finishes.
                var remaining = endsAt.HasValue ? Math.Max(0, endsAt.Value - Clock()) : 0;
                var lead = (float)remaining + PostPotPause;

                // A quick player can hit or stand while the pot is still being called; their move announces the new total.
                if (Round.Phase != RoundPhase.Playing) return;
                if (!Round.ActiveHand.Cards.SequenceEqual(cards)) return;
                AnnounceHandTotal(cards, lead);
            });
        }

        private IReadOnlyList<string> PotWords()
        {
            var pot = TablePot.Live(Round);
            if (!pot.IsSweep) return new[] { "no_sweep_pot" };
            var amount = SpokenAmount.Words(pot.Amount);
            if (amount.Count == 0) return new[] { "no_sweep_pot" };
            return new[] { "sweep_pot" }.Concat(amount).Append("dollars").ToList();
        }

        /// <summary>The hero's hand total, called when action reaches them and after every card they take. Over 21 is a bust.</summary>
        private void AnnounceHandTotal(IReadOnlyList<PlayingCard> cards, float lead = HandTotalVoiceLead)
        {
            if (!VoiceAllowed) return;
            var value = BlackjackRules.HandValue(cards);
            List<string> line;
            if (value > 21) line = new List<string> { "player_bust" };
            else
            {
                var words = SpokenAmount.Words(value);
                if (words.Count == 0) return;
                line = new[] { "you_have" }.Concat(words).ToList();
            }
            Cancel(ref _handTotalTimer);
            _handTotalTimer = After(lead, () => { if (VoiceAllowed) _svc.Sound.PlayWords(line); });
        }

        /// <summary>
        /// What the dealer holds, as words. A natural and a bust are named; "Dealer has" is said once, on the
        /// reveal, and later draws are just the running total. Null when there is nothing to say.
        /// </summary>
        private IReadOnlyList<string> DealerTotalWords(bool opening)
        {
            if (!VoiceAllowed) return null;
            var hand = Round.DealerHand;
            var value = BlackjackRules.HandValue(hand);
            if (value > 21) return new[] { "dealer_bust" };
            if (hand.Count == 2 && value == 21) return new[] { "dealer_has", "blackjack" };
            var words = SpokenAmount.Words(value);
            if (words.Count == 0) return null;
            return opening ? new[] { "dealer_has" }.Concat(words).ToList() : words;
        }

        /// <summary>Speaks the dealer's total where nothing follows it — the natural that settles the round.</summary>
        private void AnnounceDealerTotal()
        {
            var words = DealerTotalWords(opening: true);
            if (words == null) return;
            Cancel(ref _dealerTotalTimer);
            _dealerTotalTimer = After(DealerVoiceLead, () => { if (VoiceAllowed) _svc.Sound.PlayWords(words); });
        }
    }
}
