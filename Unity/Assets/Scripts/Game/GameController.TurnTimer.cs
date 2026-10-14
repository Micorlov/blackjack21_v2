using System;
using Blackjack.Core;

namespace Blackjack.Game
{
    /// <summary>
    /// The casino turn clock: the hero's hand stands by itself after <see cref="TurnSeconds"/>. The clock starts
    /// when the hero's turn begins and again on each split hand (hitting does not restart it). It never runs on a
    /// coached tutorial hand, and it pauses while the app is in the background or the chat or menu is open.
    /// </summary>
    public sealed partial class GameController
    {
        public const float TurnSeconds = 20f;

        private bool _appInBackground;

        /// <summary>Which hand the running clock belongs to; a new hand (a split) gets a fresh clock.</summary>
        private int _turnHandKey = -1;

        /// <summary>Seconds left when the clock was paused, so it resumes rather than restarts.</summary>
        private double? _turnRemaining;

        /// <summary>Seconds until the hero's hand stands by itself, or null when no clock is running.</summary>
        public float? TurnSecondsLeft =>
            Round.TurnDeadline is double deadline ? (float)Math.Max(0, deadline - Clock()) : (float?)null;

        /// <summary>Seconds left on a paused clock (the chat is open, the app is in the background), else null.</summary>
        public float? TurnSecondsPaused => Round.TurnDeadline == null && _turnRemaining.HasValue ? (float)_turnRemaining.Value : (float?)null;

        private bool TutorialHand => !State.TutorialDismissed && State.TutorialRoundsSeen < Tutorial.Rounds;

        private bool TurnClockApplies =>
            State.TurnTimerOn && State.Screen == AppScreen.Table && Round.Phase == RoundPhase.Playing && !TutorialHand;

        private bool TurnClockPaused => _appInBackground || State.TableChatOpen || State.TableMenuOpen;

        public void ToggleTurnTimer()
        {
            Set(s => s with { TurnTimerOn = !s.TurnTimerOn });
            HapticSelection();
            ScheduleSave();
        }

        /// <summary>Starts, pauses, resumes and fires the clock. Runs every frame from <see cref="Tick"/>.</summary>
        private void TickTurnTimer()
        {
            if (!TurnClockApplies)
            {
                _turnHandKey = -1;
                _turnRemaining = null;
                if (Round.TurnDeadline != null) SetRound(r => r with { TurnDeadline = null });
                return;
            }

            var key = Round.ActiveHandIndex * 16 + Round.Hands.Count;
            if (key != _turnHandKey)
            {
                _turnHandKey = key;
                _turnRemaining = TurnSeconds;
                if (Round.TurnDeadline != null) SetRound(r => r with { TurnDeadline = null });
            }

            if (TurnClockPaused)
            {
                PauseTurnClock();
                return;
            }

            if (Round.TurnDeadline == null)
            {
                var deadline = Clock() + (_turnRemaining ?? TurnSeconds);
                _turnRemaining = null;
                SetRound(r => r with { TurnDeadline = deadline });
                return;
            }

            if (Clock() < Round.TurnDeadline.Value) return;
            // Cleared first so a split's next hand never shows an expired clock for a frame.
            SetRound(r => r with { TurnDeadline = null });
            ShowToast(Loc.Or("toastTurnTimeUp", "Time's up — you stand"));
            PlayerStand();
        }

        /// <summary>
        /// Banks the seconds left and stops the clock. Called the moment the app goes to the background, because
        /// a phone stops calling Update there: waiting for the next tick would find the deadline long past.
        /// </summary>
        private void PauseTurnClock()
        {
            if (!(Round.TurnDeadline is double running)) return;
            _turnRemaining = Math.Max(0, running - Clock());
            SetRound(r => r with { TurnDeadline = null });
        }
    }
}
