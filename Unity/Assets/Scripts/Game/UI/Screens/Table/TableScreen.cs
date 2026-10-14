using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The table: header, phase banner, the felt, and the action panel for whichever phase is live.</summary>
    public sealed class TableScreen : ScreenView
    {
        private static readonly RoundPhase[] PhaseOrder =
        {
            RoundPhase.Betting, RoundPhase.Npcs, RoundPhase.Playing, RoundPhase.Dealer, RoundPhase.Settlement,
        };

        private RectTransform _headerHost, _bannerHost, _panelScroll, _panelHost, _coachHost, _menuHost, _chatHost;
        private ScrollRect _panelScrollRect;
        private Dyn _header, _banner, _coach, _menu, _chat;
        private FeltView _felt;
        private TablePanels _panels;
        private RectTransform _content;
        private float _availableHeight;
        private AppState _state;

        public TableScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("TableScreen", parent).Fill();
            var bg = W.Raw(Root, Gfx.RadialCircular("tableBg", 96, 208, new Vector2(0, 0.92f), 1.3f,
                new[] { Theme.FeltTableMid, Theme.FeltTableDark, Theme.Hex(0xFF05100C) }, new[] { 0f, 0.45f, 1f }), "Background");
            bg.rectTransform.Fill();

            _content = Ui.VStack(Root, 0, null, TextAnchor.UpperCenter, true, "Content").Fill();
            _headerHost = Ui.Node("Header", _content);
            _header = new Dyn(_headerHost);
            _bannerHost = Ui.Node("Banner", _content);
            _banner = new Dyn(_bannerHost);

            _felt = new FeltView(G);
            _felt.Build(_content);

            // The bottom panel is content-sized but capped, and scrolls from the bottom if it ever outgrows the cap.
            _panelScroll = W.Scroll(_content, null, 0, true, true, out _panelScrollRect);
            _panelScroll.Ensure<LayoutElement>().flexibleHeight = 0;
            _panelHost = Ui.VStack(_panelScrollRect.content, 0, Ui.Pad(14, 8, 14, 12), TextAnchor.UpperCenter, true, "Panel");
            _coachHost = Ui.VStack(_panelHost, 0, null, TextAnchor.UpperLeft, true, "Coach");
            _coach = new Dyn(_coachHost);
            var phaseHost = Ui.VStack(_panelHost, 0, null, TextAnchor.UpperLeft, true, "Phase");
            _panels = new TablePanels(G, Overlays, phaseHost);

            _menuHost = Ui.Node("Menu", Root).Fill();
            _menu = new Dyn(_menuHost);
            _chatHost = Ui.Node("Chat", Root).Fill();
            _chat = new Dyn(_chatHost);
        }

        public override void Refresh(AppState s)
        {
            _state = s;
            var r = s.Round;
            _header.Update($"{r.Stake?.Key}|{s.TableChatOpen}|{s.TableMenuOpen}|{Loc.Code}", h => BuildHeader(h, s));
            _banner.Update($"{r.Phase}|{r.ActingSeat}|{r.ActiveHandIndex}|{r.Hands.Count}|{Loc.Code}|{s.Friends.Count}", h => BuildBanner(h, s));
            _felt.Refresh(s);
            _coach.Update($"{s.TutorialRoundsSeen}|{s.TutorialDismissed}|{r.Phase}|{Loc.Code}|{r.Stake?.Key}", h => CoachCard.Build(h, s, G, Overlays));
            _panels.Refresh(s);
            _menu.Update("menu" + s.TableMenuOpen, h => { if (s.TableMenuOpen) BuildMenu(h); });
            _chat.Update($"chat{s.TableChatOpen}|{string.Join(",", s.ChatMessages.Select(m => m.Id))}", h => { if (s.TableChatOpen) BuildChat(h, s); });
        }

        public override void Tick()
        {
            _felt.Tick();
            // Cap the panel at a share of the screen: the result card gets more, because the felt gives way to it.
            if (_state == null) return;
            var total = _content.rect.height;
            var share = _state.Round.Phase == RoundPhase.Settlement ? 0.72f : 0.62f;
            var preferred = LayoutUtility.GetPreferredHeight(_panelScrollRect.content);
            _panelScroll.Ensure<LayoutElement>().preferredHeight = Mathf.Min(preferred, total * share);
        }

        // ---- header ---------------------------------------------------------------------------------

        private void BuildHeader(RectTransform host, AppState s)
        {
            var r = s.Round;
            var stake = r.Stake;
            var row = Ui.HStack(host, Theme.Sm, Ui.Pad(TableLayout.GutterOf(412), (int)Theme.Xxs, TableLayout.GutterOf(412), (int)Theme.Xs),
                TextAnchor.MiddleCenter, false, "HeaderRow");
            row.Fill();
            W.CircleIconButton(row, "chevron_left", G.ExitTable, 28);

            var col = Ui.VStack(row, 0, null, TextAnchor.MiddleCenter, true);
            col.FlexW();
            var title = stake?.Key switch
            {
                "bronze" => Loc.T("gameBronzeTable"),
                "silver" => Loc.T("gameSilverTable"),
                "vip" => Loc.T("gameVipTable"),
                _ => stake?.Name ?? "",
            };
            Ui.Text(col, title, 24, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Center, false).overflowMode = TextOverflowModes.Ellipsis;
            if (stake != null)
                Ui.Text(col, $"${TableCatalog.FormatChips(stake.Min)}–${TableCatalog.FormatChips(stake.Max)} · 3:2", 17,
                    Theme.TextPrimary.WithAlpha(0.82f), FontKind.Mono, TextAlignmentOptions.Center, false);

            W.CircleIconButton(row, "chat", G.ToggleTableChat, 24);
            W.CircleIconButton(row, "more_vert", G.ToggleTableMenu, 24);
            // Header height = tallest child (48) + padding.
            _headerHost.Size(null, 64);
        }

        // ---- phase banner ---------------------------------------------------------------------------

        private string ActingName(AppState s)
        {
            var seats = Roster.TableSeats(s.Friends, s.Round.Stake?.Key);
            var seat = s.Round.ActingSeat;
            return seat == null || seat.Value >= seats.Count ? Loc.Or("theTable", "The table") : seats[seat.Value].FirstName;
        }

        private void BuildBanner(RectTransform host, AppState s)
        {
            var r = s.Round;
            var split = r.Hands.Count > 1;
            var label = r.Phase switch
            {
                RoundPhase.Betting => Loc.T("gamePlaceBet"),
                RoundPhase.Insurance => Loc.T("gameInsuranceOffered"),
                RoundPhase.Npcs => Loc.T("gameSeatPlaying", ("name", ActingName(s))),
                RoundPhase.Playing => split
                    ? Loc.T("gameSplitTurn", ("hand", r.ActiveHandIndex + 1), ("total", r.Hands.Count))
                    : Loc.T("gameYourTurn"),
                RoundPhase.Dealer => Loc.T("gameDealerPlaying"),
                _ => Loc.T("gameRoundResult"),
            };
            // Betting and insurance are the player's move as much as `playing` is.
            var heroTurn = r.Phase == RoundPhase.Playing || r.Phase == RoundPhase.Betting || r.Phase == RoundPhase.Insurance;
            var current = r.Phase == RoundPhase.Insurance ? RoundPhase.Npcs : r.Phase;
            var curIdx = Mathf.Clamp(System.Array.IndexOf(PhaseOrder, current), 0, PhaseOrder.Length - 1);

            var gutter = TableLayout.GutterOf(412);
            var col = Ui.VStack(host, Theme.Xs, Ui.Pad(gutter, 0, gutter, Theme.Xs), TextAnchor.UpperCenter, true);
            col.Fill();
            var pillRow = Ui.HStack(col, 0, null, TextAnchor.MiddleCenter, false, "HeadlineRow");
            var pill = Ui.Card(pillRow, heroTurn ? Theme.Gold : Color.black.WithAlpha(0.42f), Theme.RadiusPill,
                heroTurn ? Theme.Gold : Theme.Gold.WithAlpha(0.3f), 1, Ui.Pad(Theme.Lg, Theme.Xs + Theme.Xxs), 0, false, "Headline");
            pill.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            var t = Ui.Text(pill, label, 18, heroTurn ? Theme.GoldInk : Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Center, false, 0.4f);
            t.overflowMode = TextOverflowModes.Ellipsis;

            var track = Ui.HStack(col, Theme.Xs, null, TextAnchor.MiddleCenter, true);
            track.Size(null, 6);
            for (var i = 0; i < PhaseOrder.Length; i++)
            {
                var seg = Ui.Box(track, i == curIdx ? Theme.Gold : i < curIdx ? Theme.Gold.WithAlpha(0.45f) : Theme.TextPrimary.WithAlpha(0.18f),
                    Theme.RadiusPill, "Step");
                seg.rectTransform.FlexW();
                seg.rectTransform.Size(null, 6);
            }
            _bannerHost.Size(null, 56);
        }

        // ---- menu and chat ----------------------------------------------------------------------------

        private void BuildMenu(RectTransform host)
        {
            var scrim = Ui.Box(host, Color.clear, 0, "Scrim");
            scrim.rectTransform.Fill();
            scrim.raycastTarget = true;
            scrim.rectTransform.MakePressable(G.ToggleTableMenu);

            var card = Ui.Card(host, Theme.NavSurface, Theme.RadiusMd, Color.white.WithAlpha(0.1f), 1, Ui.Pad(Theme.Lg, Theme.Sm), 0, false, "MenuItem");
            var outer = (RectTransform)card.parent;
            outer.anchorMin = outer.anchorMax = new Vector2(1, 1);
            outer.pivot = new Vector2(1, 1);
            outer.anchoredPosition = new Vector2(-TableLayout.GutterOf(412), -50);
            outer.FitContent(true, true);
            outer.MinSize(null, Theme.MinTarget);
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            Ui.Text(card, Loc.Or("leaveTable", "Leave Table"), 19, Theme.LoseSoft, FontKind.Sora, TextAlignmentOptions.Center, false);
            outer.MakePressable(G.ExitTable);
            outer.GetComponent<Image>().raycastTarget = true;
        }

        private void BuildChat(RectTransform host, AppState s)
        {
            var scrim = Ui.Box(host, Theme.Scrim.WithAlpha(0.5f), 0, "Scrim");
            scrim.rectTransform.Fill();
            scrim.raycastTarget = true;
            scrim.rectTransform.MakePressable(G.ToggleTableChat);

            var sheet = Ui.Card(host, Theme.Surface, 24, Theme.Gold.WithAlpha(0.3f), 1, Ui.Pad(16, 10, 16, 22), 0, true, "Sheet");
            var outer = (RectTransform)sheet.parent;
            outer.anchorMin = new Vector2(0, 0); outer.anchorMax = new Vector2(1, 0); outer.pivot = new Vector2(0.5f, 0);
            outer.offsetMin = outer.offsetMax = Vector2.zero;
            outer.FitContent();
            outer.GetComponent<Image>().raycastTarget = true;
            sheet.GetComponent<Image>().raycastTarget = true;

            var grip = Ui.Box(sheet, Theme.Border, 2, "Grip");
            grip.rectTransform.Size(40, 4);
            sheet.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            Ui.Spacer(sheet, 10);

            var atTable = Roster.TableSeats(s.Friends, s.Round.Stake?.Key).Count + 1;
            var head = Ui.HStack(sheet, Theme.Sm, null, TextAnchor.LowerLeft, false);
            Ui.Text(head, Loc.Or("tableChat", "Table chat"), 26, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Left, false);
            Ui.Text(head, Loc.Or("atTheTable", "{n} at the table", ("n", atTable)), 13, Theme.TextFaint, FontKind.Mono, TextAlignmentOptions.Left, false);
            Ui.Spacer(sheet, 12);

            var list = Ui.VStack(sheet, 10, null, TextAnchor.UpperLeft, true, "Messages");
            if (s.ChatMessages.Count == 0)
                Ui.Text(list, Loc.Or("noTableTalk", "No table talk yet — say GG below."), 14, Theme.TextFaint, FontKind.Sora, TextAlignmentOptions.Center, true);
            foreach (var m in s.ChatMessages) ChatBubble(list, m);
            Ui.Spacer(sheet, 6);

            var pills = Ui.HStack(sheet, Theme.Sm, null, TextAnchor.MiddleCenter, false);
            foreach (var label in GameController.Reactions)
            {
                var reaction = label;
                var pill = Ui.Card(pills, Theme.Gold.WithAlpha(0.1f), Theme.RadiusPill, Theme.Gold.WithAlpha(0.35f), 1, Ui.Pad(14, 10), 0, true, "Reaction");
                var shell = (RectTransform)pill.parent;
                shell.MinSize(null, 44);
                pill.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
                Ui.Text(pill, reaction, 13, Theme.Gold, FontKind.SoraBold, TextAlignmentOptions.Center, false);
                shell.MakePressable(() => G.SendChatMessage(reaction));
                shell.GetComponent<Image>().raycastTarget = true;
            }
        }

        private static void ChatBubble(RectTransform parent, ChatMessage m)
        {
            var self = m.Name == "You";
            var row = Ui.HStack(parent, 0, null, self ? TextAnchor.MiddleRight : TextAnchor.MiddleLeft, false);
            var bubble = Ui.Card(row, self ? Theme.Gold.WithAlpha(0.14f) : Color.white.WithAlpha(0.07f), 14,
                self ? Theme.Gold.WithAlpha(0.3f) : Color.white.WithAlpha(0.1f), 1, Ui.Pad(13, 9), 2, false, "Bubble");
            Ui.Text(bubble, m.Name, 12, self ? Theme.Gold : Theme.TextFaint, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            Ui.Text(bubble, m.Text, 15, Theme.TextPrimary, FontKind.Sora, TextAlignmentOptions.Left, true);
        }
    }
}
