using System;
using System.Linq;
using Blackjack.Game.Services;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    /// <summary>The trio (hero + 2) and heads-up (hero vs the dealer, no sweep pot) rooms, and the classic ladder staying as it was.</summary>
    public class RoomCatalogTests
    {
        private static TableStake Room(string key) => TableCatalog.ByKey(key);

        [Test]
        public void TheClassicLadderIsUnchanged_andStillFirstInTheLobby()
        {
            CollectionAssert.AreEqual(new[] { "bronze", "silver", "vip" }, TableCatalog.Tables.Take(3).Select(t => t.Key));
            Assert.AreEqual((25, 500), (Room("bronze").Min, Room("bronze").Max));
            Assert.AreEqual((100, 1000), (Room("silver").Min, Room("silver").Max));
            Assert.AreEqual((500, 5000), (Room("vip").Min, Room("vip").Max));
            foreach (var key in new[] { "bronze", "silver", "vip" })
            {
                Assert.AreEqual(4, Room(key).Opponents, key + " keeps four opponents (5 seats with the hero)");
                Assert.IsTrue(Room(key).SweepPot, key + " keeps its sweep pot");
                Assert.IsTrue(TableCatalog.IsClassic(Room(key)));
            }
        }

        [Test]
        public void TheNewRoomsAreListedWithTheirStakes()
        {
            CollectionAssert.AreEqual(new[] { "bronze", "silver", "vip", "trio", "headsup" }, TableCatalog.Tables.Select(t => t.Key));
            var trio = Room("trio");
            Assert.AreEqual((50, 1000, 2, true), (trio.Min, trio.Max, trio.Opponents, trio.SweepPot));
            var duel = Room("headsup");
            Assert.AreEqual((100, 2000, 0, false), (duel.Min, duel.Max, duel.Opponents, duel.SweepPot));
            Assert.IsFalse(TableCatalog.IsClassic(trio));
            Assert.IsFalse(TableCatalog.IsClassic(duel));
            Assert.IsNull(TableCatalog.ByKey("nope"));
        }

        [Test]
        public void EveryStakeKeyIsUnique_andChipsFitEachRoom()
        {
            Assert.AreEqual(TableCatalog.Tables.Length, TableCatalog.Tables.Select(t => t.Key).Distinct().Count());
            foreach (var t in TableCatalog.Tables)
            {
                Assert.Greater(t.Max, t.Min, t.Key);
                Assert.IsNotEmpty(TableCatalog.ChipDenomsFor(t), t.Key);
            }
        }

        [Test]
        public void TheLobbyRecommendation_stillWalksOnlyTheClassicLadder()
        {
            Assert.AreEqual("bronze", TableRecommendation.For(50).Key);
            Assert.AreEqual("bronze", TableRecommendation.For(200).Key, "the trio room must not be recommended over bronze");
            Assert.AreEqual("silver", TableRecommendation.For(400).Key);
            Assert.AreEqual("silver", TableRecommendation.For(1000).Key);
            Assert.AreEqual("vip", TableRecommendation.For(2000).Key);
            Assert.AreEqual("vip", TableRecommendation.For(1_000_000).Key);
        }

        [Test]
        public void OpponentsFor_defaultsToTheClassicCount()
        {
            Assert.AreEqual(4, TableCatalog.OpponentsFor(null));
            Assert.AreEqual(4, TableCatalog.OpponentsFor("unknown"));
            Assert.AreEqual(2, TableCatalog.OpponentsFor("trio"));
            Assert.AreEqual(0, TableCatalog.OpponentsFor("headsup"));
        }

        [Test]
        public void RosterSeatsAsManyOpponentsAsTheRoomHas()
        {
            var friends = Enumerable.Range(0, 6).Select(i => new Friend("u" + i, "F" + i, 0, true, 0, 0)).ToArray();
            Assert.AreEqual(4, Roster.TableSeats(friends, "bronze").Count);
            Assert.AreEqual(4, Roster.TableSeats(Array.Empty<Friend>(), "vip").Count, "practice bots pad a classic room");
            Assert.AreEqual(2, Roster.TableSeats(friends, "trio").Count);
            Assert.AreEqual(2, Roster.TableSeats(Array.Empty<Friend>(), "trio").Count);
            Assert.AreEqual(0, Roster.TableSeats(friends, "headsup").Count);
        }
    }

    public class RoomRoundTests
    {
        private static readonly Random Rng = new Random(7);
        private static readonly TableStake Trio = TableCatalog.ByKey("trio");
        private static readonly TableStake Duel = TableCatalog.ByKey("headsup");

        [Test]
        public void EnteringARoomRollsOnlyItsSeats()
        {
            Assert.AreEqual(4, RoundEngine.EnterTable(new RoundState(), T.Bronze, Rng).NpcSeats.Count);
            Assert.AreEqual(4, RoundEngine.EnterTable(new RoundState(), T.Vip, Rng).NpcSeats.Count);
            Assert.AreEqual(2, RoundEngine.EnterTable(new RoundState(), Trio, Rng).NpcSeats.Count);
            Assert.AreEqual(0, RoundEngine.EnterTable(new RoundState(), Duel, Rng).NpcSeats.Count);
            // The next hand keeps the room's seats.
            Assert.AreEqual(2, RoundEngine.NextHand(RoundEngine.EnterTable(new RoundState(), Trio, Rng), Rng).NpcSeats.Count);
            Assert.AreEqual(4, RoundEngine.RollNpcSeats(25, Rng).Count, "the default is still the classic table");
        }

        [Test]
        public void ClassicRoomsStillSeatFourAndKeepTheirRng()
        {
            // Rolling the classic table consumes the RNG exactly as before: one draw per seat.
            var a = RoundEngine.RollNpcSeats(25, new Random(5)).Select(n => n.Bet).ToArray();
            var b = RoundEngine.EnterTable(new RoundState(), T.Bronze, new Random(5)).NpcSeats.Select(n => n.Bet).ToArray();
            CollectionAssert.AreEqual(a, b);
        }

        // ---- heads-up -----------------------------------------------------------------------------

        private static RoundState DuelDeal(Shoe shoe, int bet = 100) =>
            RoundEngine.Deal(RoundEngine.PlaceBet(RoundEngine.EnterTable(new RoundState(), Duel, Rng), bet).State, shoe, Array.Empty<string>());

        [Test]
        public void HeadsUp_dealsOnlyTheHeroAndTheDealer_andTheHeroActsFirstAndOnly()
        {
            var s = DuelDeal(T.Stacked("10", "6", "10", "8"));
            Assert.AreEqual(0, s.NpcSeats.Count);
            Assert.AreEqual(RoundPhase.Playing, s.Phase, "nobody sits ahead of the hero");
            Assert.IsNull(s.ActingSeat);
            Assert.AreEqual(1, s.Hands.Count);
            Assert.AreEqual(2, s.Hands[0].Cards.Count);
            Assert.AreEqual(2, s.DealerHand.Count);

            s = RoundEngine.Stand(s);
            Assert.AreEqual(RoundPhase.Dealer, s.Phase, "the dealer follows the hero");
        }

        [Test]
        public void HeadsUp_settlesWithoutAPot()
        {
            var shoe = T.Stacked("10", "9", "10", "7");
            var s = RoundEngine.Stand(DuelDeal(shoe));
            var settled = RoundEngine.RunToSettlement(s, shoe, Array.Empty<string>());
            Assert.AreEqual(RoundPhase.Settlement, settled.Phase);
            Assert.AreEqual("You win!", settled.Message);
            Assert.IsNull(settled.SweepInfo);
            Assert.AreEqual(0, settled.SweepAmount);
            Assert.AreEqual(100, settled.RoundNet, "an even-money win, nothing pooled");
            Assert.AreEqual(1000 + 100, settled.Chips);
            Assert.AreEqual(settled.RoundNet, settled.RoundHandNet);
        }

        [Test]
        public void HeadsUp_aDealerNaturalSettlesAtOnce_andAnInsuranceOfferStillWorks()
        {
            var natural = DuelDeal(T.Stacked("10", "9", "A", "K"));
            Assert.AreEqual(RoundPhase.Insurance, natural.Phase, "an ace shows: insurance is offered with no seats around");
            var declined = RoundEngine.DeclineInsurance(natural, Array.Empty<string>());
            Assert.AreEqual(RoundPhase.Settlement, declined.Phase);
            Assert.IsNull(declined.SweepInfo);

            var open = DuelDeal(T.Stacked("10", "9", "A", "6"));
            var played = RoundEngine.DeclineInsurance(open, Array.Empty<string>());
            Assert.AreEqual(RoundPhase.Playing, played.Phase, "no seats to wait for after the insurance decision");
        }

        [Test]
        public void HeadsUp_aNaturalGoesStraightToTheDealer()
        {
            var shoe = T.Stacked("A", "K", "10", "7");
            var s = DuelDeal(shoe);
            Assert.AreEqual(RoundPhase.Dealer, s.Phase);
            var settled = RoundEngine.RunToSettlement(s, shoe, Array.Empty<string>());
            Assert.AreEqual("Blackjack! You win", settled.Message);
            Assert.AreEqual(150, settled.RoundNet);
        }

        [Test]
        public void HeadsUp_neverPoolsAPot_evenIfSeatsAreForcedIn()
        {
            // A heads-up state that somehow carries seat bets: the room says no pot, so there is nothing to sweep or to quote.
            var forced = new RoundState
            {
                Chips = 900, Stake = Duel, Bet = 100, Phase = RoundPhase.Dealer, HoleRevealed = true,
                DealerHand = T.Cards("10", "7"),
                Hands = new[] { new Hand(T.Cards("10", "9"), 100, HandStatus.Stood) },
                NpcSeats = new[] { new NpcSeat(100, T.Cards("10", "9", "5")) },
            };
            Assert.AreEqual(0, TablePot.Live(forced).Amount);
            Assert.IsFalse(TablePot.Live(forced).IsSweep);
            var settled = Settlement.Settle(forced, new[] { "Maya" });
            Assert.IsNull(settled.SweepInfo);
            Assert.AreEqual(0, settled.SweepAmount);
        }

        // ---- trio -----------------------------------------------------------------------------------

        private static RoundState TrioDeal(Shoe shoe, int bet = 100) =>
            RoundEngine.Deal(RoundEngine.PlaceBet(RoundEngine.EnterTable(new RoundState(), Trio, Rng), bet).State, shoe, new[] { "Maya", "Jordan" });

        [Test]
        public void Trio_seatsTheHeroAndTwoOpponents_theHeroActsAfterBothAndBeforeTheDealer()
        {
            var shoe = T.Stacked("10", "6", "10", "8", "10", "7", "10", "7", "K");
            var s = TrioDeal(shoe);
            Assert.AreEqual(2, s.NpcSeats.Count);
            Assert.AreEqual(RoundPhase.Npcs, s.Phase, "the seats play first");
            CollectionAssert.AreEqual(new[] { 0, 1 }, RoundEngine.SeatsActingIn(RoundPhase.Npcs, s.NpcSeats.Count));
            Assert.IsEmpty(RoundEngine.SeatsActingIn(RoundPhase.NpcsAfter, s.NpcSeats.Count));

            s = RoundEngine.PlaySeats(s, shoe, RoundPhase.Npcs);
            Assert.IsTrue(s.NpcSeats.All(n => n.Done), "both opponents have played");
            s = RoundEngine.HandOverAfterSeats(s);
            Assert.AreEqual(RoundPhase.Playing, s.Phase, "now the hero");
            s = RoundEngine.Stand(s);
            Assert.AreEqual(RoundPhase.Dealer, s.Phase, "then the dealer");
        }

        [Test]
        public void Trio_aBustSeatFeedsThePot_andTheHeroSweepsIt()
        {
            var shoe = T.Stacked("10", "6", "10", "8", "10", "K", "10", "7", "K");
            var s = TrioDeal(shoe);
            var forfeited = s.NpcSeats[0].Bet;
            s = RoundEngine.HandOverAfterSeats(RoundEngine.PlaySeats(s, shoe, RoundPhase.Npcs));
            Assert.AreEqual("BUST", s.NpcSeats[0].Action);
            Assert.AreEqual(forfeited, TablePot.Live(s).Amount, "the pot is live in the trio room");

            var settled = RoundEngine.RunToSettlement(RoundEngine.Stand(s), shoe, new[] { "Maya", "Jordan" });
            Assert.IsTrue(settled.SweepInfo.HeroTook);
            Assert.AreEqual(forfeited, settled.SweepAmount);
            Assert.AreEqual("You sweep the table", settled.Message);
            Assert.IsTrue(ReviewPrompt.IsBigWin(new RoundState(), settled), "a sweep in the trio room can ask for a review");
        }

        // ---- layout -----------------------------------------------------------------------------------

        [Test]
        public void TheFeltSeatsAreBalanced_forTwoOpponents_andUnchangedForFour()
        {
            var m = FeltMetrics.For(412, 700);
            Assert.AreEqual(new[] { 0, 1, 2, 3 }, Enumerable.Range(0, 4).Select(i => FeltMetrics.CurveIndex(i, 4)));
            var a = m.SeatSlot(0, 2);
            var b = m.SeatSlot(1, 2);
            Assert.AreEqual(1, a.Side);
            Assert.AreEqual(-1, b.Side);
            Assert.AreEqual(a.Y, b.Y, 0.001f, "level with each other");
            Assert.AreEqual(m.CentreX, (a.X + b.X) / 2f, 0.001f, "centred about the hero");
            Assert.AreEqual(m.SeatSlot(0).X, a.X, 0.001f);
            Assert.AreEqual(m.SeatSlot(3).X, b.X, 0.001f);
            Assert.AreEqual(m.SeatSlot(2).X, m.SeatSlot(2, 4).X, 0.001f);
        }
    }

    /// <summary>The hooks that hang off a settled hand keep working with no pot (heads-up) and with only two opponents (trio).</summary>
    public class RoomControllerTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        [Test]
        public void HeadsUp_aBlackjackSettlesThroughTheController_withNoPot()
        {
            _rig = new Rig(seed: 3);
            var c = _rig.C;
            c.EnterTable(TableCatalog.ByKey("headsup"));
            c.UseShoe(T.Stacked("A", "K", "10", "7"));
            c.PlaceBet(100);
            c.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement));
            var r = _rig.Round;
            Assert.IsNull(r.SweepInfo);
            Assert.AreEqual(150, r.RoundNet);
            Assert.AreEqual(1, r.Stats.Blackjacks);
            Assert.IsTrue(ReviewPrompt.IsBigWin(new RoundState(), r), "a natural is still a big win with no pot");
            _rig.Advance(4);
            CollectionAssert.Contains(_rig.Sound.Tones, GameSfx.Blackjack);
            CollectionAssert.DoesNotContain(_rig.Sound.Voices, GameVoice.PlayerBlackjackPot);
            c.NextHand();
            Assert.AreEqual(0, _rig.Round.NpcSeats.Count);
        }

        [Test]
        public void HeadsUp_theTurnAnnouncementCallsNoPot()
        {
            _rig = new Rig(seed: 3);
            var c = _rig.C;
            c.EnterTable(TableCatalog.ByKey("headsup"));
            c.UseShoe(T.Stacked("10", "6", "10", "7"));
            c.PlaceBet(100);
            c.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            _rig.Advance(4);
            Assert.IsFalse(_rig.Sound.Spoken.Any(w => w.Contains("pot")), "no sweep pot is spoken in heads-up");
        }

        [Test]
        public void Trio_aSweepRunsThroughThePacedTurns_andPublishesTheScore()
        {
            _rig = new Rig(seed: 3);
            _rig.C.Set(s => s with { SocialReady = true });
            var c = _rig.C;
            c.EnterTable(TableCatalog.ByKey("trio"));
            c.UseShoe(T.Stacked("10", "6", "10", "8", "10", "K", "10", "7", "K"));
            var forfeited = _rig.Round.NpcSeats[0].Bet;
            c.PlaceBet(100);
            c.DealRound();
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Playing));
            Assert.IsTrue(_rig.Round.NpcSeats.All(n => n.Done), "the hero is asked only after both opponents");
            c.PlayerStand();
            Assert.AreEqual(RoundPhase.Dealer, _rig.Round.Phase);
            Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement));
            Assert.IsTrue(_rig.Round.SweepInfo.HeroTook);
            Assert.AreEqual(forfeited, _rig.Round.SweepAmount);
            _rig.Advance(2);
            Assert.IsNotNull(_rig.Store.Saved);
            CollectionAssert.Contains(_rig.Sound.Voices, GameVoice.PlayerPot);
        }

        [Test]
        public void TheNewRoomsAlwaysSettle_andConserveChips()
        {
            foreach (var key in new[] { "trio", "headsup" })
                for (var seed = 0; seed < 20; seed++)
                {
                    _rig = new Rig(seed);
                    var c = _rig.C;
                    c.EnterTable(TableCatalog.ByKey(key));
                    for (var hand = 0; hand < 3; hand++)
                    {
                        var before = _rig.Round.Chips;
                        c.PlaceBet(100);
                        c.DealRound();
                        if (_rig.Round.Phase == RoundPhase.Insurance) c.DeclineInsurance();
                        Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase is RoundPhase.Playing or RoundPhase.Settlement), key + seed);
                        while (_rig.Round.Phase == RoundPhase.Playing)
                            if (BlackjackRules.HandValue(_rig.Round.ActiveHand.Cards) >= 17) c.PlayerStand(); else c.PlayerHit();
                        Assert.IsTrue(_rig.AdvanceUntil(() => _rig.Round.Phase == RoundPhase.Settlement), key + seed);
                        Assert.AreEqual(before + _rig.Round.RoundNet, _rig.Round.Chips, $"{key} seed {seed} hand {hand}");
                        if (key == "headsup") Assert.IsNull(_rig.Round.SweepInfo);
                        c.NextHand();
                    }
                    _rig.Dispose();
                }
            _rig = null;
        }

        [Test]
        public void TheEveningGiftAndAdPacingStillRunInAnyRoom()
        {
            _rig = new Rig(seed: 2, boot: true);
            _rig.C.EnterTable(TableCatalog.ByKey("headsup"));
            _rig.C.NextHand();
            _rig.Notifier.GiftTapped = true;
            var chips = _rig.Round.Chips;
            _rig.C.OnAppResumed();
            _rig.Advance(1.5);
            Assert.AreEqual(chips + 500, _rig.Round.Chips, "the gift pays whatever room the player is in");
        }

        [Test]
        public void OnlyClassicRoomsAreReportedAsPresence()
        {
            _rig = new Rig(seed: 2);
            _rig.C.Set(s => s with { SocialReady = true });
            _rig.C.EnterTable(TableCatalog.ByKey("trio"));
            _rig.C.EnterTable(T.Bronze);
            Assert.AreEqual("bronze", _rig.Round.Stake.Key);
            Assert.DoesNotThrow(() => _rig.C.ExitTable());
        }
    }
}
