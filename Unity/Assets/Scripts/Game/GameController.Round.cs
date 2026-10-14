using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game.Services;
using UnityEngine;

namespace Blackjack.Game
{
    /// <summary>The round: entering a table, betting, dealing, the paced NPC and dealer turns, and what a settlement triggers.</summary>
    public sealed partial class GameController
    {
        public const float NpcDecisionLead = 0.52f;
        public const float DealerRevealPause = 2f;
        private const float NpcHitPause = 0.6f;
        private const float NpcStandPause = 0.48f;
        private const float NpcHandOverPause = 0.38f;
        private const float DealerDrawPause = 0.6f;
        private const float DealerSettlePause = 0.48f;
        private const float ReviewPromptDelay = 1.5f;

        private TimerHandle _npcTimer, _dealerTimer, _reviewTimer;
        private bool _reviewPending;
        private IReadOnlyDictionary<string, bool> _flags = new Dictionary<string, bool>();

        private bool FlagEnabled(string flag) => !_flags.TryGetValue(flag, out var on) || on;

        private IReadOnlyList<string> SeatNames() =>
            Roster.TableSeats(State.Friends, Round.Stake?.Key).Select(f => f.FirstName).ToList();

        // ---- table entry ----------------------------------------------------------------------------

        public void EnterTable(TableStake stake)
        {
            Set(s => s with
            {
                Screen = AppScreen.Table,
                Round = RoundEngine.EnterTable(s.Round, stake, _rng),
            });
            // Publish table presence at once rather than waiting up to a minute for the heartbeat.
            ReportScore();
            _svc.Analytics.LogEvent(AnalyticsEvent.TableEntered, new Dictionary<string, object> { ["stake"] = stake.Key });
        }

        public void ExitTable()
        {
            Cancel(ref _npcTimer);
            Set(s => s with { Screen = AppScreen.Lobby, Round = RoundEngine.SetActingSeat(s.Round, null) });
            ReportScore();
        }

        // ---- betting --------------------------------------------------------------------------------

        public void PlaceBet(int amount)
        {
            var result = RoundEngine.PlaceBet(Round, amount);
            if (!result.Accepted) { ToastForRejection(result); return; }
            if (result.State == Round) return;
            SetRound(_ => result.State);
            PlaySfx(GameSfx.Chip);
            HapticSelection();
        }

        public void ClearBet() => SetRound(RoundEngine.ClearBet);

        public void BetAllIn()
        {
            var result = RoundEngine.BetAllIn(Round);
            if (!result.Accepted) { ToastForRejection(result); return; }
            if (result.State == Round) return;
            SetRound(_ => result.State);
            PlaySfx(GameSfx.Chip);
            HapticMedium();
        }

        /// <summary>Re-stakes the last bet and deals in one tap.</summary>
        public void RebetAndDeal()
        {
            var result = RoundEngine.Rebet(Round);
            if (!result.Accepted) { ToastForRejection(result); return; }
            if (result.State == Round) return;
            SetRound(_ => result.State);
            PlaySfx(GameSfx.Chip);
            HapticSelection();
            DealRound();
        }

        private void ToastForRejection(BetResult r)
        {
            switch (r.Rejection)
            {
                case Rejection.NotEnoughChips: ShowToast(Loc.Or("toastNotEnoughChips", "Not enough chips")); break;
                case Rejection.TableMaximum:
                    ShowToast(Loc.Or("toastTableMax", "Table maximum is ${amount}", ("amount", TableCatalog.FormatChips(r.Limit)))); break;
                case Rejection.TableMinimum:
                    ShowToast(Loc.Or("toastTableMin", "Table minimum is ${amount}", ("amount", TableCatalog.FormatChips(r.Limit)))); break;
            }
        }

        // ---- dealing --------------------------------------------------------------------------------

        public void DealRound()
        {
            if (!RoundEngine.CanDeal(Round)) return;
            var prev = Round;
            var next = RoundEngine.Deal(prev, _shoe, SeatNames());
            PlaySfx(GameSfx.Deal);
            HapticMedium();
            Transition(prev, next, holeJustRevealed: true);
        }

        /// <summary>
        /// Applies a state produced by the engine and starts whatever the new phase calls for: the NPC turns,
        /// the dealer's turn, or the settlement effects.
        /// </summary>
        private void Transition(RoundState prev, RoundState next, bool holeJustRevealed)
        {
            SetRound(_ => next);
            switch (next.Phase)
            {
                case RoundPhase.Npcs: StartNpcTurns(); break;
                case RoundPhase.Dealer when next.Phase != prev.Phase: StartDealer(); break;
                case RoundPhase.Settlement when prev.Phase != RoundPhase.Settlement:
                    // The only way to settle straight out of a deal/insurance is a dealer natural.
                    AnnounceDealerTotal();
                    OnSettled(prev, next, holeJustRevealed);
                    break;
            }
        }

        // ---- insurance ------------------------------------------------------------------------------

        public void TakeInsurance()
        {
            var prev = Round;
            HapticSelection();
            Transition(prev, RoundEngine.TakeInsurance(prev, SeatNames()), holeJustRevealed: true);
        }

        public void DeclineInsurance()
        {
            var prev = Round;
            HapticSelection();
            Transition(prev, RoundEngine.DeclineInsurance(prev, SeatNames()), holeJustRevealed: true);
        }

        // ---- hero actions ---------------------------------------------------------------------------

        private bool CanAct => Round.Phase == RoundPhase.Playing;

        public void PlayerHit()
        {
            if (!CanAct) return;
            var prev = Round;
            var next = RoundEngine.Hit(prev, _shoe);
            PlaySfx(GameSfx.Deal);
            HapticLight();
            AfterHeroAction(prev, next, announceHand: true);
        }

        public void PlayerStand()
        {
            if (!CanAct) return;
            var prev = Round;
            HapticSelection();
            AfterHeroAction(prev, RoundEngine.Stand(prev), announceHand: false);
        }

        public void PlayerDouble()
        {
            if (!CanAct || !RoundEngine.CanDouble(Round)) return;
            var prev = Round;
            var next = RoundEngine.Double(prev, _shoe);
            PlaySfx(GameSfx.Deal);
            HapticMedium();
            AfterHeroAction(prev, next, announceHand: true);
        }

        public void PlayerSplit()
        {
            if (!CanAct || !RoundEngine.CanSplit(Round)) return;
            var prev = Round;
            var next = RoundEngine.Split(prev, _shoe);
            PlaySfx(GameSfx.Deal);
            HapticMedium();
            AfterHeroAction(prev, next, announceHand: true);
        }

        public void PlayerSurrender()
        {
            if (!CanAct || !RoundEngine.CanSurrender(Round)) return;
            var prev = Round;
            HapticLight();
            AfterHeroAction(prev, RoundEngine.Surrender(prev), announceHand: false);
        }

        /// <summary>
        /// Applies a hero move, says the resulting total, and hands over to the dealer once every hand is done.
        /// When play moves to the second split hand its total is announced too, so the circle on screen and the
        /// last thing spoken never disagree.
        /// </summary>
        private void AfterHeroAction(RoundState prev, RoundState next, bool announceHand)
        {
            SetRound(_ => next);
            if (announceHand) AnnounceHandTotal(next.Hands[prev.ActiveHandIndex].Cards);
            if (next.ActiveHandIndex != prev.ActiveHandIndex && next.Phase == RoundPhase.Playing)
                AnnounceHandTotal(next.ActiveHand.Cards);
            if (next.Phase == RoundPhase.Dealer && prev.Phase != RoundPhase.Dealer) StartDealer();
        }

        // ---- opponent seats -------------------------------------------------------------------------

        private void StartNpcTurns()
        {
            if (Round.NpcSeats.Count == 0) { HandOverAfterSeats(); return; }
            StepNpc(0);
        }

        private void StepNpc(int k)
        {
            if (State.Screen != AppScreen.Table) return;
            if (k >= Round.NpcSeats.Count)
            {
                _npcTimer = After(NpcHandOverPause, HandOverAfterSeats);
                return;
            }
            SetRound(r => RoundEngine.SetActingSeat(r, k));
            _npcTimer = After(NpcDecisionLead, () => NpcDecide(k));
        }

        private void NpcDecide(int k)
        {
            if (State.Screen != AppScreen.Table) return;
            var hit = BlackjackRules.HandValue(Round.NpcSeats[k].Cards) < 17;
            SetRound(r => RoundEngine.NpcAct(r, _shoe, k));
            var seat = Round.NpcSeats[k];
            if (hit)
            {
                var bust = seat.Action == "BUST";
                if (bust) { PlaySpokenVoice(GameVoice.NpcBust); HapticLight(); }
                _npcTimer = After(NpcHitPause, () => { if (bust) StepNpc(k + 1); else NpcDecide(k); });
            }
            else
            {
                PlaySpokenVoice(GameVoice.NpcStand);
                HapticSelection();
                _npcTimer = After(NpcStandPause, () => StepNpc(k + 1));
            }
        }

        /// <summary>Action passes to the hero once every seat has played — unless they have nothing to decide (a natural).</summary>
        private void HandOverAfterSeats()
        {
            var prev = Round;
            SetRound(RoundEngine.HandOverAfterSeats);
            if (Round.Phase == RoundPhase.Dealer && prev.Phase != RoundPhase.Dealer) StartDealer();
            else if (Round.Phase == RoundPhase.Playing) NotifyPlayerTurn();
        }

        // ---- dealer ---------------------------------------------------------------------------------

        /// <summary>
        /// Reveals the hole card and hands the stage over before drawing, so the flip is its own beat. The
        /// dealer is paced like an NPC: it also waits out its own call-out before touching the next card.
        /// </summary>
        private void StartDealer()
        {
            if (Round.Phase != RoundPhase.Dealer) SetRound(RoundEngine.BeginDealer);
            DealerBeat(DealerRevealPause, DealerRevealVoiceLead, opening: true);
        }

        private void DealerBeat(float floor, float lead = DealerVoiceLead, bool opening = false)
        {
            Cancel(ref _dealerTimer);
            Cancel(ref _dealerTotalTimer);
            var floorEndsAt = Clock() + floor;
            _dealerTimer = After(floor, DealerDrawStep);

            var words = DealerTotalWords(opening);
            if (words == null) return;

            _dealerTotalTimer = After(lead, () =>
            {
                if (!VoiceAllowed) return;
                var endsAt = _svc.Sound.PlayWords(words);
                if (endsAt == null) return;
                // Only ever pushes the next card back, never pulls it forward.
                var until = endsAt.Value + DealerVoiceTail;
                if (until <= floorEndsAt) return;
                if (Round.Phase != RoundPhase.Dealer) return;
                Cancel(ref _dealerTimer);
                _dealerTimer = After(Math.Max(0, until - Clock()), DealerDrawStep);
            });
        }

        private void DealerDrawStep()
        {
            // If the player walked away mid-turn, finish at once: pacing is a nicety, settling is not optional.
            if (State.Screen != AppScreen.Table) { FinishDealerWithoutPacing(); return; }

            if (!RoundEngine.DealerShouldHit(Round.DealerHand))
            {
                Cancel(ref _dealerTimer);
                _dealerTimer = After(DealerSettlePause, () =>
                {
                    if (Round.Phase != RoundPhase.Dealer) return;
                    Settle(holeJustRevealed: false);
                });
                return;
            }

            SetRound(r => RoundEngine.DealerDraw(r, _shoe));
            PlaySfx(GameSfx.Deal);
            DealerBeat(DealerDrawPause);
        }

        private void FinishDealerWithoutPacing()
        {
            var hand = Round;
            while (RoundEngine.DealerShouldHit(hand.DealerHand)) hand = RoundEngine.DealerDraw(hand, _shoe);
            SetRound(_ => hand with { HoleRevealed = true });
            Settle(holeJustRevealed: false);
        }

        private void Settle(bool holeJustRevealed)
        {
            var prev = Round;
            var next = Settlement.Settle(prev with { HoleRevealed = true }, SeatNames());
            SetRound(_ => next);
            OnSettled(prev, next, holeJustRevealed);
        }

        // ---- what a settlement triggers -------------------------------------------------------------

        private void OnSettled(RoundState prev, RoundState next, bool holeJustRevealed)
        {
            var heroBlackjack = next.Message.StartsWith("Blackjack");
            var heroTakesPot = next.SweepInfo != null && next.SweepInfo.HeroTook;

            // Tone first, then a spoken result — every outcome gets one, a push included.
            if (heroBlackjack)
            {
                PlayOutcomeTone(GameSfx.Blackjack, holeJustRevealed);
                PlayVoice(heroTakesPot ? GameVoice.PlayerBlackjackPot : GameVoice.PlayerBlackjack, celebrate: heroTakesPot);
                if (heroTakesPot) CelebrateSweep();
                HapticCelebrate();
            }
            else if (next.MessageType == MessageType.Win)
            {
                PlayOutcomeTone(GameSfx.Win, holeJustRevealed);
                if (heroTakesPot)
                {
                    PlayVoice(GameVoice.PlayerPot, celebrate: true);
                    CelebrateSweep();
                    HapticCelebrate();
                }
                else
                {
                    PlayVoice(GameVoice.PlayerWin);
                    HapticMedium();
                }
            }
            else if (next.MessageType == MessageType.Lose)
            {
                PlayOutcomeTone(GameSfx.Lose, holeJustRevealed);
                PlayVoice(GameVoice.PlayerLose);
                HapticLight();
            }
            else
            {
                PlayOutcomeTone(GameSfx.Push, holeJustRevealed);
                PlayVoice(GameVoice.Push);
                HapticSelection();
            }

            // Hourly/daily buckets roll over when the clock period changed, then absorb this round's net result.
            var now = _now();
            var hourKey = Points.HourKeyOf(now);
            var dayKey = Points.DayKeyOf(now);
            var heroHourly = Points.Rolled(State.HeroHourlyPoints, State.HeroHourKey, hourKey) + next.RoundNet;
            var heroDaily = Points.Rolled(State.HeroDailyPoints, State.HeroDayKey, dayKey) + next.RoundNet;
            var advanced = PlayStreak.Advance(State.PlayDayStreak, State.LastPlayDayKey, now);
            var streakExtended = advanced.Streak != State.PlayDayStreak;

            Set(s => s with
            {
                HeroHourlyPoints = heroHourly,
                HeroDailyPoints = heroDaily,
                HeroHourKey = hourKey,
                HeroDayKey = dayKey,
                PlayDayStreak = advanced.Streak,
                LastPlayDayKey = advanced.DayKey,
            });
            if (streakExtended && advanced.Streak > 1)
                ShowToast(Loc.Or("toastPlayStreak", "Day {days} play streak", ("days", advanced.Streak)));
            if (streakExtended) SyncStreakReminder();

            ReportScore();
            ScheduleSave();
            LogSettlementAnalytics(prev, next, heroTakesPot);
            MaybeAskForReview();
        }

        private void LogSettlementAnalytics(RoundState prev, RoundState next, bool heroTakesPot)
        {
            // Counts and outcomes only — never a name, a group code or a uid.
            _svc.Analytics.LogEvent(AnalyticsEvent.HandPlayed, new Dictionary<string, object>
            {
                ["result"] = next.MessageType.ToString().ToLowerInvariant(),
                ["stake"] = next.Stake?.Key ?? "none",
                ["net"] = next.RoundNet,
                ["swept"] = heroTakesPot ? 1 : 0,
                ["blackjack"] = next.Stats.Blackjacks > prev.Stats.Blackjacks ? 1 : 0,
            });

            var before = prev.Stats.HandsPlayed;
            foreach (var milestone in new[] { 1, 10 })
                if (before < milestone && next.Stats.HandsPlayed >= milestone)
                    _svc.Analytics.LogEvent(milestone == 1 ? AnalyticsEvent.FirstHand : AnalyticsEvent.TenHands);

            if (!State.TutorialDismissed && State.TutorialRoundsSeen == Tutorial.Rounds - 1 && !State.TutorialCompletionLogged)
            {
                Set(s => s with { TutorialCompletionLogged = true });
                ScheduleSave();
                _svc.Analytics.LogEvent(AnalyticsEvent.TutorialComplete);
            }
        }

        /// <summary>Ask at a quiet settlement after enough play. Only an actual attempt starts the cooldown.</summary>
        private void MaybeAskForReview()
        {
            if (_reviewPending || !FlagEnabled(FeatureFlag.ReviewPrompt)) return;
            if (!ReviewPrompt.ShouldPrompt(State.Round.Stats.HandsPlayed, _now(), State.ReviewLastAttemptAtMs,
                    State.ReviewRequestCount, State.ReviewLastRequestSucceeded)) return;

            _reviewPending = true;
            _reviewTimer = After(ReviewPromptDelay, () =>
            {
                if (State.Screen != AppScreen.Table || Round.Phase != RoundPhase.Settlement) { _reviewPending = false; return; }
                Set(s => s with
                {
                    ReviewLastAttemptAtMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
                    ReviewLastRequestSucceeded = false,
                });
                _svc.Store.Save(Snapshot());
                _svc.Analytics.LogEvent(AnalyticsEvent.ReviewPrompted, new Dictionary<string, object> { ["hands"] = State.Round.Stats.HandsPlayed });
                _svc.Review.Request(completed =>
                {
                    _reviewPending = false;
                    Set(s => s with
                    {
                        ReviewPromptShown = s.ReviewPromptShown || completed,
                        ReviewLastRequestSucceeded = completed,
                        ReviewRequestCount = s.ReviewRequestCount + (completed ? 1 : 0),
                    });
                    ScheduleSave();
                    _svc.Analytics.LogEvent(AnalyticsEvent.ReviewRequestResult,
                        new Dictionary<string, object> { ["outcome"] = completed ? "request_completed" : "unavailable_or_failed" });
                });
            });
        }

        // ---- next hand / tutorial / rebuy -----------------------------------------------------------

        public void NextHand()
        {
            // The tutorial advances here rather than at settlement, so the last card of a hand is still the recap.
            var tutorialSeen = Math.Min(State.TutorialRoundsSeen + 1, Tutorial.Rounds);
            var tutorialAdvanced = tutorialSeen != State.TutorialRoundsSeen;

            // Table chat only invents filler once there are real people in the group to talk to.
            var chat = State.ChatMessages.ToList();
            if (State.FriendsAreLive && State.Friends.Count > 0)
            {
                var speaker = State.Friends[_rng.Next(State.Friends.Count)].Name;
                var text = ChatPool[_rng.Next(ChatPool.Length)];
                chat.Add(new ChatMessage(speaker, text, DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()));
            }

            Set(s => s with
            {
                Round = RoundEngine.NextHand(s.Round, _rng),
                ChatMessages = Trim(chat),
                TutorialRoundsSeen = tutorialSeen,
            });
            // Only the first few hands move this, so veterans pay no extra disk write.
            if (tutorialAdvanced) ScheduleSave();
        }

        public static readonly string[] ChatPool = { "Nice hand!", "GG", "So close!", "Let's go!", "Tough beat", "Wow, 21!" };

        public void SkipTutorial()
        {
            if (State.TutorialDismissed) return;
            _svc.Analytics.LogEvent(AnalyticsEvent.TutorialSkipped, new Dictionary<string, object> { ["lesson"] = State.TutorialRoundsSeen + 1 });
            Set(s => s with { TutorialDismissed = true });
            ScheduleSave();
            HapticSelection();
            ShowToast(Loc.Or("toastTutorialOff", "Tutorial off — replay it any time from Settings"));
        }

        public void RestartTutorial()
        {
            Set(s => s with { TutorialRoundsSeen = 0, TutorialDismissed = false });
            ScheduleSave();
            HapticSelection();
            ShowToast(Loc.Or("toastTutorialOn", "Tutorial on — deal a hand to start it"));
        }

        /// <summary>Tops the bankroll back up (never down), gated by a cooldown so running out of chips costs something.</summary>
        public void Rebuy()
        {
            var now = _now();
            if (!Core.Rebuy.IsReady(State.LastRebuyAt, now))
            {
                ShowToast(Loc.Or("toastRebuyIn", "Rebuy available in {time}",
                    ("time", Core.Rebuy.CountdownLabel(State.LastRebuyAt.Value, now))));
                return;
            }
            Set(s => s with
            {
                Round = s.Round with { Chips = Math.Max(s.Round.Chips, Core.Rebuy.Chips) },
                LastRebuyAt = now,
            });
            ScheduleSave();
            ShowToast(Loc.Or("toastRebuyChips", "+{chips} rebuy chips", ("chips", TableCatalog.FormatChips(Core.Rebuy.Chips))));
            PlaySfx(GameSfx.Win);
            HapticMedium();
            _svc.Analytics.LogEvent(AnalyticsEvent.Rebuy);
        }
    }
}
