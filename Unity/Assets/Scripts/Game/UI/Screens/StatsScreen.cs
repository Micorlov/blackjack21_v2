using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>Session and all-time numbers, and the last ten hands as dots.</summary>
    public sealed class StatsScreen : ScreenView
    {
        private Dyn _body;

        public StatsScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("Stats", parent).Fill();
            var scroll = W.Scroll(Root, Ui.Pad(20, 20, 20, 24), 0, true, false, out var sr);
            scroll.Fill();
            _body = new Dyn(Ui.VStack(sr.content, 0, null, TextAnchor.UpperLeft, true, "Body"));
        }

        public override void Refresh(AppState s)
        {
            var r = s.Round;
            var sig = $"{s.StatsTab}|{r.Stats}|{r.Session}|{string.Join("", r.History.Select(h => (int)h))}|{Loc.Code}";
            _body.Update(sig, host => Build(host, s));
        }

        private void Build(RectTransform host, AppState s)
        {
            var r = s.Round;
            W.ScreenTitle(host, Loc.Or("navStats", "Stats"));
            TabPills.Row(host,
                (Loc.Or("statsRecent", "Recent"), s.StatsTab == StatsTab.Recent, () => G.SetStatsTab(StatsTab.Recent)),
                (Loc.Or("statsAllTime", "All time"), s.StatsTab == StatsTab.AllTime, () => G.SetStatsTab(StatsTab.AllTime)));
            Ui.Spacer(host, 16);

            if (s.StatsTab == StatsTab.Recent)
            {
                var row = Ui.HStack(host, 12, null, TextAnchor.UpperLeft, true);
                Tile(row, r.Session.Hands.ToString(), Loc.Or("statHandsSession", "Hands this session")).FlexW();
                Tile(row, r.Session.Wins.ToString(), Loc.Or("statWinsSession", "Wins this session")).FlexW();
                Ui.Spacer(host, 12);
                var net = (r.Session.Net >= 0 ? "+$" : "−$") + TableCatalog.FormatChips(System.Math.Abs(r.Session.Net));
                Tile(host, net, Loc.Or("statNetSession", "Net chips this session"), r.Session.Net >= 0 ? Theme.Win : Theme.Lose);
                Ui.Spacer(host, 20);
            }
            else
            {
                var row1 = Ui.HStack(host, 12, null, TextAnchor.UpperLeft, true);
                Tile(row1, r.Stats.HandsPlayed.ToString(), Loc.Or("statHandsPlayed", "Hands played")).FlexW();
                Tile(row1, WinRate(r.Stats), Loc.Or("statWinRate", "Win rate")).FlexW();
                Ui.Spacer(host, 12);
                var row2 = Ui.HStack(host, 12, null, TextAnchor.UpperLeft, true);
                Tile(row2, r.Stats.Blackjacks.ToString(), Loc.Or("statBlackjacks", "Blackjacks")).FlexW();
                Tile(row2, r.Stats.CurrentStreak.ToString(), Loc.Or("statCurrentStreak", "Current streak")).FlexW();
                Ui.Spacer(host, 12);
                Tile(host, r.Stats.BestStreak.ToString(), Loc.Or("statBestStreak", "Best streak"));
                Ui.Spacer(host, 20);
            }

            W.SectionLabel(host, Loc.Or("statLast10", "Last 10 hands"));
            var panel = W.Panel(host, Ui.Pad(16), Theme.Md);
            var recent = r.History.Skip(System.Math.Max(0, r.History.Count - 10)).ToList();
            if (recent.Count == 0)
            {
                Ui.Text(panel, Loc.Or("statEmpty", "Play a hand to see your streak here."), 15, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 15);
                return;
            }
            var dots = Ui.HStack(panel, Theme.Sm, null, TextAnchor.MiddleLeft, false);
            foreach (var h in recent) HistoryDot(dots, h, 24, 15);
            var legend = Ui.HStack(panel, Theme.Lg, null, TextAnchor.MiddleLeft, false);
            foreach (var result in new[] { RoundResult.Win, RoundResult.Loss, RoundResult.Push })
            {
                var item = Ui.HStack(legend, Theme.Xs, null, TextAnchor.MiddleLeft, false);
                HistoryDot(item, result, 16, 11);
                Ui.Text(item, Label(result), 12, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Left, false);
            }
        }

        private static string WinRate(StatsSummary stats) =>
            stats.HandsPlayed <= 0 ? "0%" : Mathf.RoundToInt(stats.Wins / (float)stats.HandsPlayed * 100f) + "%";

        private static string Label(RoundResult r) => r switch
        {
            RoundResult.Win => Loc.Or("resultWin", "Win"), RoundResult.Loss => Loc.Or("resultLoss", "Loss"), _ => Loc.Or("resultPush", "Push"),
        };

        private static void HistoryDot(RectTransform parent, RoundResult r, float size, float icon)
        {
            var (color, name, ink) = r switch
            {
                RoundResult.Win => (Theme.Win, "check", Theme.GoldInk),
                RoundResult.Loss => (Theme.Lose, "close", Theme.TextPrimary),
                _ => (Theme.Push, "remove", Theme.GoldInk),
            };
            var dot = W.Dot(parent, size, color);
            var ic = W.Icon(dot.transform, name, icon, ink);
            ic.rectTransform.IgnoreLayout();
            ic.rectTransform.PinCentre(Vector2.zero, new Vector2(icon, icon));
        }

        private static RectTransform Tile(RectTransform parent, string value, string label, Color? valueColor = null)
        {
            var tile = W.Panel(parent, Ui.Pad(16), 0);
            var outer = (RectTransform)tile.parent;
            Ui.Text(tile, value, 30, valueColor ?? Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            Ui.Text(tile, label, 14, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
            return outer;
        }
    }
}
