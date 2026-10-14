using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// One opponent on the curve of the Seat felt: a dark pill with the name, the hand's total and what they did,
    /// their cards fanned and turned toward the dealer, and the ring their bet sits in. A seat that busts is
    /// cleared like a real table: the cards go, the ring is left empty and dashed, and the pill says "bust".
    /// </summary>
    public sealed class SeatView
    {
        private const float UpperRing = 40f, LowerRing = 46f, RingDepth = 0.37f;
        private const float LowerCardWidth = 46f;
        private const float GlowSize = 150f;
        private const float StackDiameter = 20f;

        /// <summary>Room left at the top of the column for the pill, which is drawn on its own layer above.</summary>
        private const float PillRoom = 36f;

        private static readonly Color RingColour = Theme.Gold.WithAlpha(0.55f);
        private static readonly Color ActingGlow = Theme.GoldLight.WithAlpha(0.22f);
        private static readonly Color ActingNote = Theme.Hex(0xFF5A4210);

        private int _index;
        private RectTransform _root, _pillHost, _fanHost, _ringHost;
        private Dyn _pill, _ring;
        private CardFan _fan;
        private UnityEngine.UI.RawImage _glow;

        public RectTransform Root => _root;

        /// <param name="pills">The layer above the hero's cards: a name is never hidden under a card.</param>
        public void Build(RectTransform canvas, RectTransform pills, int index)
        {
            _index = index;
            _root = Ui.VStack(canvas, Theme.Xs, null, TextAnchor.UpperCenter, false, "Seat" + index);
            _root.FitContent(true, true);
            _glow = FeltBits.Glow(_root, GlowSize, ActingGlow);
            Ui.Spacer(_root, PillRoom);
            _pillHost = Ui.VStack(pills, 0, null, TextAnchor.MiddleCenter, false, "SeatPill" + index);
            _pillHost.FitContent(true, true);
            _pill = new Dyn(_pillHost);
            _fanHost = Ui.Node("Fan", _root);
            _fan = new CardFan(_fanHost);
            _ringHost = Ui.VStack(_root, 0, null, TextAnchor.MiddleCenter, false, "RingHost");
            _ring = new Dyn(_ringHost);
        }

        private bool Lower => _index == 1 || _index == 2;
        private float CardW => Lower ? LowerCardWidth : FeltMetrics.SeatCardWidth;
        private float CardH => CardW * FeltMetrics.SeatCardHeight / FeltMetrics.SeatCardWidth;
        private float RingWidth => Lower ? LowerRing : UpperRing;

        public void Refresh(AppState s, FeltMetrics m, Friend friend)
        {
            var r = s.Round;
            var seated = friend != null;
            _root.gameObject.SetActive(seated);
            _pillHost.gameObject.SetActive(seated);
            if (!seated) return;
            var place = m.SeatSlot(_index);
            _root.At(place.X, place.Y);

            var npc = _index < r.NpcSeats.Count ? r.NpcSeats[_index] : null;
            var cards = npc?.Cards ?? System.Array.Empty<PlayingCard>();
            var busted = npc != null && npc.Action == "BUST";
            var acting = r.ActingSeat == _index;
            _glow.gameObject.SetActive(acting);

            // The fan, turned toward the dealer (the design's angles are CSS, clockwise; Unity turns the other way).
            var showCards = cards.Count > 0 && !busted;
            _fanHost.gameObject.SetActive(showCards);
            var step = CardW * (1f - FeltMetrics.SeatOverlap);
            var width = CardW + Mathf.Max(0, cards.Count - 1) * step;
            _fanHost.Size(width, CardH);
            _fanHost.localRotation = Quaternion.Euler(0, 0, -place.Tilt);
            if (showCards)
                _fan.Sync(cards, CardW, CardH, (card, i, n) => card.anchoredPosition = new Vector2(CardW / 2f + i * step, -CardH / 2f));
            else _fan.Clear();

            var pill = PillContent(s, npc, friend, busted);
            _pill.Update($"{pill.total}|{pill.note}|{pill.delta}|{pill.tone}|{acting}|{friend.FirstName}|{Loc.Code}",
                host => BuildPill(host, friend.FirstName, pill, acting));

            var bet = npc?.Bet ?? 0;
            var empty = busted || bet == 0;
            _ring.Update($"{RingWidth}|{bet}|{empty}", host => BuildRing(host, bet, empty));

            // An outer seat with a long hand or a long name keeps the whole column on the felt.
            UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(_root);
            UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(_pillHost);
            var widest = Mathf.Max(UnityEngine.UI.LayoutUtility.GetPreferredWidth(_root), UnityEngine.UI.LayoutUtility.GetPreferredWidth(_pillHost),
                width + CardH * Mathf.Abs(Mathf.Sin(place.Tilt * Mathf.Deg2Rad)));
            var x = Mathf.Clamp(place.X, m.Inset + widest / 2f + Theme.Xs, m.Inset + m.ContentWidth - widest / 2f - Theme.Xs);
            _root.At(x, place.Y);
            _pillHost.At(x, place.Y);
        }

        private enum Tone { Plain, Good, Bad }

        private readonly struct PillText
        {
            public readonly string total, note, delta;
            public readonly Tone tone, deltaTone;

            public PillText(string total, string note, Tone tone, string delta = "", Tone deltaTone = Tone.Plain)
            {
                this.total = total; this.note = note; this.tone = tone; this.delta = delta; this.deltaTone = deltaTone;
            }
        }

        /// <summary>What the seat's pill says: the bet while betting, then the total and the last thing they did, then the result.</summary>
        private static PillText PillContent(AppState s, NpcSeat npc, Friend friend, bool busted)
        {
            var r = s.Round;
            if (npc == null) return new PillText("", "", Tone.Plain);
            if (npc.Cards.Count == 0) return new PillText("$" + TableCatalog.FormatChips(npc.Bet), "", Tone.Plain);

            var total = BlackjackRules.HandValue(npc.Cards).ToString();
            if (r.Phase == RoundPhase.Settlement)
            {
                int? dealer = BlackjackRules.HandValue(r.DealerHand);
                var lost = TablePot.SeatLost(npc, dealer);
                var takes = r.SweepInfo != null && !r.SweepInfo.HeroTook && r.SweepInfo.Winner == friend.FirstName;
                var won = takes ? r.SweepInfo.TotalWin : npc.Bet;
                // Short at the result: the total (red if it bust) and what the seat won or lost.
                return new PillText(total, "", busted ? Tone.Bad : Tone.Plain,
                    (lost ? "−$" : "+$") + TableCatalog.FormatChips(lost ? npc.Bet : won), lost ? Tone.Bad : Tone.Good);
            }
            switch (npc.Action)
            {
                case "BUST": return new PillText("", Loc.T("seatBust"), Tone.Bad);
                case "STAND": return new PillText(total, Loc.T("seatStand"), Tone.Good);
                case "HIT": return new PillText(total, Loc.T("seatHits"), Tone.Plain);
            }
            var soft = BlackjackRules.IsSoft(npc.Cards) && BlackjackRules.HandValue(npc.Cards) < 21;
            return new PillText(total, soft ? Loc.T("handSoft") : "", Tone.Plain);
        }

        private static Color ToneColour(Tone tone, bool acting) => acting ? Theme.PillInk : tone switch
        {
            Tone.Good => Theme.WinLight,
            Tone.Bad => Theme.LoseOnPanel,
            _ => Theme.Ivory,
        };

        private static void BuildPill(RectTransform host, string name, PillText p, bool acting)
        {
            var row = FeltBits.Pill(host, acting ? Theme.Gold : FeltBits.PillFill, out _, null, "Pill");
            Ui.Text(row, name, Type.Caption.WithFont(FontKind.SoraSemiBold), acting ? Theme.PillInk : Theme.Ivory, TextAlignmentOptions.Left, false);
            if (p.total.Length > 0)
                Ui.Text(row, p.total, Type.Numeral(14), ToneColour(p.tone, acting), TextAlignmentOptions.Left, false);
            if (p.note.Length > 0)
                Ui.Text(row, p.note, Type.Caption.WithFont(FontKind.Sora), acting ? ActingNote : p.tone == Tone.Bad ? Theme.LoseOnPanel : Theme.TextBody,
                    TextAlignmentOptions.Left, false);
            if (p.delta.Length > 0)
                Ui.Text(row, p.delta, Type.Numeral(Type.Floor), ToneColour(p.deltaTone, acting), TextAlignmentOptions.Left, false);
        }

        private void BuildRing(RectTransform host, int bet, bool empty)
        {
            var w = RingWidth;
            var h = w * RingDepth;
            var holder = Ui.Node("Spot", host);
            holder.Size(w, h);
            var ring = FeltBits.Ring(holder, w, h, empty, empty ? RingColour.WithAlpha(0.33f) : RingColour);
            ring.rectTransform.IgnoreLayout();
            ring.rectTransform.Fill();
            if (empty) return;
            // The chips stand in the ring, their base a little above its lower edge.
            var stacks = FeltBits.ChipStacks(holder, FeltBits.StacksFor(bet).Take(1), StackDiameter);
            stacks.IgnoreLayout();
            stacks.anchorMin = stacks.anchorMax = new Vector2(0.5f, 0f);
            stacks.pivot = new Vector2(0.5f, 0f);
            stacks.anchoredPosition = new Vector2(0, Theme.Xxs);
        }
    }
}
