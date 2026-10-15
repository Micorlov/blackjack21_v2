using System;
using System.Collections;
using System.Collections.Generic;
using Blackjack.Core;
using Blackjack.Game;
using Blackjack.Game.UI;
using UnityEngine;

namespace Blackjack.PlayTests
{
    /// <summary>One state of the app to draw: a screen, a table phase, or a dialog/sheet open on top of one.</summary>
    internal sealed class Scenario
    {
        public readonly string Name;
        public readonly string Locale;
        public readonly Func<AppState> State;
        public readonly Action<GameController, Overlays> Open;

        public Scenario(string name, Func<AppState> state, Action<GameController, Overlays> open = null, string locale = "en")
        {
            Name = name;
            State = state;
            Open = open;
            Locale = locale;
        }

        public override string ToString() => Name;
    }

    /// <summary>
    /// Every screen and state the app can show, in one place: the screenshot test draws each of them and
    /// <c>RulesAudit</c> checks each of them against the design rules on several phone sizes.
    /// </summary>
    internal static class Scenarios
    {
        private static PlayingCard C(string rank, string suit = "♠") => new PlayingCard(rank, suit);

        private static AppState Table(RoundState round, bool tutorialDone = true) => new AppState
        {
            Screen = AppScreen.Table,
            DisplayName = "Michael",
            Round = round,
            TutorialDismissed = tutorialDone,
        };

        private static RoundState History() => new RoundState
        {
            Chips = 1475,
            History = new[] { RoundResult.Win, RoundResult.Loss, RoundResult.Push, RoundResult.Win, RoundResult.Win, RoundResult.Loss, RoundResult.Win },
            Stats = new StatsSummary(42, 21, 17, 4, 3, 2, 6),
            Session = new SessionSummary(9, 5, 340),
        };

        private static RoundState Betting() => new RoundState
        {
            Chips = 1250, Stake = TableCatalog.Tables[0], Bet = 125,
            NpcSeats = new[] { new NpcSeat(25), new NpcSeat(50), new NpcSeat(25), new NpcSeat(100) },
        };

        private static RoundState EmptyTable(int chips = 1250) => new RoundState
        {
            Chips = chips, Stake = TableCatalog.Tables[0],
            NpcSeats = new[] { new NpcSeat(25), new NpcSeat(25), new NpcSeat(25), new NpcSeat(25) },
        };

        // ---- The Seat: the ten states of the design reference (docs/design-concepts/the-seat) ----------

        private static RoundState SeatRound(RoundPhase phase, IReadOnlyList<Hand> hands, IReadOnlyList<PlayingCard> dealer,
            IReadOnlyList<NpcSeat> seats, int chips = 900, bool holeRevealed = false, int? acting = null) => new RoundState
        {
            Chips = chips, Stake = TableCatalog.Tables[0], Bet = 100, LastBet = 100, Phase = phase,
            DealerHand = dealer, HoleRevealed = holeRevealed, Hands = hands, NpcSeats = seats, ActingSeat = acting,
        };

        private static IReadOnlyList<NpcSeat> SeatsMidRound() => new[]
        {
            new NpcSeat(50, new[] { C("10", "♣"), C("4", "♦"), C("3") }, "STAND", true),
            new NpcSeat(100, new[] { C("K", "♣"), C("6", "♥"), C("9") }, "BUST", true),
            new NpcSeat(25, new[] { C("9", "♣"), C("4", "♦") }),
            new NpcSeat(50, new[] { C("A", "♦"), C("8") }),
        };

        private static Scenario[] Seat() => new[]
        {
            new Scenario("seat_01_betting", () => Table(SeatRound(RoundPhase.Betting, new[] { Hand.Empty }, Array.Empty<PlayingCard>(),
                new[] { new NpcSeat(50), new NpcSeat(100), new NpcSeat(25), new NpcSeat(50) }, 1000))),
            new Scenario("seat_02_insurance", () => Table(SeatRound(RoundPhase.Insurance,
                new[] { new Hand(new[] { C("10"), C("9", "♦") }, 100) }, new[] { C("A"), C("5", "♥") },
                new[]
                {
                    new NpcSeat(50, new[] { C("6", "♦"), C("6", "♥") }), new NpcSeat(100, new[] { C("Q", "♣"), C("5", "♦") }),
                    new NpcSeat(25, new[] { C("10", "♥"), C("10", "♣") }), new NpcSeat(50, new[] { C("7", "♣"), C("9", "♥") }),
                }) with { InsuranceBet = 50 })),
            new Scenario("seat_03_seat_playing", () => Table(SeatRound(RoundPhase.Npcs,
                new[] { new Hand(new[] { C("8"), C("3", "♥") }, 100) }, new[] { C("6", "♦"), C("9", "♣") },
                new[]
                {
                    new NpcSeat(50, new[] { C("10", "♣"), C("4", "♦") }, "HIT"), new NpcSeat(100, new[] { C("K", "♣"), C("6", "♥") }),
                    new NpcSeat(25, new[] { C("9", "♣"), C("4", "♦") }), new NpcSeat(50, new[] { C("A", "♦"), C("8") }),
                }, acting: 0))),
            new Scenario("seat_04_your_turn", () => Table(SeatRound(RoundPhase.Playing,
                new[] { new Hand(new[] { C("8"), C("3", "♥") }, 100) }, new[] { C("6", "♦"), C("9", "♣") }, SeatsMidRound()))),
            new Scenario("seat_05_double", () => Table(SeatRound(RoundPhase.Playing,
                new[] { new Hand(new[] { C("8"), C("3", "♥"), C("K", "♦") }, 200, HandStatus.Stood, true) },
                new[] { C("6", "♦"), C("9", "♣") }, SeatsMidRound(), 800))),
            new Scenario("seat_06_split", () => Table(SeatRound(RoundPhase.Playing,
                new[] { new Hand(new[] { C("8"), C("3", "♦") }, 100), new Hand(new[] { C("8", "♥") }, 100) },
                new[] { C("5", "♣"), C("9", "♥") }, SeatsMidRound(), 800))),
            new Scenario("seat_07_dealer", () => Table(SeatRound(RoundPhase.Dealer,
                new[] { new Hand(new[] { C("8"), C("3", "♥"), C("K", "♦") }, 200, HandStatus.Stood, true) },
                new[] { C("6", "♦"), C("K", "♣") }, SeatsMidRound(), 800, true))),
            new Scenario("seat_08_result", () => Table(SeatRound(RoundPhase.Settlement,
                new[] { new Hand(new[] { C("8"), C("3", "♥"), C("K", "♦") }, 200, HandStatus.Stood, true) },
                new[] { C("6", "♦"), C("K", "♣"), C("9") }, SeatsMidRound(), 1400, true) with
            {
                Message = "You sweep the table", MessageType = MessageType.Win, SweepAmount = 200, RoundNet = 400,
                RoundStake = 200, RoundHandNet = 200,
                SweepInfo = new SweepInfo(200, 200, 400, "You", 21, true,
                    new[] { new SweepContributor("Jordan", 100, "bust"), new SweepContributor("Sam", 100, "lost") }),
            })),
            new Scenario("seat_09_blackjack", () => Table(SeatRound(RoundPhase.Npcs,
                new[] { new Hand(new[] { C("A"), C("K", "♥") }, 100, HandStatus.Blackjack) }, new[] { C("9", "♣"), C("7") },
                new[]
                {
                    new NpcSeat(50, new[] { C("Q", "♣"), C("K", "♦") }, "STAND", true), new NpcSeat(100, new[] { C("2", "♣"), C("K", "♦") }, "HIT"),
                    new NpcSeat(25, new[] { C("8", "♥"), C("9") }), new NpcSeat(50, new[] { C("5", "♥"), C("K") }),
                }, 1300, acting: 1))),
            new Scenario("seat_10_bust", () => Table(SeatRound(RoundPhase.Npcs,
                new[] { new Hand(new[] { C("10", "♣"), C("6", "♣"), C("9", "♦") }, 100, HandStatus.Busted) }, new[] { C("10", "♥"), C("7") },
                new[]
                {
                    new NpcSeat(50, new[] { C("Q", "♣"), C("4", "♦"), C("8") }, "BUST", true), new NpcSeat(100, new[] { C("10"), C("10", "♦") }, "STAND", true),
                    new NpcSeat(25, new[] { C("9", "♥"), C("5") }, "HIT"), new NpcSeat(50, new[] { C("K", "♦"), C("8", "♣") }),
                }, 1450, acting: 2))),
            // Six dealer cards and the widest box label ("26 · bust"): the row must leave the box room on the felt.
            new Scenario("seat_11_dealer_long_bust", () => Table(SeatRound(RoundPhase.Dealer,
                new[] { new Hand(new[] { C("4", "♣"), C("3", "♣"), C("Q", "♥") }, 100, HandStatus.Stood) },
                new[] { C("5"), C("A", "♦"), C("8"), C("A"), C("A"), C("10") }, SeatsMidRound(), 1000, true))),
        };

        // ---- every other screen, dialog and sheet -------------------------------------------------------

        private static Scenario[] Screens() => new[]
        {
            new Scenario("onboarding", () => new AppState { Screen = AppScreen.Onboarding }),
            new Scenario("lobby_bonus_ready", () => new AppState { Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History() }),
            new Scenario("lobby_claimed_friends", () => new AppState
            {
                Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History(), FriendsAreLive = true,
                Friends = new[]
                {
                    new Friend("u1", "Maya T.", 2000, true, 120, 20, TableKey: "bronze"),
                    new Friend("u2", "Sam R.", 900, true, -30, 5, TableKey: "bronze"),
                    new Friend("u3", "Priya N.", 3000, true, 500, 80, TableKey: "vip"),
                },
                LastDailyBonusClaimAt = DateTime.Now.AddHours(-3), DailyBonusStreakDay = 3,
            }),
            new Scenario("stats_recent", () => new AppState { Screen = AppScreen.Stats, Round = History(), StatsTab = StatsTab.Recent }),
            new Scenario("stats_alltime", () => new AppState { Screen = AppScreen.Stats, Round = History(), StatsTab = StatsTab.AllTime }),
            new Scenario("friends_empty", () => new AppState { Screen = AppScreen.Friends, Round = History() }),
            new Scenario("friends_live", () => new AppState
            {
                Screen = AppScreen.Friends, Round = History(), FriendsAreLive = true, GroupCode = "K7Q2XM",
                Friends = new[] { new Friend("u1", "Maya T.", 2000, true, 120, 20), new Friend("u2", "Sam R.", 900, false, -30, 5) },
                LeaderboardPeriod = LeaderboardPeriod.Daily, HeroDailyPoints = 75, HeroDayKey = Points.DayKeyOf(DateTime.Now),
            }),
            new Scenario("settings", () => new AppState { Screen = AppScreen.Settings, Round = History() }),
            // The rules hold below the fold too: the audit only reads what is on screen, so scroll there.
            new Scenario("settings_bottom", () => new AppState { Screen = AppScreen.Settings, Round = History() }, (g, o) => ScrollToEnd.Start()),
            new Scenario("settings_middle", () => new AppState { Screen = AppScreen.Settings, Round = History() }, (g, o) => ScrollToEnd.Start(0.45f)),
            new Scenario("settings_signedin", () => new AppState
                { Screen = AppScreen.Settings, Round = History(), SignedIn = true, DisplayName = "Michael Orlov", SoundOn = false }),

            new Scenario("table_betting", () => Table(Betting())),
            new Scenario("table_betting_coach", () => Table(Betting(), tutorialDone: false)),
            new Scenario("table_playing", () => Table(Betting() with
            {
                Chips = 1050, Bet = 100, Phase = RoundPhase.Playing,
                DealerHand = new[] { C("6", "♦"), C("K", "♣") },
                Hands = new[] { new Hand(new[] { C("A", "♥"), C("7") }, 100) },
                NpcSeats = new[]
                {
                    new NpcSeat(25, new[] { C("10"), C("9", "♦") }, "STAND", true),
                    new NpcSeat(50, new[] { C("10"), C("9", "♥"), C("5", "♣") }, "BUST", true),
                    new NpcSeat(25, new[] { C("8"), C("9", "♥") }, "STAND", true),
                    new NpcSeat(100, new[] { C("K", "♦"), C("Q") }, "STAND", true),
                },
            })),
            new Scenario("table_playing_coach", () => Table(Betting() with
            {
                Chips = 1050, Bet = 100, Phase = RoundPhase.Playing,
                DealerHand = new[] { C("6", "♦"), C("K", "♣") },
                Hands = new[] { new Hand(new[] { C("10", "♥"), C("6") }, 100) },
            }, tutorialDone: false)),
            new Scenario("table_settlement", () => Table(Betting() with
            {
                Chips = 1475, Bet = 100, Phase = RoundPhase.Settlement, HoleRevealed = true,
                DealerHand = new[] { C("10", "♦"), C("7", "♣") },
                Hands = new[] { new Hand(new[] { C("K"), C("Q", "♥") }, 100, HandStatus.Stood) },
                NpcSeats = new[]
                {
                    new NpcSeat(25, new[] { C("10"), C("9", "♦") }, "STAND", true),
                    new NpcSeat(50, new[] { C("10"), C("9", "♥"), C("5", "♣") }, "BUST", true),
                    new NpcSeat(25, new[] { C("8"), C("9", "♥") }, "STAND", true),
                    new NpcSeat(100, new[] { C("10", "♦"), C("6") }, "STAND", true),
                },
                Message = "You sweep the table", MessageType = MessageType.Win, SweepAmount = 150, RoundNet = 250,
                RoundStake = 100, RoundHandNet = 100,
                SweepInfo = new SweepInfo(150, 100, 250, "You", 20, true, new[]
                {
                    new SweepContributor("Jordan", 50, "bust"), new SweepContributor("Priya", 100, "lost"),
                }),
            })),
            new Scenario("table_settlement_coach", () => Table(Betting() with
            {
                Chips = 1062, Bet = 25, Phase = RoundPhase.Settlement, HoleRevealed = true,
                DealerHand = new[] { C("10", "♦"), C("A", "♣") },
                Hands = new[] { new Hand(new[] { C("10"), C("8", "♥") }, 25, HandStatus.Stood) },
                NpcSeats = new[]
                {
                    new NpcSeat(25, new[] { C("10"), C("9", "♦") }, "STAND", true),
                    new NpcSeat(50, new[] { C("10"), C("9", "♥"), C("5", "♣") }, "BUST", true),
                    new NpcSeat(25, new[] { C("8"), C("9", "♥") }, "STAND", true),
                    new NpcSeat(100, new[] { C("K", "♦"), C("Q") }, "STAND", true),
                },
                Message = "Dealer wins", MessageType = MessageType.Lose, SweepAmount = 0, RoundNet = -25,
                RoundStake = 25, RoundHandNet = -25,
            }, tutorialDone: false) with { TutorialRoundsSeen = 1 }),
            new Scenario("table_chat", () => Table(EmptyTable()) with
            {
                TableChatOpen = true,
                ChatMessages = new[] { new ChatMessage("Maya T.", "Nice hand!", 1), new ChatMessage("You", "GG", 2) },
            }),
            new Scenario("table_menu", () => Table(EmptyTable()) with { TableMenuOpen = true }),
            new Scenario("table_toast", () => Table(Betting()) with { Toast = "Table maximum is $500" }),

            new Scenario("dialog_daily_bonus",
                () => new AppState { Screen = AppScreen.Lobby, Round = History(), DailyBonusStreakDay = 3, LastDailyBonusClaimAt = DateTime.Now.AddHours(-30) },
                (g, o) => DailyBonusDialog.Show(g, o)),
            new Scenario("dialog_confirm_sign_out",
                () => new AppState { Screen = AppScreen.Settings, Round = History(), SignedIn = true, DisplayName = "Michael Orlov" },
                (g, o) => ConfirmDialog.Show(o, Loc.T("signOutConfirmTitle"), Loc.T("signOutConfirmMessage"), Loc.T("signOut"), () => { }, null, true)),
            new Scenario("sheet_out_of_chips",
                () => Table(EmptyTable(12)) with { LastRebuyAt = DateTime.Now.AddHours(-1) },
                (g, o) => OutOfChipsSheet.Show(g, o)),
            new Scenario("sheet_how_to_play", () => new AppState { Screen = AppScreen.Settings, Round = History() },
                (g, o) => HowToPlaySheet.Show(o)),
            new Scenario("page_terms", () => new AppState { Screen = AppScreen.Onboarding },
                (g, o) => LegalPage.Show(o, LegalContent.Terms)),
        };

        private static Scenario[] RightToLeft() => new[]
        {
            // The table keeps casino order in every language (first base on the right); text and panels mirror.
            new Scenario("rtl_he_seat_your_turn", () => Seat()[3].State(), null, "he"),
            new Scenario("rtl_he_seat_result", () => Seat()[7].State(), null, "he"),
            new Scenario("rtl_ar_seat_split", () => Seat()[5].State(), null, "ar"),
            new Scenario("rtl_ar_seat_waiting", () => Seat()[8].State(), null, "ar"),
            new Scenario("rtl_he_lobby", () => new AppState { Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History() }, null, "he"),
            new Scenario("rtl_he_table", () => Table(Betting()), null, "he"),
            new Scenario("rtl_ar_settings", () => new AppState { Screen = AppScreen.Settings, Round = History() }, null, "ar"),
            new Scenario("rtl_ar_howto", () => new AppState { Screen = AppScreen.Settings, Round = History() }, (g, o) => HowToPlaySheet.Show(o), "ar"),
        };

        public static IReadOnlyList<Scenario> All
        {
            get
            {
                var all = new List<Scenario>();
                all.AddRange(Seat());
                all.AddRange(Screens());
                all.AddRange(RightToLeft());
                // BJ_SCENARIO=seat_ narrows a run to the scenarios whose name contains it.
                var only = Environment.GetEnvironmentVariable("BJ_SCENARIO");
                return string.IsNullOrEmpty(only) ? all : all.FindAll(s => s.Name.Contains(only));
            }
        }
    }

    /// <summary>Scrolls every scroll view on screen to a point (0 = the bottom) once the layout has settled.</summary>
    internal sealed class ScrollToEnd : MonoBehaviour
    {
        private float _position;
        private int _frames;

        public static void Start(float position = 0f)
        {
            var go = new GameObject("ScrollToEnd");
            go.AddComponent<ScrollToEnd>()._position = position;
        }

        private void LateUpdate()
        {
            foreach (var scroll in FindObjectsByType<UnityEngine.UI.ScrollRect>(FindObjectsSortMode.None))
            {
                scroll.verticalNormalizedPosition = _position;
                scroll.velocity = Vector2.zero;
            }
            if (++_frames > 10) Destroy(gameObject);
        }
    }

    /// <summary>A scenario drawn on a stage of its own: the controller, the whole UI, and any dialog it opens.</summary>
    internal sealed class ScenarioRun
    {
        public Shots.Stage Stage { get; private set; }
        public GameController Controller { get; private set; }

        private static Overlays OverlaysOf(AppRoot app) =>
            (Overlays)typeof(AppRoot).GetField("_overlays", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(app);

        public static ScenarioRun Start(Scenario scenario, int width = Shots.Width, int height = Shots.Height)
        {
            // The language is chosen before the UI exists, so nothing is built twice.
            Loc.Use(scenario.Locale);
            var run = new ScenarioRun { Stage = Shots.Create(width, height) };
            var go = new GameObject("Controller");
            run.Controller = go.AddComponent<GameController>();
            run.Controller.Init(new GameServices(), null, new System.Random(1), boot: false);
            var app = AppRoot.Attach(run.Stage.Root, run.Controller);
            run.Controller.Force(scenario.State());
            scenario.Open?.Invoke(run.Controller, OverlaysOf(app));
            return run;
        }

        public IEnumerator Settle() => Shots.Settle();

        public void Stop()
        {
            UnityEngine.Object.Destroy(Controller.gameObject);
            Shots.Destroy(Stage);
            Loc.Use("en");
        }
    }
}
