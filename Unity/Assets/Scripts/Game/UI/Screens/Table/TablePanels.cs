using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The Seat's controls under the felt, one panel per phase: the chip row while betting, the insurance offer,
    /// the hero's moves with the turn clock, the turn order and quick chat while others play, and the result
    /// sheet. Each is rebuilt only when what it shows changes.
    /// </summary>
    public sealed class TablePanels
    {
        private const float DebounceSeconds = 0.25f;
        private const float ChipSize = 52f;
        private const float AllInWidth = 88f;
        private const int QuickReactions = 2;

        private static readonly Color InfoFill = Color.black.WithAlpha(0.4f);
        private static readonly Color InfoBorder = Theme.Gold.WithAlpha(0.35f);
        private static readonly Color ChipBorder = Theme.Ivory.WithAlpha(0.5f);
        private static readonly Color SheetFill = Theme.Hex(0xFF1E0D06);

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
                case RoundPhase.Betting: _dyn.Update(BettingSignature(s), h => Betting(h, s)); break;
                case RoundPhase.Insurance: _dyn.Update($"ins{r.InsuranceBet}|{Loc.Code}", h => Insurance(h, s)); break;
                case RoundPhase.Playing: _dyn.Update(PlayingSignature(s), h => Playing(h, s)); break;
                case RoundPhase.Npcs:
                case RoundPhase.NpcsAfter:
                case RoundPhase.Dealer: _dyn.Update(WaitingSignature(s), h => Waiting(h, s)); break;
                case RoundPhase.Settlement: _dyn.Update(SettlementSignature(s), h => Settlement(h, s)); break;
            }
        }

        private Action Debounced(Action a) => () =>
        {
            if (Time.unscaledTime - _lastAction < DebounceSeconds) return;
            _lastAction = Time.unscaledTime;
            a();
        };

        private static string Money(int amount) => "$" + TableCatalog.FormatChips(amount);

        private static RectTransform Column(RectTransform host, string name) =>
            Ui.VStack(host, Theme.Sm, null, TextAnchor.UpperCenter, true, name);

        private static RectTransform Pair(RectTransform parent, float gap = Theme.Md) =>
            Ui.HStack(parent, gap, null, TextAnchor.MiddleCenter, true, "Buttons");

        // ---- betting --------------------------------------------------------------------------------

        private static string BettingSignature(AppState s)
        {
            var r = s.Round;
            var rebuyReady = Core.Rebuy.IsReady(s.LastRebuyAt, DateTime.Now);
            return $"bet{r.Bet}|{r.Chips}|{r.Stake?.Key}|{r.LastBet}|{s.FriendsAreLive}|{rebuyReady}|{Loc.Code}";
        }

        private void Betting(RectTransform host, AppState s)
        {
            var r = s.Round;
            var stake = r.Stake;
            var tableMin = stake?.Min ?? 0;
            int? tableMax = stake?.Max;
            var belowMin = r.Bet < tableMin;
            var dealDisabled = !(r.Bet > 0 && r.Bet <= r.Chips) || belowMin;
            var canAllIn = r.Chips >= tableMin && r.Bet < r.Chips && (tableMax == null || r.Bet < tableMax);
            var canRebet = r.Bet == 0 && r.LastBet > 0 && r.LastBet <= r.Chips && r.LastBet >= tableMin
                           && (tableMax == null || r.LastBet <= tableMax);

            var col = Column(host, "Betting");
            var line = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleLeft, false, "BetLine");
            Ui.Text(line, Loc.T("gameBet"), new TextStyle(13, FontKind.SoraSemiBold), Theme.Gold, TextAlignmentOptions.Left, false);
            Ui.Text(line, Money(r.Bet), Type.Numeral(20), Theme.Gold, TextAlignmentOptions.Left, false);
            var hint = Ui.Text(line, belowMin ? Loc.T("gameMinimum", ("amount", Money(tableMin))) : "", Type.Numeral(Type.Floor, bold: false),
                Theme.TextBody, TextAlignmentOptions.Left, false);
            hint.rectTransform.FlexW();
            W.OutlineChip(line, Loc.T("gameAllIn"), _g.BetAllIn, Theme.Gold.WithAlpha(0.6f), Color.clear, Theme.Gold, 14, FontKind.SoraBold,
                AllInWidth, canAllIn);

            var chips = Ui.HStack(col, 0, null, TextAnchor.MiddleCenter, true, "Chips");
            foreach (var d in TableCatalog.ChipDenomsFor(stake))
            {
                var disabled = r.Bet + d > r.Chips || (tableMax != null && r.Bet + d > tableMax);
                var amount = d;
                Ui.Spacer(chips, 0, 1);
                W.ChipButton(chips, d, Theme.ChipColor(d), disabled, () => _g.PlaceBet(amount), ChipSize);
            }
            Ui.Spacer(chips, 0, 1);

            var buttons = Pair(col);
            W.SeatButton(buttons, Loc.T("gameClear"), null, W.Finish.Leather, _g.ClearBet).FlexW();
            var deal = canRebet
                ? W.SeatButton(buttons, Loc.T("gameRebet", ("amount", Money(r.LastBet))), null, W.Finish.Gold, _g.RebetAndDeal)
                : W.SeatButton(buttons, Loc.T("gameDeal"), null, W.Finish.Gold, _g.DealRound, !dealDisabled);
            deal.FlexW();

            // Practice bots fill the empty seats; say so once, quietly.
            if (!s.FriendsAreLive)
            {
                var wrap = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter, false, "Practice");
                Ui.Text(wrap, Loc.T("gamePracticeBots"), Type.BodySm, Theme.TextBody, TextAlignmentOptions.Center, false);
                W.TextLink(wrap, Loc.T("gameInvite"), _g.ShareInviteWhatsApp, Theme.Gold, 15);
            }

            // Below the table minimum the rebuy must appear before the stack hits zero.
            if (r.Chips >= (stake?.Min ?? TableCatalog.StartingChips)) return;
            var ready = Core.Rebuy.IsReady(s.LastRebuyAt, DateTime.Now);
            W.SeatButton(col, ready ? Loc.T("rebuyButtonLabel", ("chips", 1000)) : Loc.T("gameChipOptions"), null, W.Finish.Gold,
                ready ? (Action)_g.Rebuy : () => OutOfChipsSheet.Show(_g, _overlays), true, W.SeatButtonShort);
            W.TextLink(col, Loc.T("gameChipOptions"), () => OutOfChipsSheet.Show(_g, _overlays), Theme.Gold, 15);
        }

        // ---- insurance ------------------------------------------------------------------------------

        private void Insurance(RectTransform host, AppState s)
        {
            var col = Column(host, "Insurance");
            var info = Ui.Card(col, InfoFill, Theme.RadiusMd, InfoBorder, 1, Ui.Pad(Theme.Md, Theme.Sm), Theme.Xs, true, "Offer");
            Ui.Text(info, Loc.T("gameInsuranceOffer", ("amount", Money(s.Round.InsuranceBet))), Type.Body, Theme.Ivory);
            // Declining carries the primary weight and insuring is the considered opt-in: insurance is a losing bet.
            var buttons = Pair(col);
            W.SeatButton(buttons, Loc.T("gameInsure"), Money(s.Round.InsuranceBet), W.Finish.Leather, _g.TakeInsurance).FlexW();
            W.SeatButton(buttons, Loc.T("gameNoThanks"), null, W.Finish.Gold, _g.DeclineInsurance).FlexW();
        }

        // ---- playing --------------------------------------------------------------------------------

        private static string PlayingSignature(AppState s)
        {
            var r = s.Round;
            return $"play{RoundEngine.CanDouble(r)}{RoundEngine.CanSplit(r)}{RoundEngine.CanSurrender(r)}|{r.ActiveHandIndex}|{r.Hands.Count}"
                   + $"|{r.ActiveHand.Bet}|{r.ActiveHand.Doubled}|{Loc.Code}";
        }

        private void Playing(RectTransform host, AppState s)
        {
            var r = s.Round;
            var hand = r.ActiveHand;
            var split = r.Hands.Count > 1;
            var col = Column(host, "Playing");
            var label = hand.Doubled
                ? Loc.T("turnDoubled", ("total", BlackjackRules.HandValue(hand.Cards)))
                : split ? Loc.T("turnHandOf", ("hand", r.ActiveHandIndex + 1), ("total", r.Hands.Count)) : Loc.T("gameYourTurn");
            TurnTimerView.Build(col, _g, label, hand.Doubled ? Loc.T("turnStandsAutomatically") : "");

            var moves = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter, true, "Moves");
            var bet = Money(hand.Bet);
            var canDouble = RoundEngine.CanDouble(r);
            var canSplit = RoundEngine.CanSplit(r);
            var canSurrender = RoundEngine.CanSurrender(r);
            W.SeatButton(moves, Loc.T("gameDouble"), Loc.T("actionAdd", ("amount", bet)), W.Finish.Felt, Debounced(_g.PlayerDouble),
                canDouble, W.SeatButtonShort).FlexW(1.2f);
            W.SeatButton(moves, Loc.T("gameSplit"),
                canSplit ? Loc.T("actionAdd", ("amount", bet)) : split ? Loc.T("actionOnceOnly") : Loc.T("actionPairsOnly"),
                W.Finish.Felt, Debounced(_g.PlayerSplit), canSplit, W.SeatButtonShort).FlexW(1f);
            W.SeatButton(moves, Loc.T("gameSurrender"),
                canSurrender ? Loc.T("actionKeep", ("amount", Money(hand.Bet / 2))) : split ? Loc.T("actionNotAfterSplit") : Loc.T("actionTwoCardsOnly"),
                W.Finish.Loss, Debounced(_g.PlayerSurrender), canSurrender, W.SeatButtonShort).FlexW(1f);

            // Equal halves, deliberately: neither move is right for every hand, so neither gets extra weight.
            var buttons = Pair(col);
            W.SeatButton(buttons, Loc.T("gameStand"), null, W.Finish.Leather, Debounced(_g.PlayerStand)).FlexW();
            W.SeatButton(buttons, Loc.T("gameHit"), null, W.Finish.Gold, Debounced(_g.PlayerHit)).FlexW();
        }

        // ---- waiting --------------------------------------------------------------------------------

        private static string StandingsSignature(AppState s) =>
            s.FriendsAreLive ? string.Join(",", s.Friends.Select(f => f.Id + f.HourlyScore)) + s.HeroHourlyPoints : "";

        private static string WaitingSignature(AppState s)
        {
            var r = s.Round;
            var seats = string.Join(",", r.NpcSeats.Select(n => n.Done ? "d" : "-"));
            var dealer = r.Phase == RoundPhase.Dealer ? TableCalc.DealerTotalLabel(r) : "";
            return $"wait{r.Phase}|{r.ActingSeat}|{seats}|{dealer}|{StandingsSignature(s)}|{Loc.Code}";
        }

        private static string ActingName(AppState s)
        {
            var seats = Roster.TableSeats(s.Friends, s.Round.Stake?.Key);
            var seat = s.Round.ActingSeat;
            return seat == null || seat.Value >= seats.Count ? Loc.Or("theTable", "The table") : seats[seat.Value].FirstName;
        }

        private void Waiting(RectTransform host, AppState s)
        {
            var r = s.Round;
            var col = Column(host, "Waiting");
            if (r.Phase == RoundPhase.Dealer) DealerNote(col, r);
            else TurnTimerView.Build(col, _g, Loc.T("gameSeatPlaying", ("name", ActingName(s))),
                r.Phase == RoundPhase.Npcs ? Loc.T("turnYouPlayThird") : "");
            TurnOrder(col, s);
            QuickChat(col);
            if (s.FriendsAreLive) Standings(col, s);
        }

        /// <summary>What the dealer is doing and why: it must draw to 16 and stands on all 17s.</summary>
        private static void DealerNote(RectTransform col, RoundState r)
        {
            var info = Ui.Card(col, InfoFill, Theme.RadiusMd, InfoBorder, 1, Ui.Pad(Theme.Md, Theme.Sm), Theme.Xxs, true, "DealerNote");
            info.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            var total = BlackjackRules.HandValue(r.DealerHand);
            var line = !r.HoleRevealed ? Loc.T("gameDealerPlaying")
                : RoundEngine.DealerShouldHit(r.DealerHand) ? Loc.T("dealerMustDraw", ("total", total))
                : Loc.T("dealerStandsOn", ("total", total));
            Ui.Text(info, line, Type.Body, Theme.Ivory, TextAlignmentOptions.Center);
            Ui.Text(info, Loc.T("dealerRule"), Type.Caption.WithFont(FontKind.Sora), Theme.TextBody, TextAlignmentOptions.Center);
        }

        /// <summary>Who plays in what order, in casino order with the hero in the middle chair.</summary>
        private static void TurnOrder(RectTransform col, AppState s)
        {
            var r = s.Round;
            var seats = Roster.TableSeats(s.Friends, r.Stake?.Key);
            var row = Ui.HStack(col, Theme.Xs, null, TextAnchor.MiddleCenter, false, "Order");
            var heroDone = r.Phase == RoundPhase.NpcsAfter || r.Phase == RoundPhase.Dealer;
            for (var i = 0; i < r.NpcSeats.Count; i++)
            {
                if (i == TableCatalog.SeatsBeforeHero) OrderChip(row, Loc.T("orderYou"), heroDone, false, true);
                var name = i < seats.Count ? seats[i].FirstName : "";
                OrderChip(row, name, r.NpcSeats[i].Done, r.ActingSeat == i, false);
            }
            if (r.NpcSeats.Count <= TableCatalog.SeatsBeforeHero) OrderChip(row, Loc.T("orderYou"), heroDone, false, true);
        }

        private static void OrderChip(RectTransform row, string name, bool done, bool now, bool me)
        {
            var fill = now ? Theme.Gold : Color.clear;
            var border = now ? Theme.Gold : me ? Theme.Gold.WithAlpha(0.6f) : Theme.Ivory.WithAlpha(0.3f);
            var ink = now ? Theme.PillInk : me ? Theme.Gold : done ? Theme.TextFaintOnPanel : Theme.TextBody;
            var pill = FeltBits.Pill(row, fill, out _, border, "Turn", Theme.Sm, Theme.Xs);
            Ui.Text(pill, done && !now ? "<s>" + name + "</s>" : name, new TextStyle(Type.Floor, FontKind.SoraSemiBold), ink,
                TextAlignmentOptions.Center, false);
        }

        /// <summary>Two canned reactions and the way into the table chat, each a full 48-unit target.</summary>
        private void QuickChat(RectTransform col)
        {
            var row = Ui.HStack(col, Theme.Sm, null, TextAnchor.MiddleCenter, false, "QuickChat");
            foreach (var reaction in GameController.Reactions.Take(QuickReactions))
            {
                var label = reaction;
                W.OutlineChip(row, label, () => _g.SendChatMessage(label), ChipBorder, Color.white.WithAlpha(0.08f), Theme.Ivory);
            }
            W.OutlineChip(row, Loc.T("chatShort"), _g.ToggleTableChat, ChipBorder, Color.white.WithAlpha(0.08f), Theme.Ivory);
        }

        private static void Standings(RectTransform parent, AppState s)
        {
            var hero = Points.Rolled(s.HeroHourlyPoints, s.HeroHourKey, Points.HourKeyOf(DateTime.Now));
            var rows = new List<(string name, int points, bool self)> { (Loc.T("orderYou"), hero, true) };
            rows.AddRange(s.Friends.Select(f => (f.FirstName, f.HourlyScore, false)));
            rows = rows.OrderByDescending(x => x.points).ToList();
            var visible = rows.Select((x, i) => (rank: i + 1, row: x)).ToList();
            var selfIdx = visible.FindIndex(e => e.row.self);
            if (visible.Count > 5)
                visible = selfIdx >= 5 ? visible.Take(4).Append(visible[selfIdx]).ToList() : visible.Take(5).ToList();

            var card = Ui.Card(parent, InfoFill, Theme.RadiusMd, Color.white.WithAlpha(0.1f), 1, Ui.Pad(Theme.Md, Theme.Sm), Theme.Xxs, true, "Standings");
            Ui.Text(card, Loc.Or("friendsThisHour", "Friends this hour"), Type.Caption, Theme.TextBody);
            foreach (var e in visible)
            {
                var row = Ui.HStack(card, Theme.Xs, null, TextAnchor.MiddleLeft, false);
                Ui.Text(row, "#" + e.rank, Type.Numeral(13), Theme.TextBody, TextAlignmentOptions.Left, false).rectTransform.Size(Theme.Xxxl);
                var name = Ui.Text(row, e.row.name, Type.Caption.WithFont(e.row.self ? FontKind.SoraBold : FontKind.SoraSemiBold),
                    e.row.self ? Theme.Gold : Theme.Ivory, TextAlignmentOptions.Left, false);
                name.Shrink();
                name.rectTransform.FlexW();
                Ui.Text(row, (e.row.points >= 0 ? "+" : "-") + Money(Mathf.Abs(e.row.points)), Type.Numeral(Type.Floor),
                    e.row.points >= 0 ? Theme.WinLight : Theme.LoseOnPanel, TextAlignmentOptions.Right, false);
            }
        }

        // ---- settlement -----------------------------------------------------------------------------

        private static string SettlementSignature(AppState s)
        {
            var r = s.Round;
            return $"set{r.Stats.HandsPlayed}|{r.Message}|{r.RoundNet}|{r.SweepAmount}|{r.Chips}|{Loc.Code}";
        }

        /// <summary>The result sheet: the outcome and the figure the player came for, then where it came from.</summary>
        private void Settlement(RectTransform host, AppState s)
        {
            var r = s.Round;
            var netColour = r.RoundNet > 0 ? Theme.WinLight : r.RoundNet < 0 ? Theme.LoseOnPanel : Theme.Ivory;
            var resultKey = Guide.ResultKey(r.Message);

            var sheet = Ui.Card(host, SheetFill, Theme.RadiusXxl, Theme.Gold, 1.5f, Ui.Pad(Theme.Xl, Theme.Lg, Theme.Xl, Theme.Xl), Theme.Xs, true, "Sheet");
            var head = Ui.HStack(sheet, Theme.Md, null, TextAnchor.MiddleLeft, false, "Head");
            var title = Ui.Text(head, resultKey != null ? Loc.T(resultKey) : r.Message, Type.H2, Theme.Ivory, TextAlignmentOptions.Left, true);
            title.rectTransform.FlexW();
            var net = Ui.Text(head, "", Type.Numeral(26), netColour, TextAlignmentOptions.Right, false);
            CountUpText.Make(net, r.RoundNet, "$", true, () => { if (s.HapticsOn) _g.Services.Haptics.Selection(); });
            Ui.Spacer(sheet, Theme.Xs);

            Line(sheet, Loc.T("gameYouBet"), Money(r.RoundStake), Theme.Ivory, null);
            Line(sheet, Loc.T("gameAgainstDealer"), (r.RoundHandNet >= 0 ? "+" : "−") + Money(Mathf.Abs(r.RoundHandNet)),
                r.RoundHandNet > 0 ? Theme.WinLight : r.RoundHandNet < 0 ? Theme.LoseOnPanel : Theme.Ivory, null);
            if (r.SweepAmount > 0) Line(sheet, Loc.T("gameSweepPot"), "+" + Money(r.SweepAmount), Theme.Gold, Theme.Gold);
            Line(sheet, Loc.T("gameBalance"), Money(r.Chips), Theme.Ivory, null, last: true);
            Ui.Spacer(sheet, Theme.Sm);
            W.SeatButton(sheet, Loc.T("gameNextHand"), null, W.Finish.Gold, _g.NextHand, true, W.SeatButtonShort + Theme.Xs);
        }

        private static void Line(RectTransform parent, string label, string value, Color valueColour, Color? labelColour, bool last = false)
        {
            var row = Ui.HStack(parent, Theme.Sm, Ui.Pad(0, Theme.Xs), TextAnchor.MiddleLeft, false, "Line");
            var l = Ui.Text(row, label, new TextStyle(14, FontKind.Sora), labelColour ?? Theme.TextBody, TextAlignmentOptions.Left, false);
            l.rectTransform.FlexW();
            Ui.Text(row, value, Type.Numeral(14), valueColour, TextAlignmentOptions.Right, false);
            if (!last) W.Divider(parent, Theme.Ivory.WithAlpha(0.08f));
        }
    }
}
