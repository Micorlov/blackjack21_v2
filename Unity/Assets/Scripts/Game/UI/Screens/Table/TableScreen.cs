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
        private const float HeaderHeight = 64f;
        private const float PanelShare = 0.62f;
        private const float SheetShare = 0.6f;
        private const float PhaseLineHeight = 28f;
        private const float HeaderIcon = 20f;
        private static readonly Color HeaderRing = Theme.Gold.WithAlpha(0.3f);

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
            // The room around the table: warm light from above, out-of-focus lamps, falling to near black.
            var bg = W.Raw(Root, Gfx.Room(), "Background");
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

        public override void Dispose()
        {
            _felt?.Dispose();
            base.Dispose();
        }

        public override void Tick()
        {
            _felt.Tick();
            if (_state == null) return;
            // The controls are capped at a share of the screen and scroll from the bottom if they ever outgrow it.
            var total = _content.rect.height;
            var settled = _state.Round.Phase == RoundPhase.Settlement;
            var height = Mathf.Min(LayoutUtility.GetPreferredHeight(_panelScrollRect.content), total * (settled ? SheetShare : PanelShare));
            var layout = _panelScroll.Ensure<LayoutElement>();
            layout.preferredHeight = height;
            // The result sheet lies over the felt, as on the design: the table keeps its full size behind it.
            if (layout.ignoreLayout != settled)
            {
                layout.ignoreLayout = settled;
                LayoutRebuilder.MarkLayoutForRebuild(_content);
            }
            if (!settled) return;
            _panelScroll.anchorMin = new Vector2(0, 0);
            _panelScroll.anchorMax = new Vector2(1, 0);
            _panelScroll.pivot = new Vector2(0.5f, 0);
            _panelScroll.anchoredPosition = Vector2.zero;
            _panelScroll.sizeDelta = new Vector2(0, height);
        }

        // ---- header ---------------------------------------------------------------------------------

        private void BuildHeader(RectTransform host, AppState s)
        {
            var r = s.Round;
            var stake = r.Stake;
            var row = Ui.HStack(host, Theme.Sm, Ui.Pad(Theme.Md, Theme.Sm), TextAnchor.MiddleCenter, false, "HeaderRow");
            row.Fill();
            W.CircleIconButton(row, "chevron_left", G.ExitTable, HeaderIcon + Theme.Xs, Theme.Gold, HeaderRing);

            var col = Ui.VStack(row, 0, null, TextAnchor.MiddleCenter, true);
            col.FlexW();
            var title = stake?.Key switch
            {
                "bronze" => Loc.T("gameBronzeTable"),
                "silver" => Loc.T("gameSilverTable"),
                "vip" => Loc.T("gameVipTable"),
                _ => stake?.Name ?? "",
            };
            Ui.Text(col, title, Type.H2, Theme.Ivory, TextAlignmentOptions.Center, false).Shrink();
            if (stake != null)
                Ui.Text(col, $"${TableCatalog.FormatChips(stake.Min)} – ${TableCatalog.FormatChips(stake.Max)}", Type.Numeral(Type.Floor, bold: false),
                    Theme.Gold, TextAlignmentOptions.Center, false);

            W.CircleIconButton(row, "chat", G.ToggleTableChat, HeaderIcon, Theme.Gold, HeaderRing);
            W.CircleIconButton(row, "more_vert", G.ToggleTableMenu, HeaderIcon, Theme.Gold, HeaderRing);
            _headerHost.Size(null, HeaderHeight);
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
                RoundPhase.Npcs or RoundPhase.NpcsAfter => Loc.T("gameSeatPlaying", ("name", ActingName(s))),
                RoundPhase.Playing => split
                    ? Loc.T("gameSplitTurn", ("hand", r.ActiveHandIndex + 1), ("total", r.Hands.Count))
                    : Loc.T("gameYourTurn"),
                RoundPhase.Dealer => Loc.T("gameDealerPlaying"),
                _ => Loc.T("gameRoundResult"),
            };
            // One quiet line naming the moment, in sentence case: the felt itself shows whose turn it is.
            var line = Ui.HStack(host, 0, null, TextAnchor.MiddleCenter, false, "PhaseLine");
            line.Fill();
            var row = FeltBits.Pill(line, Color.black.WithAlpha(0.55f), out _, Theme.Gold.WithAlpha(0.35f), "Phase", Theme.Md, Theme.Xxs);
            Ui.Text(row, label, Type.Caption, Theme.Gold, TextAlignmentOptions.Center, false).Shrink();
            _bannerHost.Size(null, PhaseLineHeight);
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
