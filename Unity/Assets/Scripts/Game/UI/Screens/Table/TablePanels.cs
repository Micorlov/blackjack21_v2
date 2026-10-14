using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The bottom action panels, one per round phase. Each is rebuilt only when what it shows changes.</summary>
    public sealed class TablePanels
    {
        private const float DebounceSeconds = 0.25f;

        private readonly GameController _g;
        private readonly Overlays _overlays;
        private readonly Dyn _dyn;
        private float _lastAction = -10f;

        public TablePanels(GameController g, Overlays overlays, RectTransform host)
        {
            _g = g;
            _overlays = overlays;
            _dyn = new Dyn(host);
        }

        public void Refresh(AppState s)
        {
            var r = s.Round;
            switch (r.Phase)
            {
                case RoundPhase.Betting:
                    _dyn.Update(BettingSignature(s), h => Betting(h, s));
                    break;
                case RoundPhase.Insurance:
                    _dyn.Update("ins" + r.InsuranceBet, h => Insurance(h, s));
                    break;
                case RoundPhase.Playing:
                    _dyn.Update(PlayingSignature(s), h => Playing(h, s));
                    break;
                case RoundPhase.Npcs:
                case RoundPhase.NpcsAfter:
                    _dyn.Update("npc" + r.ActingSeat + StandingsSignature(s), h => Waiting(h, s,
                        Loc.T("gameSeatPlaying", ("name", ActingName(s))), 20));
                    break;
                case RoundPhase.Dealer:
                    _dyn.Update("dealer" + StandingsSignature(s), h => Waiting(h, s, Loc.T("gameDealerPlaying"), 24));
                    break;
                case RoundPhase.Settlement:
                    _dyn.Update(SettlementSignature(s), h => Settlement(h, s));
                    break;
            }
        }

        private static string ActingName(AppState s)
        {
            var seats = Roster.TableSeats(s.Friends, s.Round.Stake?.Key);
            var seat = s.Round.ActingSeat;
            return seat == null || seat.Value >= seats.Count ? "Table" : seats[seat.Value].FirstName;
        }

        private Action Debounced(Action a) => () =>
        {
            if (Time.unscaledTime - _lastAction < DebounceSeconds) return;
            _lastAction = Time.unscaledTime;
            a();
        };

        // ---- betting --------------------------------------------------------------------------------

        private string BettingSignature(AppState s)
        {
            var r = s.Round;
            var rebuyReady = Core.Rebuy.IsReady(s.LastRebuyAt, DateTime.Now);
            return $"bet{r.Bet}|{r.Chips}|{r.Stake?.Key}|{r.LastBet}|{s.FriendsAreLive}|{rebuyReady}|{Loc.Code}";
        }

        private void Betting(RectTransform host, AppState s)
        {
            var r = s.Round;
            var stake = r.Stake;
            var denoms = TableCatalog.ChipDenomsFor(stake);
            var tableMin = stake?.Min ?? 0;
            int? tableMax = stake?.Max;
            var belowMin = r.Bet < tableMin;
            var dealDisabled = !(r.Bet > 0 && r.Bet <= r.Chips) || belowMin;
            var canAllIn = r.Chips >= tableMin && r.Bet < r.Chips && (tableMax == null || r.Bet < tableMax);
            var canRebet = r.Bet == 0 && r.LastBet > 0 && r.LastBet <= r.Chips && r.LastBet >= tableMin
                           && (tableMax == null || r.LastBet <= tableMax);

            var col = Ui.VStack(host, 0, null, TextAnchor.UpperCenter, true, "Betting");

            // One compact line: the bet figure, the table minimum folded in until the bet clears it, ALL IN on the end.
            var line = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter);
            Ui.Text(line, Loc.T("gameBet"), 15, Theme.TextPrimary.WithAlpha(0.82f), FontKind.Mono, TextAlignmentOptions.Left, false, 1.2f);
            Ui.Text(line, "$" + r.Bet, 28, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            if (belowMin)
                Ui.Text(line, "·  " + Loc.T("gameMinimum", ("amount", "$" + TableCatalog.FormatChips(tableMin))), 15, Theme.TextMuted,
                    FontKind.Mono, TextAlignmentOptions.Left, false, 0.8f);
            if (canAllIn)
                W.ActionPill(line, Loc.T("gameAllIn"), Theme.Gold.WithAlpha(0.45f), Theme.Gold.WithAlpha(0.1f), Theme.Gold,
                    _g.BetAllIn, 8, 12, 15);

            Ui.Spacer(col, Theme.Xs);
            ChipTray(col, r, denoms, tableMax);
            Ui.Spacer(col, Theme.Xs);

            var buttons = Ui.HStack(col, 8, null, TextAnchor.MiddleCenter, true);
            var clear = W.ActionPill(buttons, Loc.T("gameClear"), Theme.Lose.WithAlpha(0.6f), Theme.Lose.WithAlpha(0.2f),
                Theme.LoseLight, _g.ClearBet, 16, 0, 20);
            clear.FlexW(1);
            var main = canRebet
                ? W.GoldButton(buttons, Loc.T("gameRebet", ("amount", "$" + TableCatalog.FormatChips(r.LastBet))), _g.RebetAndDeal, 16, 0, 20)
                : W.GoldButton(buttons, Loc.T("gameDeal"), _g.DealRound, 16, 0, 20, !dealDisabled);
            main.FlexW(2);

            // Practice bots fill the empty seats; say so once, quietly.
            if (!s.FriendsAreLive)
            {
                Ui.Spacer(col, Theme.Xs);
                var wrap = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter);
                Ui.Text(wrap, Loc.T("gamePracticeBots"), 15, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Center, false);
                W.TextLink(wrap, Loc.T("gameInvite"), _g.ShareInviteWhatsApp, Theme.Gold, 16);
            }

            // Below the table minimum the rebuy must appear before the stack hits zero.
            if (r.Chips < (stake?.Min ?? TableCatalog.StartingChips))
            {
                Ui.Spacer(col, Theme.Sm);
                var ready = Core.Rebuy.IsReady(s.LastRebuyAt, DateTime.Now);
                W.GoldButton(col, ready ? Loc.T("rebuyButtonLabel", ("chips", 1000)) : Loc.T("gameChipOptions"),
                    ready ? (Action)_g.Rebuy : () => OutOfChipsSheet.Show(_g, _overlays), 14, 0, 18);
                Ui.Spacer(col, Theme.Xs);
                W.TextLink(col, Loc.T("gameChipOptions"), () => OutOfChipsSheet.Show(_g, _overlays), Theme.Gold, 15);
            }
        }

        private void ChipTray(RectTransform parent, RoundState r, int[] denoms, int? tableMax)
        {
            const float chip = 64f;
            var row = Ui.HStack(parent, 8, null, TextAnchor.MiddleCenter);
            row.Size(null, chip);
            // Evenly spaced when they fit; the tray never scrolls, so ALL IN lives on the bet line instead.
            row.GetComponent<HorizontalLayoutGroup>().spacing = 8;
            foreach (var d in denoms)
            {
                var disabled = r.Bet + d > r.Chips || (tableMax != null && r.Bet + d > tableMax);
                var amount = d;
                W.ChipButton(row, d, Theme.ChipColor(d), disabled, () => _g.PlaceBet(amount), chip);
            }
        }

        // ---- insurance ------------------------------------------------------------------------------

        private void Insurance(RectTransform host, AppState s)
        {
            var col = Ui.VStack(host, 12, null, TextAnchor.UpperCenter, true, "Insurance");
            Ui.Text(col, Loc.T("gameInsuranceOffer", ("amount", "$" + TableCatalog.FormatChips(s.Round.InsuranceBet))), 20,
                Theme.TextPrimary.WithAlpha(0.85f), FontKind.Sora, TextAlignmentOptions.Center, true, 0, 20);
            // Declining carries the primary weight and insuring is the considered opt-in: insurance is a losing bet.
            var row = Ui.HStack(col, 8, null, TextAnchor.MiddleCenter, true);
            W.ActionPill(row, Loc.T("gameInsure"), Theme.Gold.WithAlpha(0.32f), Theme.Gold.WithAlpha(0.08f), Theme.Gold,
                _g.TakeInsurance, 22, 0, 20).FlexW(1);
            W.GoldButton(row, Loc.T("gameNoThanks"), _g.DeclineInsurance, 22, 0, 24).FlexW(2);
        }

        // ---- playing --------------------------------------------------------------------------------

        private static string PlayingSignature(AppState s)
        {
            var r = s.Round;
            return $"play{RoundEngine.CanDouble(r)}{RoundEngine.CanSplit(r)}{RoundEngine.CanSurrender(r)}{r.ActiveHandIndex}{Loc.Code}";
        }

        private void Playing(RectTransform host, AppState s)
        {
            var r = s.Round;
            var col = Ui.VStack(host, Theme.Sm + Theme.Xxs, null, TextAnchor.UpperCenter, true, "Playing");
            TurnTimerView.Build(col, _g);
            var top = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter, true);
            var gold = Theme.Gold.WithAlpha(0.32f);
            W.ActionPill(top, Loc.T("gameDouble"), gold, Theme.Gold.WithAlpha(0.08f), Theme.Gold, Debounced(_g.PlayerDouble), 16, 0, 20,
                RoundEngine.CanDouble(r)).FlexW(3);
            W.ActionPill(top, Loc.T("gameSplit"), gold, Theme.Gold.WithAlpha(0.08f), Theme.Gold, Debounced(_g.PlayerSplit), 16, 0, 20,
                RoundEngine.CanSplit(r)).FlexW(3);
            // Surrender forfeits half the bet for good: smallest share, destructive outline.
            W.ActionPill(top, Loc.T("gameSurrender"), Theme.Lose, Color.clear, Theme.LoseLight, Debounced(_g.PlayerSurrender), 16, 8, 16,
                RoundEngine.CanSurrender(r)).FlexW(2);

            // Equal halves, deliberately: neither action is right for every hand, so neither gets extra weight.
            var bottom = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter, true);
            W.ActionPill(bottom, Loc.T("gameStand"), Theme.Win.WithAlpha(0.6f), Theme.Win.WithAlpha(0.2f), Theme.WinLight,
                Debounced(_g.PlayerStand), 22, 0, 24).FlexW(1);
            W.GoldButton(bottom, Loc.T("gameHit"), Debounced(_g.PlayerHit), 22, 0, 24).FlexW(1);
        }

        // ---- waiting --------------------------------------------------------------------------------

        private static string StandingsSignature(AppState s) =>
            s.FriendsAreLive ? string.Join(",", s.Friends.Select(f => f.Id + f.HourlyScore)) + s.HeroHourlyPoints : "";

        private void Waiting(RectTransform host, AppState s, string text, float fontSize)
        {
            var col = Ui.VStack(host, Theme.Sm, null, TextAnchor.UpperCenter, true, "Waiting");
            var pad = Ui.VStack(col, 0, Ui.Pad(0, 38), TextAnchor.MiddleCenter, true);
            var row = Ui.HStack(pad, 10, null, TextAnchor.MiddleCenter);
            var dot = W.Dot(row, 10, Theme.Gold);
            dot.gameObject.AddComponent<PulseAlpha>();
            Ui.Text(row, text, fontSize, Theme.TextPrimary.WithAlpha(0.85f), FontKind.Sora, TextAlignmentOptions.Center, false);
            // Only once there are real people to race; with bots-only seats there is nothing to rank.
            if (s.FriendsAreLive) Standings(col, s);
        }

        private static void Standings(RectTransform parent, AppState s)
        {
            var hero = Points.Rolled(s.HeroHourlyPoints, s.HeroHourKey, Points.HourKeyOf(DateTime.Now));
            var rows = new List<(string name, int points, bool self)> { ("You", hero, true) };
            rows.AddRange(s.Friends.Select(f => (f.FirstName, f.HourlyScore, false)));
            rows = rows.OrderByDescending(x => x.points).ToList();
            var visible = rows.Select((x, i) => (rank: i + 1, row: x)).ToList();
            var selfIdx = visible.FindIndex(e => e.row.self);
            if (visible.Count > 5)
                visible = selfIdx >= 5 ? visible.Take(4).Append(visible[selfIdx]).ToList() : visible.Take(5).ToList();

            var card = Ui.Card(parent, Color.black.WithAlpha(0.35f), Theme.RadiusMd, Color.white.WithAlpha(0.1f), 1, Ui.Pad(12, 8), 2, true, "Standings");
            Ui.Text(card, Loc.Or("friendsThisHour", "Friends this hour"), 12, Theme.TextFaint, FontKind.SoraSemiBold);
            foreach (var e in visible)
            {
                var row = Ui.HStack(card, 4, null, TextAnchor.MiddleLeft, false);
                var rank = Ui.Text(row, "#" + e.rank, 13, Theme.TextFaint, FontKind.MonoBold, TextAlignmentOptions.Left, false);
                rank.rectTransform.Size(26);
                var name = Ui.Text(row, e.row.name, 12, e.row.self ? Theme.Gold : Theme.TextPrimary,
                    e.row.self ? FontKind.SoraBold : FontKind.SoraSemiBold, TextAlignmentOptions.Left, false);
                name.Shrink();
                name.rectTransform.FlexW();
                Ui.Text(row, (e.row.points >= 0 ? "+" : "-") + "$" + TableCatalog.FormatChips(Mathf.Abs(e.row.points)), 12,
                    e.row.points >= 0 ? Theme.WinLight : Theme.LoseSoft, FontKind.MonoBold, TextAlignmentOptions.Right, false);
            }
        }

        // ---- settlement -----------------------------------------------------------------------------

        private static string SettlementSignature(AppState s)
        {
            var r = s.Round;
            return $"set{r.Stats.HandsPlayed}|{r.Message}|{r.RoundNet}|{r.SweepAmount}|{r.Chips}|{Loc.Code}";
        }

        private void Settlement(RectTransform host, AppState s)
        {
            var r = s.Round;
            var netColor = r.RoundNet > 0 ? Theme.WinLight : r.RoundNet < 0 ? Theme.LoseLight : Theme.Push;
            var messageColor = r.MessageType switch
            {
                MessageType.Win => Theme.Win, MessageType.Lose => Theme.Lose, MessageType.Push => Theme.Push, _ => Theme.TextPrimary,
            };
            var pot = TableCalc.MidRound(r);
            var winner = TableCalc.WinnerInfo(s);
            var resultKey = Guide.ResultKey(r.Message);
            var handColor = r.RoundHandNet > 0 ? Theme.WinLight : r.RoundHandNet < 0 ? Theme.LoseLight : Theme.Push;

            var card = Ui.Card(host, Color.black.WithAlpha(0.72f), 18, netColor, 2, Ui.Pad(15, 8), 0, true, "Settlement");

            // Message on the left, the figure the player came for on the right.
            var head = Ui.HStack(card, 12, null, TextAnchor.UpperLeft, false);
            var msg = Ui.Text(head, resultKey != null ? Loc.T(resultKey) : r.Message, 28, messageColor, FontKind.SerifItalic, TextAlignmentOptions.TopLeft, true, 0, -10);
            msg.rectTransform.FlexW();
            var net = Ui.Text(head, "", 40, netColor, FontKind.MonoBold, TextAlignmentOptions.TopRight, false);
            CountUpText.Make(net, r.RoundNet, "$", true, () => { if (s.HapticsOn) _g.Services.Haptics.Selection(); });
            net.rectTransform.Ensure<LayoutElement>().minWidth = 80;

            Ui.Spacer(card, 4);
            var cardsRow = Ui.HStack(card, 7, null, TextAnchor.MiddleLeft, false);
            var strip = Ui.HStack(cardsRow, -2, null, TextAnchor.MiddleLeft, false);
            foreach (var c in r.Hands.SelectMany(h => h.Cards))
                CardViews.Face(strip, c, 24, 33, false);
            Ui.Text(cardsRow, TableCalc.ShowdownLabel(r, pot.HeroLiveTotal), 14, Theme.TextPrimary.WithAlpha(0.6f),
                FontKind.Mono, TextAlignmentOptions.Left, false, 0.06f);

            Ui.Spacer(card, 6);
            W.Divider(card, Color.white.WithAlpha(0.1f));
            Ui.Spacer(card, 6);
            StatRow(card, Loc.T("gameYouBet"), "$" + TableCatalog.FormatChips(r.RoundStake), Theme.TextPrimary, null);
            StatRow(card, Loc.T("gameAgainstDealer"), (r.RoundHandNet >= 0 ? "+" : "−") + "$" + TableCatalog.FormatChips(Mathf.Abs(r.RoundHandNet)), handColor, null);
            if (r.SweepAmount > 0)
                StatRow(card, Loc.T("gameSweepPot"), "+$" + TableCatalog.FormatChips(r.SweepAmount), Theme.Gold, Theme.Gold);
            W.Divider(card, Color.white.WithAlpha(0.08f));
            StatRow(card, Loc.T("gameBalance"), TableCatalog.FormatChips(r.Chips), Theme.TextPrimary, null);

            Ui.Spacer(card, 6);
            PotDetail(card, r, winner);
            Ui.Spacer(card, 6);
            W.GoldButton(card, Loc.T("gameNextHand"), _g.NextHand, 16, 0, 17);
        }

        private static void StatRow(RectTransform parent, string label, string value, Color valueColor, Color? labelColor)
        {
            var row = Ui.HStack(parent, 8, Ui.Pad(0, 1), TextAnchor.MiddleLeft, false);
            var l = Ui.Text(row, label, 16, labelColor ?? Theme.TextPrimary.WithAlpha(0.66f), FontKind.Mono, TextAlignmentOptions.Left, false);
            // No ellipsis here: TMP drops the whole line in the mono face when it tries to ellipsise.
            l.rectTransform.FlexW();
            Ui.Text(row, value, 18, valueColor, FontKind.MonoBold, TextAlignmentOptions.Right, false);
        }

        private static void PotDetail(RectTransform parent, RoundState r, PotWinnerInfo winner)
        {
            var sweep = r.SweepInfo;
            var card = Ui.Card(parent, sweep != null ? Theme.Gold.WithAlpha(0.06f) : Color.white.WithAlpha(0.03f), Theme.RadiusMd,
                sweep != null ? Theme.Gold.WithAlpha(0.3f) : Color.white.WithAlpha(0.1f), 1, Ui.Pad(9, 5), 5, true, "PotDetail");
            var row = Ui.Card(card, winner.RowBg, 10, winner.RowBorder, 1, Ui.Pad(9, 5), 0, true, "Winner");
            var hs = Ui.HStack(row, 9, null, TextAnchor.MiddleLeft, false);
            W.Avatar(hs, winner.Initial, winner.AvatarBg, 36);
            var col = Ui.VStack(hs, 0, null, TextAnchor.MiddleLeft, true);
            col.FlexW();
            Ui.Text(col, winner.Headline, 17, winner.TextColor, FontKind.SoraBold, TextAlignmentOptions.TopLeft, true);
            Ui.Text(col, winner.Sub, 13, Theme.TextPrimary.WithAlpha(0.55f), FontKind.Mono, TextAlignmentOptions.Left, false, 0.06f);
            Ui.Text(hs, sweep != null ? "$" + TableCatalog.FormatChips(sweep.TotalWin) : "—", 22, winner.TextColor, FontKind.MonoBold, TextAlignmentOptions.Right, false);

            if (sweep == null || sweep.Contributors.Count == 0) return;
            var wrap = Ui.Node("Contributors", card);
            var flow = wrap.gameObject.AddComponent<GridLayoutGroup>();
            flow.cellSize = new Vector2(150, 24);
            flow.spacing = new Vector2(4, 4);
            wrap.FitContent();
            foreach (var c in sweep.Contributors)
            {
                var chip = Ui.Card(wrap, Color.black.WithAlpha(0.5f), 6, null, 0, Ui.Pad(6, 1), 0, true, "Contributor");
                var cell = Ui.HStack(chip, 4, null, TextAnchor.MiddleLeft, false);
                Ui.Text(cell, $"{c.Name} {(c.Reason == "bust" ? Loc.T("gameBusted") : Loc.T("gameLost"))}", 13,
                    Theme.TextPrimary.WithAlpha(0.6f), FontKind.Mono, TextAlignmentOptions.Left, false);
                Ui.Text(cell, "−$" + TableCatalog.FormatChips(c.Amount), 13, Theme.LoseLight, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            }
        }
    }

    /// <summary>Pulses an image's alpha (the "waiting" dot).</summary>
    public sealed class PulseAlpha : MonoBehaviour
    {
        private Image _image;
        private void Awake() => _image = GetComponent<Image>();
        private void Update()
        {
            var t = Mathf.PingPong(Time.unscaledTime / 1.2f, 1f);
            var c = _image.color; c.a = Mathf.Lerp(0.35f, 1f, t); _image.color = c;
        }
    }
}
