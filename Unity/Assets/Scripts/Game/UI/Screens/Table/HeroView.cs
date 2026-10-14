using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The hero's own place at the Seat table: the hand's total in a gold badge, 88-unit cards fanned toward the
    /// player, the bet ring with its chips, and the balance racked on the rail. A double turns the third card
    /// sideways; a split lays the two hands side by side, the one in play lit and the other dimmed.
    /// </summary>
    public sealed class HeroView
    {
        private const float W = FeltMetrics.HeroCardWidth, H = FeltMetrics.HeroCardHeight;
        // Two hands side by side only fit a 384-wide felt at the dealer's card size; ranks stay over the floor.
        private const float SplitCardWidth = FeltMetrics.CardWidth;
        private const float SplitCardHeight = FeltMetrics.CardHeight;
        private const float SplitOffset = 60f;
        private const float SplitOverlap = 0.5f;

        /// <summary>A long hand closes up rather than reaching over the lower seats.</summary>
        private const float WidestFan = 168f;
        private const float IdleAlpha = 0.8f;
        private const float BetRingWidth = 84f, BetRingHeight = 30f, BigRingWidth = 104f, BigRingHeight = 38f;
        private const float BadgeDisc = 36f;
        private const float RailStackGap = 5f;
        private const float SidewaysDrop = 20f;

        // The design's fan: each card turned a little more, the middle one lifted (CSS degrees, clockwise).
        private static readonly float[] Turn = { -5f, 4f, 9f, 13f, 16f, 18f };
        private static readonly float[] Lift = { 0f, -4f, -2f, 0f, 2f, 4f };
        private static readonly (Color colour, int count)[] RailStacks =
        {
            (Theme.ChipBlack, 5), (Theme.ChipGreen, 3), (Theme.ChipRed, 2),
        };

        private sealed class HandSlot
        {
            public RectTransform Root, Cards;
            public CardFan Fan;
            public CanvasGroup Group;
            public RawImage Glow;
        }

        private RectTransform _canvas, _badgeHost, _labelsHost, _betsHost, _rail;
        private Dyn _badge, _labels, _bets;
        private readonly List<HandSlot> _hands = new List<HandSlot>();
        private CountUpText _balance;

        public void Build(RectTransform canvas)
        {
            _canvas = canvas;
            _betsHost = Ui.Node("HeroBets", canvas).Fill();
            _bets = new Dyn(_betsHost);
            _labelsHost = Ui.Node("HandLabels", canvas).Fill();
            _labels = new Dyn(_labelsHost);
            _badgeHost = Ui.VStack(canvas, 0, null, TextAnchor.UpperCenter, false, "HeroBadge");
            _badgeHost.FitContent(true, true);
            _badge = new Dyn(_badgeHost);
            BuildRail();
        }

        /// <summary>The player's own chips racked on the rail, and the balance beside them.</summary>
        private void BuildRail()
        {
            _rail = Ui.Node("Rail", _canvas);
            _rail.sizeDelta = Vector2.zero;
            var stacks = FeltBits.ChipStacks(_rail, RailStacks);
            stacks.GetComponent<HorizontalLayoutGroup>().spacing = RailStackGap;
            stacks.At(0, 0, new Vector2(0, 0));
            var line = Ui.HStack(_rail, Theme.Xs, null, TextAnchor.MiddleLeft, false, "Balance");
            line.FitContent(true, true);
            line.At(-Theme.Xl, Theme.Xs, new Vector2(0, 1));
            Ui.Text(line, Loc.T("railBalance"), Type.Caption.WithFont(FontKind.Sora), Theme.TextBody, TextAlignmentOptions.Left, false);
            var figure = Ui.Text(line, "", Type.Numeral(14), Theme.Ivory, TextAlignmentOptions.Left, false);
            _balance = CountUpText.Make(figure, 0, "$");
        }

        public void Refresh(AppState s, FeltMetrics m)
        {
            var r = s.Round;
            var split = r.Hands.Count > 1;
            while (_hands.Count > r.Hands.Count) { Object.Destroy(_hands[_hands.Count - 1].Root.gameObject); _hands.RemoveAt(_hands.Count - 1); }
            while (_hands.Count < r.Hands.Count) _hands.Add(NewHand(_hands.Count));

            for (var i = 0; i < _hands.Count; i++)
            {
                var x = split ? m.CentreX + (i == 0 ? -SplitOffset : SplitOffset) : m.CentreX;
                var active = !split || i == r.ActiveHandIndex || r.Phase != RoundPhase.Playing;
                RefreshHand(_hands[i], r.Hands[i], x, m.Y(FeltMetrics.HeroCardsTop), split, active && split && r.Phase == RoundPhase.Playing);
                _hands[i].Group.alpha = active ? 1f : IdleAlpha;
                // A hand waiting its turn is inactive, not something to act on or read closely yet.
                _hands[i].Group.interactable = active;
            }

            _badgeHost.At(m.CentreX, m.Y(FeltMetrics.HeroBadgeTop));
            var hand = r.Hands[0];
            var badge = !split && hand.Cards.Count > 0 ? BadgeText(r, hand) : default;
            _badge.Update(badge.label == null ? "" : $"{badge.total}|{badge.label}|{badge.tone}|{Loc.Code}", host =>
            {
                if (badge.label != null) BuildBadge(host, badge.total, badge.label, badge.tone);
            });

            var labels = split ? string.Join(",", r.Hands.Select((h, i) => $"{BlackjackRules.HandValue(h.Cards)}{i == r.ActiveHandIndex}")) : "";
            _labels.Update($"{labels}|{r.Phase}|{m.CentreX:0}|{m.Y(FeltMetrics.SplitLabelTop):0}|{Loc.Code}",
                host => { if (split) BuildSplitLabels(host, r, m); });

            var bets = string.Join(",", r.Hands.Select(h => h.Bet)) + $"|{r.Bet}|{r.Phase}|{m.CentreX:0}|{m.Y(FeltMetrics.BetTop):0}|{Loc.Code}";
            _bets.Update(bets, host => BuildBets(host, r, m));

            _rail.At(m.CentreX + Theme.Space48 + Theme.Xs, m.Y(FeltMetrics.RailChipsTop) + 22f, new Vector2(0, 0));
            _balance.SetValue(r.Chips);
        }

        private HandSlot NewHand(int index)
        {
            var root = Ui.Node("Hand" + index, _canvas);
            root.SetSiblingIndex(_badgeHost.GetSiblingIndex());
            var group = root.gameObject.AddComponent<CanvasGroup>();
            var glow = FeltBits.Glow(root, W * 2.4f, Theme.Gold.WithAlpha(0.35f));
            var cards = Ui.Node("Cards", root);
            cards.anchorMin = cards.anchorMax = new Vector2(0.5f, 1f);
            cards.pivot = new Vector2(0.5f, 1f);
            return new HandSlot { Root = root, Cards = cards, Fan = new CardFan(cards), Group = group, Glow = glow };
        }

        private static void RefreshHand(HandSlot slot, Hand hand, float x, float top, bool split, bool lit)
        {
            var n = hand.Cards.Count;
            var w = split ? SplitCardWidth : W;
            var h = split ? SplitCardHeight : H;
            var sideways = hand.Doubled && n == 3;
            var inRow = sideways ? 2 : n;
            var step = w * (1f - (split ? SplitOverlap : FeltMetrics.HeroOverlap));
            if (inRow > 1) step = Mathf.Min(step, (WidestFan - w) / (inRow - 1));
            var width = w + Mathf.Max(0, inRow - 1) * step;
            slot.Root.At(x, top);
            slot.Root.sizeDelta = new Vector2(width, h);
            slot.Cards.sizeDelta = new Vector2(width, h);
            slot.Cards.anchoredPosition = Vector2.zero;
            slot.Glow.gameObject.SetActive(lit);
            // Sized to the hand, so the light stays on it and off the print above.
            slot.Glow.rectTransform.sizeDelta = Vector2.one * Mathf.Max(width, h) * 1.4f;
            if (n == 0) { slot.Fan.Clear(); return; }
            slot.Fan.Sync(hand.Cards, w, h, (card, i, count) =>
            {
                if (sideways && i == 2)
                {
                    // A double is dealt one card, sideways across the hand.
                    card.anchoredPosition = new Vector2(width / 2f, -(h / 2f + SidewaysDrop));
                    card.localRotation = Quaternion.Euler(0, 0, -90f);
                    card.SetAsLastSibling();
                    return;
                }
                var k = Mathf.Min(i, Turn.Length - 1);
                card.anchoredPosition = new Vector2(w / 2f + i * step, -h / 2f - Lift[k]);
                card.localRotation = Quaternion.Euler(0, 0, -Turn[k]);
            });
        }

        private enum Tone { Plain, Gold, Bad }

        private readonly struct Badge
        {
            public readonly string total, label;
            public readonly Tone tone;
            public Badge(string total, string label, Tone tone) { this.total = total; this.label = label; this.tone = tone; }
        }

        /// <summary>The badge over the hand: its total, and "hard", "soft", "doubled", "blackjack", "bust" or the result.</summary>
        private static Badge BadgeText(RoundState r, Hand hand)
        {
            var total = BlackjackRules.HandValue(hand.Cards).ToString();
            if (hand.Status == HandStatus.Busted) return new Badge(total, Loc.T("handBust"), Tone.Bad);
            if (hand.Status == HandStatus.Blackjack) return new Badge(total, Loc.T("handBlackjack"), Tone.Gold);
            if (hand.Status == HandStatus.Surrendered) return new Badge(total, Loc.T("handSurrendered"), Tone.Bad);
            if (r.Phase == RoundPhase.Settlement)
            {
                return r.MessageType switch
                {
                    MessageType.Win => new Badge(total, Loc.T("handYouWin"), Tone.Gold),
                    MessageType.Lose => new Badge(total, Loc.T("handLost"), Tone.Bad),
                    _ => new Badge(total, Loc.T("handPush"), Tone.Plain),
                };
            }
            if (hand.Doubled) return new Badge(total, Loc.T("handDoubled"), Tone.Plain);
            return new Badge(total, BlackjackRules.IsSoft(hand.Cards) ? Loc.T("handSoft") : Loc.T("handHard"), Tone.Plain);
        }

        private static void BuildBadge(RectTransform host, string total, string label, Tone tone)
        {
            var border = tone == Tone.Bad ? Theme.LoseOnPanel.WithAlpha(0.8f) : tone == Tone.Gold ? Theme.Gold : Theme.Gold.WithAlpha(0.6f);
            var card = Ui.Card(host, Color.black.WithAlpha(0.62f), Theme.RadiusXxl, border, 1, Ui.Pad(Theme.Xs, Theme.Xxs, Theme.Md, Theme.Xxs), 0, false, "Badge");
            var row = Ui.HStack(card, Theme.Sm, null, TextAnchor.MiddleCenter, false);
            var disc = Ui.Card(row, tone == Tone.Bad ? Theme.LoseOnPanel : Theme.Gold, Theme.RadiusPill, null, 0, Ui.Pad(Theme.Sm, 0), 0, false, "Total");
            disc.MinSize(BadgeDisc, BadgeDisc);
            disc.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            Ui.Text(disc, total, Type.Numeral(20), Theme.PillInk, TextAlignmentOptions.Center, false);
            Ui.Text(row, label, new TextStyle(14, FontKind.SoraSemiBold), Theme.Ivory, TextAlignmentOptions.Left, false);
        }

        private static void BuildSplitLabels(RectTransform host, RoundState r, FeltMetrics m)
        {
            for (var i = 0; i < r.Hands.Count; i++)
            {
                var lit = i == r.ActiveHandIndex && r.Phase == RoundPhase.Playing;
                var row = FeltBits.Pill(host, lit ? Theme.Gold : FeltBits.PillFill, out var root, lit ? (Color?)null : Theme.Gold.WithAlpha(0.45f), "Hand" + i);
                root.At(m.CentreX + (i == 0 ? -SplitOffset : SplitOffset), m.Y(FeltMetrics.SplitLabelTop));
                var ink = lit ? Theme.PillInk : Theme.Ivory;
                Ui.Text(row, Loc.T("handNumber", ("n", i + 1)), new TextStyle(13, FontKind.SoraSemiBold), ink, TextAlignmentOptions.Left, false);
                Ui.Text(row, BlackjackRules.HandValue(r.Hands[i].Cards).ToString(), Type.Numeral(16), ink, TextAlignmentOptions.Left, false);
            }
        }

        /// <summary>Each hand's bet in its ring on the felt; while betting, the stake waits in one big lit ring.</summary>
        private static void BuildBets(RectTransform host, RoundState r, FeltMetrics m)
        {
            var betting = r.Phase == RoundPhase.Betting;
            var y = m.Y(FeltMetrics.BetTop);
            if (betting)
            {
                var label = FeltBits.Pill(host, Theme.Gold, out var labelRoot, null, "YourBet", Theme.Md, Theme.Xs);
                labelRoot.At(m.CentreX, m.Y(FeltMetrics.HeroCardsTop) + Theme.Space48);
                Ui.Text(label, "$" + TableCatalog.FormatChips(r.Bet), Type.Numeral(20), Theme.PillInk, TextAlignmentOptions.Left, false);
                Ui.Text(label, Loc.T("heroYourBet"), new TextStyle(14, FontKind.SoraSemiBold), Theme.PillInk, TextAlignmentOptions.Left, false);
                Spot(host, m.CentreX, y - Theme.Xs, BigRingWidth, BigRingHeight, r.Bet, true);
                return;
            }
            for (var i = 0; i < r.Hands.Count; i++)
            {
                var x = r.Hands.Count > 1 ? m.CentreX + (i == 0 ? -SplitOffset : SplitOffset) : m.CentreX;
                var bet = r.Hands[i].Bet != 0 ? r.Hands[i].Bet : r.Bet;
                Spot(host, x, y, BetRingWidth, BetRingHeight, bet, false);
                // Split hands name their totals in the labels above; a figure beside each ring would collide.
                if (bet <= 0 || r.Hands.Count > 1) continue;
                var figure = FeltBits.Pill(host, FeltBits.PillFill, out var figureRoot, null, "BetFigure");
                figureRoot.At(x + BetRingWidth / 2f + Theme.Xs, y + Theme.Xs, new Vector2(0, 1));
                Ui.Text(figure, "$" + TableCatalog.FormatChips(bet), Type.Numeral(14), Theme.Ivory, TextAlignmentOptions.Left, false);
            }
        }

        private static void Spot(RectTransform host, float x, float y, float w, float h, int bet, bool lit)
        {
            var spot = Ui.Node("Spot", host);
            spot.At(x, y);
            spot.sizeDelta = new Vector2(w, h);
            if (lit) FeltBits.Glow(spot, w * 1.6f, Theme.Gold.WithAlpha(0.35f));
            var ring = FeltBits.Ring(spot, w, h, bet <= 0, lit ? Theme.Gold : Theme.Gold.WithAlpha(0.7f));
            ring.rectTransform.IgnoreLayout();
            ring.rectTransform.Fill();
            if (bet <= 0) return;
            var stacks = FeltBits.ChipStacks(spot, FeltBits.StacksFor(bet));
            stacks.IgnoreLayout();
            stacks.anchorMin = stacks.anchorMax = new Vector2(0.5f, 0f);
            stacks.pivot = new Vector2(0.5f, 0f);
            stacks.anchoredPosition = new Vector2(0, Theme.Xs + Theme.Xxs);
        }
    }
}
