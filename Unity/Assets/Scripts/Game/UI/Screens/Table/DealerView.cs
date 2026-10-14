using Blackjack.Core;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The dealer's side of the Seat felt: the dealer's cards fanned below the chip tray with a "Dealer 6 + ?" box
    /// beside them, the "Place your bets" call while the table is betting, and the sweep pot pill.
    /// </summary>
    public sealed class DealerView
    {
        private const float BoxGap = Theme.Sm;
        private const float CallGap = Theme.Xs;
        private const float PotChip = 22f;
        private const float PotChipOverlap = -10f;
        private const float RevealWait = 0.5f;

        private static readonly Color BoxBorder = Theme.Gold.WithAlpha(0.5f);
        private static readonly Color[] PotChips = { Theme.ChipRed, Theme.ChipBlack, Theme.ChipGreen };

        private RectTransform _cards, _boxHost, _callHost, _potHost;
        private Dyn _box, _call, _pot;
        private CardFan _fan;
        private RoundState _round;
        private FlipCard _hole;
        private float _flipStart = -1f;

        public void Build(RectTransform canvas)
        {
            _cards = Ui.Node("DealerCards", canvas);
            _cards.sizeDelta = new Vector2(FeltMetrics.CardWidth, FeltMetrics.CardHeight);
            _fan = new CardFan(_cards);
            _boxHost = Ui.Node("DealerBox", canvas);
            _box = new Dyn(_boxHost);
            _callHost = Ui.VStack(canvas, CallGap, null, TextAnchor.UpperCenter, false, "Call");
            _callHost.FitContent(true, true);
            _call = new Dyn(_callHost);
            _potHost = Ui.HStack(canvas, Theme.Sm, null, TextAnchor.MiddleCenter, false, "Pot");
            _potHost.FitContent(true, true);
            _pot = new Dyn(_potHost);
        }

        public void Refresh(AppState s, FeltMetrics m)
        {
            var r = s.Round;
            var count = r.DealerHand.Count;
            var step = FeltMetrics.DealerCardStep(count, m.ContentWidth - 2 * Theme.Xxxl);
            var rowWidth = FeltMetrics.CardWidth + Mathf.Max(0, count - 1) * step;
            _cards.At(m.CentreX - rowWidth / 2f, m.Y(FeltMetrics.DealerTop), new Vector2(0, 1));
            _cards.sizeDelta = new Vector2(rowWidth, FeltMetrics.CardHeight);
            RefreshCards(r, step);

            _boxHost.At(m.CentreX + rowWidth / 2f + BoxGap, m.Y(FeltMetrics.DealerTop) + Theme.Sm, new Vector2(0, 1));
            var label = DealerLabel(r);
            var bust = TableCalc.DealerBusted(r);
            _box.Update(count == 0 ? "" : $"{label}|{bust}|{Loc.Code}", host => { if (count > 0) BuildBox(host, label, bust); });

            _callHost.At(m.CentreX, m.Y(FeltMetrics.CallTop));
            var callSig = count == 0 && r.Phase == RoundPhase.Betting ? "call" + Loc.Code : "";
            _call.Update(callSig, host => { if (callSig.Length > 0) BuildCall(host); });

            _potHost.At(m.CentreX, m.Y(FeltMetrics.PotTop));
            _round = r;
            RefreshPot(r);
        }

        /// <summary>The settled pot waits for the hole card to finish turning, so the result is not told before it is shown.</summary>
        public void Tick()
        {
            if (_round != null && _round.Phase == RoundPhase.Settlement) RefreshPot(_round);
        }

        /// <summary>"6 + ?" while the hole card is down, the total once it is up, "16 · draws" while the dealer must hit.</summary>
        private static string DealerLabel(RoundState r)
        {
            var label = TableCalc.DealerTotalLabel(r);
            if (TableCalc.DealerBusted(r)) return label + " · " + Loc.T("seatBust");
            if (r.Phase == RoundPhase.Dealer && r.HoleRevealed && RoundEngine.DealerShouldHit(r.DealerHand))
                return label + " · " + Loc.T("dealerDraws");
            return label;
        }

        private static void BuildBox(RectTransform host, string label, bool bust)
        {
            var card = Ui.Card(host, Color.black.WithAlpha(0.6f), Theme.RadiusMd, bust ? Theme.LoseOnPanel.WithAlpha(0.7f) : BoxBorder, 1,
                Ui.Pad(Theme.Sm, Theme.Xs), 0, false, "Box");
            var outer = (RectTransform)card.parent;
            outer.At(0, 0, new Vector2(0, 1));
            outer.FitContent(true, true);
            Ui.Text(card, Loc.T("seatDealer"), Type.Caption.WithFont(FontKind.Sora), Theme.TextBody);
            Ui.Text(card, label, Type.Numeral(15), bust ? Theme.LoseOnPanel : Theme.Ivory, TMPro.TextAlignmentOptions.Left, false);
        }

        private static void BuildCall(RectTransform host)
        {
            var title = Ui.Text(host, Loc.T("feltPlaceBets"), Type.FeltPrint, Theme.Gold, TMPro.TextAlignmentOptions.Center, false);
            title.fontSize = 18;
            Ui.Text(host, Loc.T("feltDealerWaits"), new TextStyle(16, FontKind.SerifItalic), Theme.Ivory, TMPro.TextAlignmentOptions.Center, false);
        }

        private void RefreshPot(RoundState r)
        {
            var pot = TableCalc.MidRound(r);
            var settled = r.Phase == RoundPhase.Settlement;
            var show = pot.PotValueLabel.Length > 0 && (!settled || !Flipping);
            var sig = show ? $"{pot.PotLabelText}|{pot.PotValueLabel}|{pot.HeroLeads}|{settled}|{Loc.Code}" : "";
            _pot.Update(sig, host =>
            {
                if (!show) return;
                var chips = Ui.HStack(host, PotChipOverlap, null, TextAnchor.MiddleCenter, false, "Chips");
                foreach (var colour in PotChips) W.ChipDisc(chips, colour, PotChip);
                var swept = settled && r.SweepInfo != null;
                var row = FeltBits.Pill(host, swept ? Theme.Gold : Color.black.WithAlpha(0.55f), out _, null, "PotPill", Theme.Md);
                var ink = swept ? Theme.PillInk : Theme.Gold;
                Ui.Text(row, settled ? pot.PotLabelText : Loc.T("gameSweepPot"), Type.Caption, ink, TMPro.TextAlignmentOptions.Left, false);
                Ui.Text(row, pot.PotValueLabel, Type.Numeral(15), swept ? Theme.PillInk : Theme.Ivory, TMPro.TextAlignmentOptions.Left, false);
                if (pot.HeroLeads && !settled)
                    Ui.Text(row, "· " + Loc.T("gameYouLead"), Type.Caption, Theme.Gold, TMPro.TextAlignmentOptions.Left, false);
            });
        }

        private bool Flipping => _hole != null && _flipStart >= 0 && Time.unscaledTime - _flipStart < RevealWait;

        private void RefreshCards(RoundState r, float step)
        {
            var hand = r.DealerHand;
            if (hand.Count == 0)
            {
                _fan.Clear();
                _hole = null;
                _flipStart = -1f;
                return;
            }
            const float w = FeltMetrics.CardWidth, h = FeltMetrics.CardHeight;
            if (hand.Count < _fan.Count) { _hole = null; _flipStart = -1f; }
            _fan.Sync(hand, w, h,
                (card, i, n) => card.anchoredPosition = new Vector2(w / 2f + i * step, -h / 2f),
                (parent, i, card) =>
                {
                    if (i != 1) return CardViews.Face(parent, card, w, h);
                    // The hole card turns over in place when the dealer opens it.
                    _hole = FlipCard.Make(parent, card, w, h, r.HoleRevealed);
                    return _hole.Root;
                });
            if (_hole == null) return;
            _hole.Set(r.HoleRevealed);
            if (r.HoleRevealed && _flipStart < 0) _flipStart = Time.unscaledTime;
            if (!r.HoleRevealed) _flipStart = -1f;
        }
    }
}
