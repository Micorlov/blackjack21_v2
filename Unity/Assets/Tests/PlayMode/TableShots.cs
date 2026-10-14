using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game;
using Blackjack.Game.UI;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace Blackjack.PlayTests
{
    public class TableShots
    {
        private Shots.Stage _stage;
        private GameController _g;
        private AppRoot _app;

        private static PlayingCard C(string rank, string suit = "♠") => new PlayingCard(rank, suit);

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

        private static AppState TableState(RoundState round) => new AppState
        {
            Screen = AppScreen.Table,
            DisplayName = "Michael",
            Round = round,
            TutorialDismissed = true,
        };

        private static RoundState Betting() => new RoundState
        {
            Chips = 1250, Stake = TableCatalog.Tables[0], Bet = 125,
            NpcSeats = new[] { new NpcSeat(25), new NpcSeat(50), new NpcSeat(25), new NpcSeat(100) },
        };

        [UnityTest]
        public IEnumerator Betting_phase()
        {
            Setup(TableState(Betting()));
            yield return Shots.Capture(_stage, "table_betting");
            Teardown();
        }

        [UnityTest]
        public IEnumerator Betting_phase_with_coach()
        {
            var s = TableState(Betting()) with { TutorialDismissed = false };
            Setup(s);
            yield return Shots.Capture(_stage, "table_betting_coach");
            Teardown();
        }

        [UnityTest]
        public IEnumerator Playing_phase()
        {
            var round = Betting() with
            {
                Chips = 1050, Bet = 100, Phase = RoundPhase.Playing,
                DealerHand = new[] { C("6", "♦"), C("K", "♣") },
                Hands = new[] { new Hand(new[] { C("A", "♥"), C("7", "♠") }, 100) },
                NpcSeats = new[]
                {
                    new NpcSeat(25, new[] { C("10"), C("9", "♦") }, "STAND", true),
                    new NpcSeat(50, new[] { C("10"), C("9", "♥"), C("5", "♣") }, "BUST", true),
                    new NpcSeat(25, new[] { C("8"), C("9", "♥") }, "STAND", true),
                    new NpcSeat(100, new[] { C("K", "♦"), C("Q") }, "STAND", true),
                },
            };
            Setup(TableState(round));
            yield return Shots.Capture(_stage, "table_playing");
            Teardown();
        }

        [UnityTest]
        public IEnumerator Settlement_with_sweep()
        {
            var round = Betting() with
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
            };
            Setup(TableState(round));
            yield return Shots.Capture(_stage, "table_settlement");
            Teardown();
        }
    }
}
