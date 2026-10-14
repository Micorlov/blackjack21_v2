using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Game;
using Blackjack.Game.Services;
using NUnit.Framework;
using UnityEngine;

namespace Blackjack.Core.Tests
{
    /// <summary>The paced controller, driven by a fake clock so a whole round runs in milliseconds.</summary>
    internal sealed class Rig
    {
        public readonly GameController C;
        public readonly NullSound Sound = new NullSound();
        public readonly MemorySaveStore Store = new MemorySaveStore();
        public readonly NullNotifier Notifier = new NullNotifier();
        public readonly NullAnalytics Analytics = new NullAnalytics();
        public readonly FakeSocial Social = new FakeSocial();
        public double Time;
        public DateTime Now = new DateTime(2026, 8, 10, 14, 0, 0);

        public Rig(int seed = 1, bool boot = false)
        {
            var go = new GameObject("TestController");
            C = go.AddComponent<GameController>();
            C.UseClock(() => Time);
            C.Init(new GameServices
            {
                Sound = Sound, Store = Store, Notifier = Notifier, Analytics = Analytics, Social = Social,
            }, () => Now, new System.Random(seed), boot);
            C.Set(s => s with { Screen = AppScreen.Lobby });
        }

        public RoundState Round => C.State.Round;

        public void Advance(double seconds, double step = 0.05)
        {
            for (var t = 0.0; t < seconds; t += step)
            {
                Time += step;
                C.Tick();
            }
        }

        public bool AdvanceUntil(Func<bool> done, double limit = 60)
        {
            for (var t = 0.0; t < limit && !done(); t += 0.05)
            {
                Time += 0.05;
                C.Tick();
            }
            return done();
        }

        public void Dispose() => UnityEngine.Object.DestroyImmediate(C.gameObject);
    }

    internal sealed class FakeSocial : ISocialService
    {
        public bool Available => true;
        public string Uid { get; set; } = "hero-uid";
        public Action<IReadOnlyList<Friend>> Watcher;
        public readonly List<string> Reports = new List<string>();

        public void EnsureSignedIn(Action<bool> done) => done(true);
        public void FetchMyGroupCode(Action<string> done) => done("ABC234");
        public void IsGroupCreator(string code, Action<bool> done) => done(false);
        public void CreateGroup(string displayName, System.Random rng, Action<string> done) => done("NEW234");
        public void JoinGroup(string code, string displayName, Action<JoinResult> done) => done(JoinResult.Joined);
        public void ReportScore(string code, string name, int chips, int hourly, int daily, string hourKey, string dayKey,
            string tableKey, string appVersion, string platform, string country, int playSeconds) =>
            Reports.Add($"{name}:{chips}:{tableKey}");
        public void AddPlayTime(int seconds) { }
        public void EnsureCreatedAtStamped() { }
        public IDisposable WatchMembers(string code, Action<IReadOnlyList<Friend>> onUpdate) { Watcher = onUpdate; return new Stop(); }
        public void SignInWithGoogle(Action<GoogleProfile, string> done) => done(new GoogleProfile("Maya Test", null), null);
        public void SignOut(Action done) => done();
        public void LoadFeatureFlags(Action<IReadOnlyDictionary<string, bool>> done) => done(new Dictionary<string, bool>());
        public GoogleProfile RestoredProfile() => null;
        private sealed class Stop : IDisposable { public void Dispose() { } }
    }

    public class ControllerRoundTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        [Test]
        public void ANaturalPlaysTheTableOutAndTakesTheSweepPotThroughThePacedTurns()
        {
            _rig = new Rig(seed: 3);
            var c = _rig.C;
            c.EnterTable(T.Bronze);
            // Deal order: four seats x2, the hero's pair, the dealer's pair, then seat one's hit card.
            c.UseShoe(T.Stacked("10", "6", "10", "8", "10", "8", "10", "8", "A", "K", "10", "7", "K"));
            var forfeited = _rig.Round.NpcSeats[0].Bet;
            var chipsBefore = _rig.Round.Chips;

            c.PlaceBet(100);
            c.DealRound();
            Assert.AreEqual(RoundPhase.Npcs, _rig.Round.Phase, "a natural does not end the round");

            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement));
            var r = _rig.Round;
            Assert.AreEqual(forfeited, r.SweepAmount);
            Assert.IsTrue(r.SweepInfo.HeroTook);
            Assert.AreEqual("Blackjack — you sweep", r.Message);
            Assert.AreEqual(chipsBefore + 150 + forfeited, r.Chips);

            _rig.Advance(4);
            CollectionAssert.Contains(_rig.Sound.Tones, GameSfx.Blackjack);
            CollectionAssert.Contains(_rig.Sound.Voices, GameVoice.PlayerBlackjackPot);
        }

        [Test]
        public void TheDealerRevealsAndDrawsOnItsOwnBeat_notAllAtOnce()
        {
            _rig = new Rig(seed: 4);
            var c = _rig.C;
            c.EnterTable(T.Bronze);
            // Hero 10+6, dealer 5+6 must draw; seats all stand on 18.
            c.UseShoe(T.Stacked("10", "8", "10", "8", "10", "8", "10", "8", "10", "6", "5", "6", "4", "10"));
            c.PlaceBet(100);
            c.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));

            c.PlayerStand();
            Assert.AreEqual(RoundPhase.NpcsAfter, _rig.Round.Phase, "the seats on the hero's left play before the dealer");
            Assert.IsFalse(_rig.Round.HoleRevealed);
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Dealer));
            Assert.IsTrue(_rig.Round.HoleRevealed);
            Assert.AreEqual(2, _rig.Round.DealerHand.Count, "no card is drawn on the reveal beat");

            _rig.Advance(1.0);
            Assert.AreEqual(2, _rig.Round.DealerHand.Count, "the reveal floor is two seconds");
            _rig.Advance(1.5);
            Assert.AreEqual(3, _rig.Round.DealerHand.Count, "one draw per beat");
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement));
            Assert.AreEqual(1, _rig.Round.Stats.HandsPlayed);
        }

        [Test]
        public void RandomRoundsAlwaysSettleAndConserveChips()
        {
            for (var seed = 0; seed < 25; seed++)
            {
                _rig = new Rig(seed);
                var c = _rig.C;
                c.EnterTable(T.Bronze);
                for (var hand = 0; hand < 4; hand++)
                {
                    var before = _rig.Round.Chips;
                    c.PlaceBet(100);
                    c.DealRound();
                    if (_rig.Round.Phase == RoundPhase.Insurance) c.DeclineInsurance();
                    Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase is RoundPhase.Playing or RoundPhase.Settlement), $"seed {seed}");
                    while (_rig.Round.Phase == RoundPhase.Playing)
                    {
                        if (BlackjackRules.HandValue(_rig.Round.ActiveHand.Cards) >= 17) c.PlayerStand(); else c.PlayerHit();
                    }
                    Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement), $"seed {seed}");
                    Assert.AreEqual(before + _rig.Round.RoundNet, _rig.Round.Chips, $"seed {seed} hand {hand}");
                    c.NextHand();
                }
                _rig.Dispose();
            }
            _rig = null;
        }

        [Test]
        public void SettlementPublishesTheScoreAndSavesTheGame()
        {
            _rig = new Rig(seed: 5);
            _rig.C.Set(s => s with { SocialReady = true });
            _rig.C.EnterTable(T.Bronze);
            _rig.C.UseShoe(T.Stacked("10", "8", "10", "8", "10", "8", "10", "8", "10", "9", "10", "7"));
            _rig.C.PlaceBet(100);
            _rig.C.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            _rig.C.PlayerStand();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement));
            _rig.Advance(2);

            Assert.AreEqual(1, _rig.C.State.PlayDayStreak);
            Assert.IsNotNull(_rig.Store.Saved);
            Assert.AreEqual(_rig.Round.Chips, _rig.Store.Saved.Chips);
            Assert.AreEqual(1, _rig.Store.Saved.Stats.HandsPlayed);
            CollectionAssert.Contains(_rig.Analytics.Events, AnalyticsEvent.HandPlayed);
            CollectionAssert.Contains(_rig.Analytics.Events, AnalyticsEvent.FirstHand);
            StringAssert.Contains(":bronze", _rig.Social.Reports.Last());
        }

        [Test]
        public void ExitingMidDealerTurnStillSettlesTheHand()
        {
            _rig = new Rig(seed: 6);
            _rig.C.EnterTable(T.Bronze);
            _rig.C.UseShoe(T.Stacked("10", "8", "10", "8", "10", "8", "10", "8", "10", "6", "5", "6", "4", "10"));
            _rig.C.PlaceBet(100);
            _rig.C.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            _rig.C.PlayerStand();
            _rig.C.ExitTable();
            _rig.Advance(3);
            Assert.AreEqual(RoundPhase.Settlement, _rig.Round.Phase, "a bet is never stranded");
            Assert.IsTrue(_rig.Round.NpcSeats.All(n => n.Done), "the seats after the hero still played");
        }

        [Test]
        public void ExitingMidDealerTurnSettlesToo()
        {
            _rig = new Rig(seed: 6);
            _rig.C.EnterTable(T.Bronze);
            _rig.C.UseShoe(T.Stacked("10", "8", "10", "8", "10", "8", "10", "8", "10", "6", "5", "6", "4", "10"));
            _rig.C.PlaceBet(100);
            _rig.C.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            _rig.C.PlayerStand();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Dealer));
            _rig.C.ExitTable();
            _rig.Advance(3);
            Assert.AreEqual(RoundPhase.Settlement, _rig.Round.Phase);
        }
    }

    public class ControllerMetaTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        [Test]
        public void DailyBonus_paysOncePerCooldown_andSchedulesTheNextReminder()
        {
            _rig = new Rig();
            var chips = _rig.Round.Chips;
            _rig.C.ClaimDailyBonus();
            Assert.AreEqual(chips + 250, _rig.Round.Chips);
            Assert.AreEqual(1, _rig.C.State.DailyBonusStreakDay);
            Assert.AreEqual(_rig.Now, _rig.Store.LastClaim);
            Assert.IsNotNull(_rig.Notifier.DailyAfter);
            Assert.AreEqual(TimeSpan.FromHours(24), _rig.Notifier.DailyAfter.Value);

            _rig.C.ClaimDailyBonus();
            Assert.AreEqual(chips + 250, _rig.Round.Chips, "still cooling down");

            _rig.Now = _rig.Now.AddHours(25);
            _rig.C.ClaimDailyBonus();
            Assert.AreEqual(2, _rig.C.State.DailyBonusStreakDay);
        }

        [Test]
        public void DailyBonus_addsThePlayStreakBonus()
        {
            _rig = new Rig();
            _rig.C.Set(s => s with { PlayDayStreak = 3, LastPlayDayKey = Points.DayKeyOf(_rig.Now) });
            var chips = _rig.Round.Chips;
            _rig.C.ClaimDailyBonus();
            Assert.AreEqual(chips + 250 + 150, _rig.Round.Chips);
        }

        [Test]
        public void Rebuy_topsUpOnceThenCoolsDown()
        {
            _rig = new Rig();
            _rig.C.Set(s => s with { Round = s.Round with { Chips = 10 } });
            _rig.C.Rebuy();
            Assert.AreEqual(1000, _rig.Round.Chips);
            _rig.C.Set(s => s with { Round = s.Round with { Chips = 10 } });
            _rig.C.Rebuy();
            Assert.AreEqual(10, _rig.Round.Chips, "cooldown");
            StringAssert.Contains("4h", _rig.C.State.Toast);
            _rig.Now = _rig.Now.AddHours(4);
            _rig.C.Rebuy();
            Assert.AreEqual(1000, _rig.Round.Chips);
        }

        [Test]
        public void Rebuy_neverReducesAStackAboveTheTopUp()
        {
            _rig = new Rig();
            _rig.C.Set(s => s with { Round = s.Round with { Chips = 5000 } });
            _rig.C.Rebuy();
            Assert.AreEqual(5000, _rig.Round.Chips);
        }

        [Test]
        public void Boot_restoresTheSavedPlayerAndSkipsTheGate()
        {
            var store = new MemorySaveStore
            {
                Saved = new SavedGame
                {
                    Chips = 4321, OnboardingDone = true, SoundOn = false, TutorialRoundsSeen = 2,
                    Stats = new StatsSummary(HandsPlayed: 7, Wins: 4),
                    HourKey = "stale", HourlyPoints = 99,
                },
            };
            var go = new GameObject("Boot");
            var c = go.AddComponent<GameController>();
            c.Init(new GameServices { Store = store }, () => new DateTime(2026, 8, 10, 14, 0, 0), new System.Random(1));
            Assert.AreEqual(4321, c.State.Chips);
            Assert.AreEqual(AppScreen.Lobby, c.State.Screen);
            Assert.IsFalse(c.State.SoundOn);
            Assert.AreEqual(7, c.State.Round.Stats.HandsPlayed);
            Assert.AreEqual(0, c.State.HeroHourlyPoints, "a stale hour's points are worth nothing");
            UnityEngine.Object.DestroyImmediate(go);
        }

        [Test]
        public void Boot_withNoSaveStartsAtTheOnboardingGate()
        {
            var go = new GameObject("Fresh");
            var c = go.AddComponent<GameController>();
            c.Init(new GameServices(), null, new System.Random(1));
            Assert.AreEqual(AppScreen.Onboarding, c.State.Screen);
            Assert.AreEqual(1000, c.State.Chips);
            UnityEngine.Object.DestroyImmediate(go);
        }

        [Test]
        public void PlayNow_opensTheCoachedBronzeTableWithoutBetting()
        {
            _rig = new Rig();
            _rig.C.Set(s => s with { Screen = AppScreen.Onboarding });
            _rig.C.PlayNow();
            Assert.AreEqual(AppScreen.Table, _rig.C.State.Screen);
            Assert.AreEqual("bronze", _rig.Round.Stake.Key);
            Assert.AreEqual(0, _rig.Round.Bet);
            CollectionAssert.Contains(_rig.Analytics.Events, AnalyticsEvent.OnboardingComplete);
        }

        [Test]
        public void TablePlay_neverAcceptsABetBeyondTheTableMaximum()
        {
            _rig = new Rig();
            _rig.C.EnterTable(T.Bronze);
            _rig.C.BetAllIn();
            Assert.AreEqual(500, _rig.Round.Bet);
            _rig.C.PlaceBet(25);
            Assert.AreEqual(500, _rig.Round.Bet);
            StringAssert.Contains("500", _rig.C.State.Toast);
        }

        [Test]
        public void SoundToggle_silencesPendingVoiceAndIsSaved()
        {
            _rig = new Rig();
            _rig.C.ToggleSound();
            Assert.IsFalse(_rig.C.State.SoundOn);
            _rig.Advance(1);
            Assert.IsNotNull(_rig.Store.Saved);
            Assert.IsFalse(_rig.Store.Saved.SoundOn);
        }

        [Test]
        public void ReferralReward_paysTheInviterOnceForEachJoinedFriend()
        {
            _rig = new Rig();
            _rig.C.Init(new GameServices { Sound = _rig.Sound, Store = _rig.Store, Notifier = _rig.Notifier, Analytics = _rig.Analytics, Social = _rig.Social },
                () => _rig.Now, new System.Random(1), boot: true);
            Assert.IsNotNull(_rig.Social.Watcher, "subscribed to the group");
            var chips = _rig.Round.Chips;
            var friend = new Friend("u2", "Maya T.", 1000, true, 0, 0, InvitedBy: "hero-uid");

            // Paid on the very first snapshot too: a friend who joined while this device was offline is still credited.
            _rig.Social.Watcher(new[] { friend });
            Assert.AreEqual(chips + 100, _rig.Round.Chips);
            Assert.AreEqual(1, _rig.C.State.ReferralsCount);
            Assert.IsEmpty(_rig.Notifier.Shown, "no notification for the baseline snapshot");
            _rig.Social.Watcher(new[] { friend });
            Assert.AreEqual(chips + 100, _rig.Round.Chips, "paid exactly once");
        }

        [Test]
        public void HandleBack_walksBackOneScreenAtATime()
        {
            _rig = new Rig();
            _rig.C.GoSettings();
            Assert.IsTrue(_rig.C.HandleBack());
            Assert.AreEqual(AppScreen.Lobby, _rig.C.State.Screen);
            Assert.IsFalse(_rig.C.HandleBack(), "the lobby leaves the app");
        }
    }

    public class SavedGameJsonTests
    {
        [Test]
        public void RoundTrips()
        {
            var game = new SavedGame
            {
                Chips = 777, OnboardingDone = true, LanguageOverride = "he", AvatarColor = unchecked((int)0xFFB23A2E),
                Stats = new StatsSummary(12, 7, 4, 1, 2, 3, 5),
                History = new[] { RoundResult.Win, RoundResult.Loss, RoundResult.Push },
                RewardedReferralIds = new[] { "a", "b" }, LastRebuyAtMs = 1700000000000, PlayDayStreak = 4,
                TurnTimerOn = false,
            };
            var back = Blackjack.Game.Services.SavedGameJson.FromJson(Blackjack.Game.Services.SavedGameJson.ToJson(game));
            Assert.AreEqual(777, back.Chips);
            Assert.AreEqual("he", back.LanguageOverride);
            Assert.AreEqual(game.AvatarColor, back.AvatarColor);
            Assert.AreEqual(game.Stats, back.Stats);
            CollectionAssert.AreEqual(game.History, back.History);
            CollectionAssert.AreEqual(new[] { "a", "b" }, back.RewardedReferralIds.ToArray());
            Assert.AreEqual(1700000000000, back.LastRebuyAtMs);
            Assert.IsFalse(back.TurnTimerOn);
        }

        [Test]
        public void IsTolerantOfMissingAndMistypedFields()
        {
            var back = Blackjack.Game.Services.SavedGameJson.FromJson("{\"v\":1,\"chips\":\"lots\",\"stats\":{\"handsPlayed\":5},\"soundOn\":3}");
            Assert.AreEqual(1000, back.Chips);
            Assert.IsTrue(back.SoundOn);
            Assert.AreEqual(3, back.TutorialRoundsSeen, "hands played stands in, capped at the lesson count");
            Assert.IsTrue(back.OnboardingDone, "an old blob belongs to someone who got past the gate");
            Assert.IsTrue(back.TurnTimerOn, "a save from before the turn timer gets it switched on");
        }

        [Test]
        public void RejectsOtherSchemaVersionsAndGarbage()
        {
            Assert.IsNull(Blackjack.Game.Services.SavedGameJson.FromJson("{\"v\":2}"));
            Assert.IsNull(Blackjack.Game.Services.SavedGameJson.FromJson("not json"));
        }
    }

    /// <summary>The 20-second casino turn clock: auto-stand, pauses, a fresh clock per split hand, and when it is off.</summary>
    public class TurnTimerTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        private void DealToTheHero(params string[] heroAndDealerAndDraws)
        {
            _rig = new Rig(seed: 7);
            var c = _rig.C;
            c.Set(s => s with { TutorialDismissed = true });
            c.EnterTable(T.Bronze);
            // Four seats on 18 (they all stand), then the hero's pair, the dealer's pair and any later draws.
            c.UseShoe(T.Stacked(new[] { "10", "8", "10", "8", "10", "8", "10", "8" }.Concat(heroAndDealerAndDraws).ToArray()));
            c.PlaceBet(100);
            c.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            _rig.Advance(0.05);
        }

        [Test]
        public void TheHandStandsByItselfAfterTwentySeconds()
        {
            DealToTheHero("10", "6", "10", "7");
            Assert.IsNotNull(_rig.Round.TurnDeadline);
            _rig.Advance(GameController.TurnSeconds - 1);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase, "not before the twenty seconds are up");

            _rig.Advance(1.5);
            Assert.AreEqual(HandStatus.Stood, _rig.Round.Hands[0].Status);
            Assert.AreEqual(RoundPhase.NpcsAfter, _rig.Round.Phase);
            Assert.IsNull(_rig.Round.TurnDeadline, "no clock outside the hero's turn");
            StringAssert.Contains("you stand", _rig.C.State.Toast);
        }

        [Test]
        public void HittingDoesNotRestartTheClock()
        {
            DealToTheHero("5", "4", "10", "7", "2");
            var deadline = _rig.Round.TurnDeadline;
            _rig.Advance(5);
            _rig.C.PlayerHit();
            _rig.Advance(0.05);
            Assert.AreEqual(deadline, _rig.Round.TurnDeadline);
        }

        [Test]
        public void TheClockPausesWhileTheChatIsOpen_andResumesWhereItWas()
        {
            DealToTheHero("10", "6", "10", "7");
            _rig.Advance(10);
            _rig.C.ToggleTableChat();
            _rig.Advance(60);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase, "a paused clock never fires");
            Assert.AreEqual(10f, _rig.C.TurnSecondsPaused ?? 0f, 0.2f);

            _rig.C.ToggleTableChat();
            _rig.Advance(9);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase);
            _rig.Advance(1.5);
            Assert.AreEqual(HandStatus.Stood, _rig.Round.Hands[0].Status);
        }

        [Test]
        public void TheClockPausesInTheBackground()
        {
            DealToTheHero("10", "6", "10", "7");
            _rig.C.OnAppPaused();
            _rig.Advance(60);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase);
            _rig.C.OnAppResumed();
            _rig.Advance(GameController.TurnSeconds + 1);
            Assert.AreEqual(HandStatus.Stood, _rig.Round.Hands[0].Status);
        }

        [Test]
        public void TheBackgroundPauseHoldsEvenWhenNoFrameRunsWhileAway()
        {
            // A phone stops calling Update in the background: the clock moves on without a single tick.
            DealToTheHero("10", "6", "10", "7");
            _rig.Advance(5);
            _rig.C.OnAppPaused();
            _rig.Time += 60;
            _rig.C.OnAppResumed();
            _rig.Advance(0.1);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase, "coming back must not find the hand stood");
            Assert.Greater(_rig.C.TurnSecondsLeft ?? 0f, 14f);
        }

        [Test]
        public void EachSplitHandGetsItsOwnClock()
        {
            DealToTheHero("8", "8", "10", "7", "3", "2");
            _rig.Advance(15);
            _rig.C.PlayerSplit();
            _rig.Advance(GameController.TurnSeconds - 1);
            Assert.AreEqual(0, _rig.Round.ActiveHandIndex, "the split restarted the clock");

            _rig.Advance(1.5);
            Assert.AreEqual(HandStatus.Stood, _rig.Round.Hands[0].Status);
            Assert.AreEqual(1, _rig.Round.ActiveHandIndex);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase);
            Assert.Greater(_rig.C.TurnSecondsLeft ?? 0f, GameController.TurnSeconds - 1, "the second hand starts a full clock");
        }

        [Test]
        public void TheClockIsOffWhenSwitchedOff_andOnTutorialHands()
        {
            DealToTheHero("10", "6", "10", "7");
            _rig.C.ToggleTurnTimer();
            _rig.Advance(60);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase);
            Assert.IsNull(_rig.Round.TurnDeadline);
            _rig.Dispose();

            _rig = new Rig(seed: 7);
            Assert.IsTrue(_rig.C.State.TurnTimerOn, "on by default");
            _rig.C.Set(s => s with { Screen = AppScreen.Table, TutorialRoundsSeen = 0, TutorialDismissed = false,
                Round = T.Playing(hero: new[] { "10", "6" }) });
            _rig.Advance(60);
            Assert.AreEqual(RoundPhase.Playing, _rig.Round.Phase, "a coached hand has no clock");
        }

        [Test]
        public void TheSettingIsSaved()
        {
            DealToTheHero("10", "6", "10", "7");
            _rig.C.ToggleTurnTimer();
            _rig.Advance(1);
            Assert.IsFalse(_rig.Store.Saved.TurnTimerOn);
        }
    }

    public class CardFanTests
    {
        [Test]
        public void ANewCardSizeRebuildsTheWholeFan()
        {
            // A split keeps the first card but deals both hands at a smaller size: no card may stay at the old one.
            // (The fan frees old cards with Destroy, which edit mode reports but the test does not depend on.)
            UnityEngine.TestTools.LogAssert.ignoreFailingMessages = true;
            var host = new GameObject("Fan", typeof(RectTransform));
            try
            {
                var fan = new Blackjack.Game.UI.CardFan((RectTransform)host.transform);
                var pair = new[] { T.C("8"), T.C("8", "♥") };
                fan.Sync(pair, 88f, 128f, (card, i, n) => { });
                fan.Sync(new[] { pair[0], T.C("3", "♦") }, 66f, 96f, (card, i, n) => { });
                Assert.AreEqual(2, fan.Count);
                foreach (var card in fan.Cards) Assert.AreEqual(new Vector2(66f, 96f), card.sizeDelta);
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(host);
            }
        }
    }
}
