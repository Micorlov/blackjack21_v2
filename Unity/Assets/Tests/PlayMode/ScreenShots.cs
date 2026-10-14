using System;
using System.Collections;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game;
using Blackjack.Game.UI;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace Blackjack.PlayTests
{
    /// <summary>One screenshot per screen/dialog, so the whole UI can be reviewed without a device.</summary>
    public class ScreenShots
    {
        private Shots.Stage _stage;
        private GameController _g;
        private AppRoot _app;

        private void Setup(AppState state)
        {
            _stage = Shots.Create();
            var go = new GameObject("Controller");
            _g = go.AddComponent<GameController>();
            _g.Init(new GameServices(), null, new System.Random(1), boot: false);
            _app = AppRoot.Attach(_stage.Root, _g);
            _g.Force(state);
        }

        private void Teardown()
        {
            UnityEngine.Object.Destroy(_g.gameObject);
            Shots.Destroy(_stage);
        }

        private static Overlays OverlaysOf(AppRoot app) =>
            (Overlays)typeof(AppRoot).GetField("_overlays", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(app);

        private static RoundState History() => new RoundState
        {
            Chips = 1475,
            History = new[] { RoundResult.Win, RoundResult.Loss, RoundResult.Push, RoundResult.Win, RoundResult.Win, RoundResult.Loss, RoundResult.Win },
            Stats = new StatsSummary(42, 21, 17, 4, 3, 2, 6),
            Session = new SessionSummary(9, 5, 340),
        };

        [UnityTest] public IEnumerator Onboarding()
        {
            Setup(new AppState { Screen = AppScreen.Onboarding });
            yield return Shots.Capture(_stage, "onboarding");
            Teardown();
        }

        [UnityTest] public IEnumerator Lobby_bonusReady()
        {
            Setup(new AppState { Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History() });
            yield return Shots.Capture(_stage, "lobby_bonus_ready");
            Teardown();
        }

        [UnityTest] public IEnumerator Lobby_claimed_withFriendsHere()
        {
            var friends = new[]
            {
                new Friend("u1", "Maya T.", 2000, true, 120, 20, TableKey: "bronze"),
                new Friend("u2", "Sam R.", 900, true, -30, 5, TableKey: "bronze"),
                new Friend("u3", "Priya N.", 3000, true, 500, 80, TableKey: "vip"),
            };
            Setup(new AppState
            {
                Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History(), Friends = friends, FriendsAreLive = true,
                LastDailyBonusClaimAt = DateTime.Now.AddHours(-3), DailyBonusStreakDay = 3,
            });
            yield return Shots.Capture(_stage, "lobby_claimed_friends");
            Teardown();
        }

        [UnityTest] public IEnumerator Stats_recent()
        {
            Setup(new AppState { Screen = AppScreen.Stats, Round = History(), StatsTab = StatsTab.Recent });
            yield return Shots.Capture(_stage, "stats_recent");
            Teardown();
        }

        [UnityTest] public IEnumerator Stats_allTime()
        {
            Setup(new AppState { Screen = AppScreen.Stats, Round = History(), StatsTab = StatsTab.AllTime });
            yield return Shots.Capture(_stage, "stats_alltime");
            Teardown();
        }

        [UnityTest] public IEnumerator Friends_empty()
        {
            Setup(new AppState { Screen = AppScreen.Friends, Round = History() });
            yield return Shots.Capture(_stage, "friends_empty");
            Teardown();
        }

        [UnityTest] public IEnumerator Friends_live()
        {
            var friends = new[]
            {
                new Friend("u1", "Maya T.", 2000, true, 120, 20),
                new Friend("u2", "Sam R.", 900, false, -30, 5),
            };
            Setup(new AppState
            {
                Screen = AppScreen.Friends, Round = History(), Friends = friends, FriendsAreLive = true, GroupCode = "K7Q2XM",
                LeaderboardPeriod = LeaderboardPeriod.Daily, HeroDailyPoints = 75, HeroDayKey = Points.DayKeyOf(DateTime.Now),
            });
            yield return Shots.Capture(_stage, "friends_live");
            Teardown();
        }

        [UnityTest] public IEnumerator Settings_signedOut()
        {
            Setup(new AppState { Screen = AppScreen.Settings, Round = History() });
            yield return Shots.Capture(_stage, "settings");
            Teardown();
        }

        [UnityTest] public IEnumerator Settings_signedIn_bottom()
        {
            Setup(new AppState { Screen = AppScreen.Settings, Round = History(), SignedIn = true, DisplayName = "Michael Orlov", SoundOn = false });
            yield return Shots.Capture(_stage, "settings_signedin");
            Teardown();
        }

        [UnityTest] public IEnumerator Dialog_dailyBonus()
        {
            Setup(new AppState { Screen = AppScreen.Lobby, Round = History(), DailyBonusStreakDay = 3, LastDailyBonusClaimAt = DateTime.Now.AddHours(-30) });
            DailyBonusDialog.Show(_g, OverlaysOf(_app));
            yield return Shots.Capture(_stage, "dialog_daily_bonus");
            Teardown();
        }

        [UnityTest] public IEnumerator Sheet_outOfChips()
        {
            var round = new RoundState { Chips = 12, Stake = TableCatalog.Tables[0], NpcSeats = new[] { new NpcSeat(25), new NpcSeat(25), new NpcSeat(25), new NpcSeat(25) } };
            Setup(new AppState { Screen = AppScreen.Table, Round = round, TutorialDismissed = true, LastRebuyAt = DateTime.Now.AddHours(-1) });
            OutOfChipsSheet.Show(_g, OverlaysOf(_app));
            yield return Shots.Capture(_stage, "sheet_out_of_chips");
            Teardown();
        }

        [UnityTest] public IEnumerator Sheet_howToPlay()
        {
            Setup(new AppState { Screen = AppScreen.Settings, Round = History() });
            HowToPlaySheet.Show(OverlaysOf(_app));
            yield return Shots.Capture(_stage, "sheet_how_to_play");
            Teardown();
        }

        [UnityTest] public IEnumerator Page_terms()
        {
            Setup(new AppState { Screen = AppScreen.Onboarding });
            LegalPage.Show(OverlaysOf(_app), LegalContent.Terms);
            yield return Shots.Capture(_stage, "page_terms");
            Teardown();
        }

        [UnityTest] public IEnumerator Table_chat()
        {
            var round = new RoundState { Chips = 1250, Stake = TableCatalog.Tables[0], NpcSeats = new[] { new NpcSeat(25), new NpcSeat(25), new NpcSeat(25), new NpcSeat(25) } };
            Setup(new AppState
            {
                Screen = AppScreen.Table, Round = round, TutorialDismissed = true, TableChatOpen = true,
                ChatMessages = new[] { new ChatMessage("Maya T.", "Nice hand!", 1), new ChatMessage("You", "GG", 2) },
            });
            yield return Shots.Capture(_stage, "table_chat");
            Teardown();
        }

        [UnityTest] public IEnumerator Rtl_hebrew_lobby_and_table()
        {
            Loc.Use("he");
            Setup(new AppState { Screen = AppScreen.Lobby, DisplayName = "Michael", Round = History() });
            yield return Shots.Capture(_stage, "rtl_he_lobby");
            _g.Force(new AppState { Screen = AppScreen.Table, DisplayName = "Michael", TutorialDismissed = true, Round = new RoundState { Chips = 1250, Stake = TableCatalog.Tables[0], Bet = 125, NpcSeats = new[] { new NpcSeat(25), new NpcSeat(50), new NpcSeat(25), new NpcSeat(100) } } });
            yield return Shots.Capture(_stage, "rtl_he_table");
            Teardown();
            Loc.Use("en");
        }

        [UnityTest] public IEnumerator Rtl_arabic_settings_and_howto()
        {
            Loc.Use("ar");
            Setup(new AppState { Screen = AppScreen.Settings, Round = History() });
            yield return Shots.Capture(_stage, "rtl_ar_settings");
            HowToPlaySheet.Show(OverlaysOf(_app));
            yield return Shots.Capture(_stage, "rtl_ar_howto");
            Teardown();
            Loc.Use("en");
        }
    }
}
