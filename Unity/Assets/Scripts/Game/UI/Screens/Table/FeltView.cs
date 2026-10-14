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
    /// The felt: a fixed-unit canvas scaled to the room it is given, holding the tilted table, the dealer,
    /// four opponent plates and the hero's hands. Built once; refreshed in place so cards animate alone.
    /// </summary>
    public sealed class FeltView
    {
        private const float WoodEdge = 10f;
        private const float RailOverhang = 40f;
        private const float RailDepthShare = 0.3f;
        private const float RailBelowCanvas = 20f;
        /// <summary>The current layout's corners hold the fixtures at this scale; the Seat layout gives them their own room.</summary>
        private const float FixtureScale = 0.6f;

        private readonly GameController _g;
        private RectTransform _host;
        private RectTransform _canvas;
        private RawImage _feltImage;
        private Material _feltMaterial;
        private DealerAreaView _dealer;
        private readonly SeatPlateView[] _seats = new SeatPlateView[TableCatalog.OpponentSeats];
        private HeroAreaView _hero;
        private FeltEffects _effects;
        private AppState _state;
        private Vector2 _lastSize;
        private FeltMetrics _metrics;
        private string _layoutSignature;

        public FeltView(GameController g) { _g = g; }

        public FeltMetrics Metrics => _metrics;
        public RectTransform Canvas => _canvas;

        public void Build(RectTransform parent)
        {
            _host = Ui.Node("Felt", parent);
            _host.Flex();
            _host.gameObject.AddComponent<RectMask2D>();

            _canvas = Ui.Node("FeltCanvas", _host);
            _canvas.anchorMin = _canvas.anchorMax = new Vector2(0, 1);
            _canvas.pivot = new Vector2(0, 1);
            // The felt scales from 0.65 to 1.4; its labels never land under the 12-unit floor.
            _canvas.gameObject.AddComponent<FloorScope>();

            _feltMaterial = Gfx.NewFeltMaterial();
            _feltImage = W.Raw(_canvas, Texture2D.whiteTexture, "Table");
            _feltImage.material = _feltMaterial;
            _feltImage.rectTransform.Fill();

            BuildChipTray();
            BuildDiscardPile();

            _dealer = new DealerAreaView();
            _dealer.Build(_canvas);
            for (var i = 0; i < _seats.Length; i++)
            {
                _seats[i] = new SeatPlateView();
                _seats[i].Build(_canvas, i);
            }
            _hero = new HeroAreaView();
            _hero.Build(_canvas);
            _effects = new FeltEffects(_canvas);
        }

        private RectTransform _tray, _pile;

        /// <summary>The dealer's chip tray: racked columns of chips in a dark well.</summary>
        private void BuildChipTray()
        {
            _tray = Fixture("ChipTray", Gfx.ChipTray(), Gfx.TraySize, new Vector2(0, 1));
            _tray.localScale = Vector3.one * FixtureScale;
        }

        /// <summary>The discard holder and the shoe, side by side on the dealer's right.</summary>
        private void BuildDiscardPile()
        {
            _pile = Ui.Node("DiscardPile", _canvas);
            _pile.anchorMin = _pile.anchorMax = new Vector2(1, 1);
            _pile.pivot = new Vector2(1, 1);
            _pile.sizeDelta = new Vector2(Gfx.DiscardSize.x + Theme.Xs + Gfx.ShoeSize.x, Gfx.ShoeSize.y);
            _pile.localScale = Vector3.one * FixtureScale;
            var discard = FixtureImage(_pile, "Discard", Gfx.DiscardHolder());
            discard.rectTransform.Pin(new Vector2(0, 1), new Vector2(0, 1), new Vector2(0, -Theme.Xxs), Gfx.DiscardSize);
            var shoe = FixtureImage(_pile, "Shoe", Gfx.Shoe());
            shoe.rectTransform.Pin(new Vector2(1, 1), new Vector2(1, 1), Vector2.zero, Gfx.ShoeSize);
        }

        private RectTransform Fixture(string name, Sprite art, Vector2 size, Vector2 corner)
        {
            var img = FixtureImage(_canvas, name, art);
            img.rectTransform.anchorMin = img.rectTransform.anchorMax = corner;
            img.rectTransform.pivot = corner;
            img.rectTransform.sizeDelta = size;
            return img.rectTransform;
        }

        private static Image FixtureImage(Transform parent, string name, Sprite art)
        {
            var img = Ui.Box(parent, Color.white, 0, name);
            img.sprite = art;
            img.type = Image.Type.Simple;
            return img;
        }

        public void Refresh(AppState state)
        {
            _state = state;
            Relayout(force: true);
        }

        public void Tick()
        {
            if (_host == null) return;
            var size = _host.rect.size;
            if (size != _lastSize) Relayout(force: true);
            _hero.Tick();
            _effects.Tick();
        }

        private void Relayout(bool force)
        {
            if (_state == null) return;
            var size = _host.rect.size;
            if (size.x < 8 || size.y < 8) return;
            _lastSize = size;

            var r = _state.Round;
            var heroHasCards = r.Hands.Any(h => h.Cards.Count > 0);
            var m = FeltMetrics.For(r.Phase, heroHasCards, r.SweepAmount, size.x, size.y);
            _metrics = m;

            _canvas.sizeDelta = new Vector2(m.CanvasWidth, m.CanvasHeight);
            _canvas.localScale = Vector3.one * m.Scale;
            _canvas.anchoredPosition = Vector2.zero;

            _feltMaterial.SetVector("_Canvas", new Vector4(m.CanvasWidth, m.CanvasHeight, 0, 0));
            // The padded rail curves across the bottom of the felt, deepest in front of the hero.
            var railMid = m.CanvasHeight + RailBelowCanvas;
            var railSide = railMid - RailDepthShare * m.ContentWidth;
            _feltMaterial.SetVector("_Rail", new Vector4(railSide, railMid, RailOverhang, WoodEdge));

            _tray.anchoredPosition = new Vector2(m.Inset + 10, -(WoodEdge + Theme.Sm));
            _pile.anchoredPosition = new Vector2(-(m.Inset + 10), -(WoodEdge + Theme.Xs));

            _dealer.Refresh(_state, m);
            var seatFriends = Roster.TableSeats(_state.Friends, r.Stake?.Key);
            for (var i = 0; i < _seats.Length; i++)
                _seats[i].Refresh(_state, m, i, i < seatFriends.Count ? seatFriends[i] : null);
            _hero.Refresh(_state, m);
            _effects.Refresh(_state, m, _hero, _seats);
        }
    }

    // ---------------------------------------------------------------------------------------------------

    public sealed class DealerAreaView
    {
        private RectTransform _root, _cardsHost, _potSlot, _bannerSlot;
        private TextMeshProUGUI _total;
        private RectTransform _bustTag;
        private Dyn _potPill, _banner;
        private CardFan _fan;
        private FlipCard _hole;
        private string _lastDealerKey = "";
        private string _lastPotSig = "";

        public void Build(RectTransform canvas)
        {
            _root = Ui.VStack(canvas, 8, null, TextAnchor.UpperCenter, false, "Dealer");
            _root.anchorMin = new Vector2(0, 1); _root.anchorMax = new Vector2(1, 1); _root.pivot = new Vector2(0.5f, 1);
            _root.offsetMin = Vector2.zero; _root.offsetMax = Vector2.zero;
            _root.FitContent();
            _root.Ensure<LayoutElement>();

            BuildBadge(_root);
            // Slots size to what they hold (the pill, the banner) but keep a fixed height so the felt never jumps.
            _potSlot = Ui.VStack(_root, 0, null, TextAnchor.MiddleCenter, false, "PotSlot");
            _potSlot.Size(null, 30);
            _potPill = new Dyn(_potSlot);
            _bannerSlot = Ui.VStack(_root, 0, null, TextAnchor.MiddleCenter, false, "BannerSlot");
            _bannerSlot.Size(null, 0);
            _banner = new Dyn(_bannerSlot);

            _cardsHost = Ui.Node("DealerCards", _root);
            _cardsHost.Size(FeltMetrics.CardWidth * 4, FeltMetrics.CardHeight + 2);
            _fan = new CardFan(_cardsHost);
        }

        private void BuildBadge(RectTransform parent)
        {
            var box = Ui.Card(parent, Color.black.WithAlpha(0.72f), 26, Theme.Gold.WithAlpha(0.32f), 1, Ui.Pad(4, 4, 16, 4), 0, false, "Badge");
            var row = Ui.HStack(box, 9, null, TextAnchor.MiddleLeft);
            var avatar = Ui.Box(row, Theme.Hex(0xFF1F2A26), 0, "Avatar");
            avatar.sprite = Sprites.Circle; avatar.type = Image.Type.Simple;
            avatar.rectTransform.Size(46, 46);
            var d = Ui.Text(avatar.transform, "D", 24, Theme.Gold, FontKind.SerifItalic, TextAlignmentOptions.Center, false);
            d.rectTransform.Fill();

            var col = Ui.VStack(row, 0, null, TextAnchor.MiddleLeft, false);
            Ui.Text(col, Loc.T("gameDealer"), 14, Theme.Gold.WithAlpha(0.85f), FontKind.Mono, TextAlignmentOptions.Left, false, 1.6f, 0, "Label");
            var line = Ui.HStack(col, 8, null, TextAnchor.MiddleLeft);
            _total = Ui.Text(line, "—", 24, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            var tag = Ui.Card(line, Theme.Lose.WithAlpha(0.22f), 6, Theme.Lose.WithAlpha(0.6f), 1, Ui.Pad(6, 1), 0, false, "BustTag");
            Ui.Text(tag, Loc.T("gameBusted"), 14, Theme.LoseLight, FontKind.MonoBold, TextAlignmentOptions.Center, false, 1f);
            _bustTag = (RectTransform)tag.parent;
            _bustTag.gameObject.SetActive(false);
        }

        public void Refresh(AppState s, FeltMetrics m)
        {
            var r = s.Round;
            _root.offsetMin = new Vector2(m.Inset, 0);
            _root.offsetMax = new Vector2(-m.Inset, 0);
            _total.text = TableCalc.DealerTotalLabel(r);
            _bustTag.gameObject.SetActive(TableCalc.DealerBusted(r));

            RefreshPot(r);
            RefreshBanner(r);
            RefreshCards(r, m);
        }

        private void RefreshPot(RoundState r)
        {
            var pot = TableCalc.MidRound(r);
            var sig = pot.PotLabelText + "|" + pot.PotValueLabel + "|" + pot.HeroLeads;
            if (sig == _lastPotSig) return;
            _lastPotSig = sig;
            _potPill.Update(sig, host =>
            {
                if (pot.PotValueLabel.Length == 0) return;
                var box = Ui.Card(host, Color.black.WithAlpha(0.6f), 14, Theme.Gold.WithAlpha(0.22f), 1, Ui.Pad(12, 3), 0, false, "Pill");
                var row = Ui.HStack(box, 8, null, TextAnchor.MiddleCenter);
                Ui.Text(row, pot.PotLabelText, 14, Theme.Gold.WithAlpha(0.7f), FontKind.Mono, TextAlignmentOptions.Left, false, 1.4f);
                Ui.Text(row, pot.PotValueLabel, 18, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false);
                if (pot.HeroLeads)
                {
                    var tag = Ui.Card(row, Theme.Gold, 6, null, 0, Ui.Pad(6, 2), 0, false, "Lead");
                    Ui.Text(tag, Loc.T("gameYouLead"), 14, Theme.GoldInk, FontKind.MonoBold, TextAlignmentOptions.Center, false, 1f);
                }
            });
        }

        private void RefreshBanner(RoundState r)
        {
            // The banner waits for the hole card's flip to finish so the sweep is not announced before the reveal.
            var show = r.SweepAmount > 0 && (!_holeFlipping || Time.unscaledTime - _flipStart > 0.5f);
            if (r.SweepAmount > 0 && _hole != null && r.HoleRevealed && _flipStart < 0) _flipStart = Time.unscaledTime;
            var sig = show ? "sweep" + r.SweepAmount : "";
            _banner.Update(sig, host =>
            {
                if (!show) return;
                var box = Ui.Card(host, Theme.Gold, 18, null, 0, Ui.Pad(16, 7), 0, false, "Sweep");
                var row = Ui.HStack(box, 9, null, TextAnchor.MiddleCenter);
                Ui.Text(row, Loc.T("gameTableSweep"), 14, Theme.GoldInk, FontKind.Mono, TextAlignmentOptions.Left, false, 1.4f);
                Ui.Text(row, "+$" + TableCatalog.FormatChips(r.SweepAmount), 24, Theme.GoldInk, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            });
            _bannerSlot.Size(null, show ? 40 : 0);
        }

        private bool _holeFlipping => _hole != null && _flipStart >= 0;
        private float _flipStart = -1f;

        private void RefreshCards(RoundState r, FeltMetrics m)
        {
            var hand = r.DealerHand;
            if (hand.Count == 0)
            {
                _fan.Clear();
                _hole = null;
                _flipStart = -1f;
                return;
            }
            var w = FeltMetrics.CardWidth;
            var h = FeltMetrics.CardHeight;
            _cardsHost.sizeDelta = new Vector2(m.ContentWidth, h + 2);
            var step = FeltMetrics.DealerCardStep(hand.Count, m.ContentWidth);
            var rowWidth = w + (hand.Count - 1) * step;
            var left = (m.ContentWidth - rowWidth) / 2f;
            var host = _cardsHost;

            if (hand.Count < _fan.Count) { _hole = null; _flipStart = -1f; }
            _fan.Sync(hand, w, h,
                (card, i, count) =>
                {
                    var rowW = w + (count - 1) * FeltMetrics.DealerCardStep(count, m.ContentWidth);
                    var l = (m.ContentWidth - rowW) / 2f;
                    card.anchoredPosition = new Vector2(l + i * FeltMetrics.DealerCardStep(count, m.ContentWidth) + w / 2f, -(h + 2 - h / 2f));
                },
                (parent, i, card) =>
                {
                    if (i != 1) return CardViews.Face(parent, card, w, h);
                    // The hole card turns over in place when the dealer opens it.
                    var flip = FlipCard.Make(parent, card, w, h, r.HoleRevealed);
                    _hole = flip;
                    return flip.Root;
                });
            if (_hole != null)
            {
                var wasRevealed = _flipStart >= 0;
                _hole.Set(r.HoleRevealed);
                if (r.HoleRevealed && !wasRevealed && _flipStart < 0) _flipStart = Time.unscaledTime;
                if (!r.HoleRevealed) _flipStart = -1f;
            }
        }
    }

    // ---------------------------------------------------------------------------------------------------

    public sealed class SeatPlateView
    {
        private const float CardW = 42, CardH = 60, CardStep = 27, CardsMax = 90;

        private RectTransform _slot, _plate, _cardsHolder, _cardsClip, _avatarHolder, _statusHolder, _badgeHolder;
        private Image _plateOuter, _plateInner;
        private TextMeshProUGUI _name, _status, _stack;
        private CardFan _fan;
        private Dyn _badge;
        private Image _avatarDisc;
        private TextMeshProUGUI _avatarText;
        private int _index;

        public RectTransform Slot => _slot;

        public void Build(RectTransform canvas, int index)
        {
            _index = index;
            _slot = Ui.Node("Seat" + index, canvas);
            var rightSide = index % 2 == 1;
            _slot.anchorMin = _slot.anchorMax = new Vector2(rightSide ? 1 : 0, 1);
            _slot.pivot = new Vector2(rightSide ? 1 : 0, 1);

            var inner = Ui.Card(_slot, Color.black.WithAlpha(0.62f), Theme.RadiusLg, Theme.Gold.WithAlpha(0.22f), 1.5f, Ui.Pad(5, 5, 10, 5), 0, true, "Plate");
            _plate = (RectTransform)inner.parent;
            _plate.anchorMin = new Vector2(0, 1); _plate.anchorMax = new Vector2(1, 1); _plate.pivot = new Vector2(0.5f, 1);
            _plate.offsetMin = Vector2.zero; _plate.offsetMax = Vector2.zero;
            _plate.FitContent();
            _plateOuter = _plate.GetComponent<Image>();
            _plateInner = inner.GetComponent<Image>();
            var row = Ui.HStack(inner, 7, null, TextAnchor.MiddleLeft, false, "Row");

            // Either the cards (once dealt) or the avatar sits first.
            _avatarHolder = Ui.Node("AvatarHolder", row);
            _avatarHolder.Size(46, 46);
            _avatarDisc = Ui.Box(_avatarHolder, Theme.SeatColors[index % 4], 0, "Avatar");
            _avatarDisc.sprite = Sprites.Circle; _avatarDisc.type = Image.Type.Simple; _avatarDisc.rectTransform.Fill();
            _avatarText = Ui.Text(_avatarHolder, "", 22, Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center, false);
            _avatarText.rectTransform.Fill();

            _cardsHolder = Ui.Node("CardsHolder", row);
            _cardsHolder.Size(CardsMax, CardH);
            _cardsClip = Ui.Node("Cards", _cardsHolder);
            _cardsClip.anchorMin = _cardsClip.anchorMax = new Vector2(0, 0.5f);
            _cardsClip.pivot = new Vector2(0, 0.5f);
            _cardsClip.sizeDelta = new Vector2(CardW, CardH);
            _fan = new CardFan(_cardsClip);

            var col = Ui.VStack(row, 0, null, TextAnchor.MiddleLeft, true, "Text");
            col.FlexW();
            var line1 = Ui.HStack(col, 6, null, TextAnchor.MiddleLeft, false);
            _name = Ui.Text(line1, "", 16, Theme.TextPrimary.WithAlpha(0.95f), FontKind.Sora, TextAlignmentOptions.Left, false);
            _name.Shrink(0.7f);
            _name.rectTransform.FlexW();
            _status = Ui.Text(line1, "", 20, Theme.WinLight, FontKind.MonoBold, TextAlignmentOptions.Right, false);
            var line2 = Ui.HStack(col, 6, null, TextAnchor.MiddleLeft, false);
            _stack = Ui.Text(line2, "", 17, Color.white, FontKind.MonoBold, TextAlignmentOptions.Left, false);
            _stack.rectTransform.FlexW();
            _stack.rectTransform.MinSize(16);
            // Shrinks to fit beside the badge (Flutter's FittedBox scale-down) rather than ellipsising a bankroll.
            _stack.enableAutoSizing = true;
            _stack.fontSizeMin = 9;
            _stack.fontSizeMax = 17;
            _badgeHolder = Ui.HStack(line2, 0, null, TextAnchor.MiddleRight, false);
            _badge = new Dyn(_badgeHolder);
        }

        public void Refresh(AppState s, FeltMetrics m, int index, Friend friend)
        {
            var r = s.Round;
            var rightSide = index % 2 == 1;
            _slot.anchoredPosition = new Vector2(rightSide ? -m.Inset : m.Inset, -m.SeatTopOf(index / 2));
            _slot.sizeDelta = new Vector2(m.SeatWidth, m.SeatHeight);
            if (friend == null) { _slot.gameObject.SetActive(false); return; }
            _slot.gameObject.SetActive(true);

            var npc = index < r.NpcSeats.Count ? r.NpcSeats[index] : null;
            var hasCards = npc != null && npc.Cards.Count > 0;
            var total = hasCards ? BlackjackRules.HandValue(npc.Cards) : 0;
            var acting = r.ActingSeat == index;
            var takesPot = r.Phase == RoundPhase.Settlement && r.SweepInfo != null && !r.SweepInfo.HeroTook
                           && r.SweepInfo.Winner == friend.FirstName;

            Ui.StyleRing(_plateOuter, acting ? Theme.Gold : Theme.Gold.WithAlpha(0.22f), Theme.RadiusLg, 1.5f);
            Ui.Style(_plateInner, acting ? Theme.Gold.WithAlpha(0.18f) : Color.black.WithAlpha(0.62f), Theme.RadiusLg - 1.5f);

            _avatarHolder.gameObject.SetActive(!hasCards);
            _cardsHolder.gameObject.SetActive(hasCards);
            _avatarText.text = friend.Initial;
            _name.text = friend.FirstName;
            _stack.text = TableCatalog.FormatChips(friend.Chips);
            _status.gameObject.SetActive(hasCards);
            _status.text = total.ToString();
            _status.color = total > 21 ? Theme.LoseSoft : (total == 21 ? Theme.Gold : Theme.WinLight);

            if (hasCards)
            {
                var n = npc.Cards.Count;
                var width = CardW + (n - 1) * CardStep;
                _cardsHolder.GetComponent<LayoutElement>().preferredWidth = Mathf.Min(width, CardsMax);
                _cardsHolder.GetComponent<LayoutElement>().minWidth = Mathf.Min(width, CardsMax);
                _cardsClip.localScale = Vector3.one * Mathf.Min(1f, CardsMax / width);
                _cardsClip.sizeDelta = new Vector2(width, CardH);
                _fan.Sync(npc.Cards, CardW, CardH, (card, i, count) =>
                    card.anchoredPosition = new Vector2(i * CardStep + CardW / 2f, -CardH / 2f));
            }
            else _fan.Clear();

            // The 12-unit floor stops the bankroll shrinking beside an action badge; mid-round the badge matters more.
            _stack.gameObject.SetActive(!takesPot && (npc == null || npc.Action.Length == 0));
            var badgeSig = takesPot ? "pot" + r.SweepInfo.TotalWin
                : npc != null && npc.Action.Length > 0 ? "act" + npc.Action
                : npc != null ? "bet" + npc.Bet : "";
            var rebuilt = _badge.Update(badgeSig, host =>
            {
                if (takesPot)
                {
                    var c = Ui.Card(host, Theme.Gold, Theme.RadiusSm, null, 0, Ui.Pad(7, 3), 0, false, "Pot");
                    Ui.Text(c, "+$" + TableCatalog.FormatChips(r.SweepInfo.TotalWin), 14, Theme.GoldInk, FontKind.MonoBold, TextAlignmentOptions.Center, false, 0.5f);
                }
                else if (npc != null && npc.Action.Length > 0)
                {
                    var color = npc.Action == "BUST" ? Theme.LoseSoft : npc.Action == "STAND" ? Theme.WinLight : Theme.Gold;
                    var c = Ui.Card(host, Color.black.WithAlpha(0.8f), Theme.RadiusSm, color, 1, Ui.Pad(6, 3), 0, false, "Action");
                    var text = npc.Action == "BUST" ? Loc.T("gameBusted") : npc.Action == "STAND" ? Loc.T("gameStand") : npc.Action;
                    Ui.Text(c, text, 13, color, FontKind.MonoBold, TextAlignmentOptions.Center, false, 0.8f);
                }
                else if (npc != null)
                {
                    var row = Ui.HStack(host, 3, null, TextAnchor.MiddleRight, false);
                    W.Dot(row, 10, Theme.Gold);
                    Ui.Text(row, TableCatalog.FormatChips(npc.Bet), 14, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Left, false);
                }
            });
            if (rebuilt)
            {
                // Keep the badge at its natural width: it is the stack figure that gives way when the line is tight.
                LayoutRebuilder.ForceRebuildLayoutImmediate(_badgeHolder);
                _badgeHolder.Ensure<LayoutElement>().minWidth = LayoutUtility.GetPreferredWidth(_badgeHolder);
            }
        }
    }

    // ---------------------------------------------------------------------------------------------------

    public sealed class HeroAreaView
    {
        private const float Circle = 78f;
        private RectTransform _root, _stack;
        private readonly List<HandBlock> _blocks = new List<HandBlock>();

        public RectTransform PlateOf(int hand) => hand < _blocks.Count ? _blocks[hand].Plate : null;

        public void Build(RectTransform canvas)
        {
            _root = Ui.Node("Hero", canvas);
            _root.anchorMin = new Vector2(0, 0); _root.anchorMax = new Vector2(1, 1);
            // Not yet: a split stack scales itself down to fit, which a floor would fight. The Seat hero replaces it.
            _root.gameObject.AddComponent<FloorScope>().On = false;
            _stack = Ui.VStack(_root, 10, null, TextAnchor.UpperCenter, false, "Hands");
            _stack.anchorMin = new Vector2(0.5f, 1); _stack.anchorMax = new Vector2(0.5f, 1); _stack.pivot = new Vector2(0.5f, 1);
            _stack.offsetMin = _stack.offsetMax = Vector2.zero;
            _stack.sizeDelta = Vector2.zero;
            _stack.FitContent(true, true);
        }

        private float _availableHeight;
        private bool _needsFit;

        public void Refresh(AppState s, FeltMetrics m)
        {
            var r = s.Round;
            _root.gameObject.SetActive(r.Phase != RoundPhase.Settlement);
            _root.offsetMin = new Vector2(m.Inset, 0);
            _root.offsetMax = new Vector2(-m.Inset, -m.HeroTop);
            _availableHeight = m.CanvasHeight - m.HeroTop;

            while (_blocks.Count > r.Hands.Count)
            {
                _blocks[_blocks.Count - 1].Destroy();
                _blocks.RemoveAt(_blocks.Count - 1);
            }
            while (_blocks.Count < r.Hands.Count) _blocks.Add(new HandBlock(_stack, _blocks.Count));
            for (var i = 0; i < _blocks.Count; i++)
                _blocks[i].Refresh(s, i, i == r.ActiveHandIndex && r.Phase == RoundPhase.Playing, r.Hands.Count > 1);
            _needsFit = true;
        }

        public void Tick()
        {
            if (!_needsFit) return;
            _needsFit = false;
            // A split hand stacks two full blocks; scale the whole area down rather than overflow the felt.
            LayoutRebuilder.ForceRebuildLayoutImmediate(_stack);
            var preferred = LayoutUtility.GetPreferredHeight(_stack);
            _stack.localScale = Vector3.one * (preferred > _availableHeight && preferred > 0 ? Mathf.Max(0.3f, _availableHeight / preferred) : 1f);
        }

        private sealed class HandBlock
        {
            private readonly RectTransform _block, _fanHost, _fanClip, _totalCircle;
            private readonly CardFan _fan;
            private readonly TextMeshProUGUI _betText, _totalText, _handLabel, _avatarInitial;
            private readonly Image _betRing, _totalRing, _plateOuter, _plateInner;
            private readonly RectTransform _betChipRow;
            private readonly CountUpText _balance;
            private readonly GameObject _betChip, _betPlaceholder;

            public RectTransform Plate { get; }

            public HandBlock(RectTransform parent, int index)
            {
                _block = Ui.VStack(parent, 4, null, TextAnchor.UpperCenter, false, "Hand" + index);
                _fanHost = Ui.Node("Fan", _block);
                _fanHost.Size(FeltMetrics.CardWidth + 3 * 66f + 20, FeltMetrics.CardHeight);
                _fanClip = Ui.Node("FanCards", _fanHost).Fill();
                _fan = new CardFan(_fanClip);

                var row = Ui.HStack(_block, 8, null, TextAnchor.MiddleCenter, false, "Row");
                // Bet circle
                var bet = CircleBase(row, Theme.Gold.WithAlpha(0.45f), out _betRing);
                var betInner = Ui.VStack(bet, 2, null, TextAnchor.MiddleCenter, false);
                betInner.Fill();
                _betChip = Ui.Node("Chip", betInner).gameObject;
                var chipImg = _betChip.AddComponent<FlatImage>();
                chipImg.sprite = Sprites.Circle; chipImg.color = Theme.Gold; chipImg.raycastTarget = false;
                ((RectTransform)_betChip.transform).Size(30, 22);
                _betText = Ui.Text(betInner, "", 18, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Center, false);
                _betPlaceholder = Ui.Text(bet, "BET", 14, Theme.Gold.WithAlpha(0.5f), FontKind.Mono, TextAlignmentOptions.Center, false, 1f).gameObject;
                ((RectTransform)_betPlaceholder.transform).Fill();

                // Hand-total circle
                _totalCircle = CircleBase(row, Theme.Gold.WithAlpha(0.45f), out _totalRing);
                _totalText = Ui.Text(_totalCircle, "", 32, Theme.Gold, FontKind.MonoBold, TextAlignmentOptions.Center, false);
                _totalText.rectTransform.Fill();

                // Plate
                var inner = Ui.Card(row, Color.black.WithAlpha(0.64f), 26, Color.white.WithAlpha(0.1f), 1.5f, Ui.Pad(4, 4, 16, 4), 0, false, "Plate");
                Plate = (RectTransform)inner.parent;
                _plateOuter = Plate.GetComponent<Image>();
                _plateInner = inner.GetComponent<Image>();
                var prow = Ui.HStack(inner, 10, null, TextAnchor.MiddleLeft, false);
                var avatar = Ui.Box(prow, Theme.Gold, 0, "Avatar");
                avatar.sprite = Sprites.Circle; avatar.type = Image.Type.Simple;
                avatar.rectTransform.Size(52, 52);
                _avatarInitial = Ui.Text(avatar.transform, "G", 24, Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center, false);
                _avatarInitial.rectTransform.Fill();
                var col = Ui.VStack(prow, 0, null, TextAnchor.MiddleLeft, false);
                _handLabel = Ui.Text(col, "", 18, Theme.TextPrimary, FontKind.Sora, TextAlignmentOptions.Left, false);
                var bal = Ui.Text(col, "0", 24, Color.white, FontKind.MonoBold, TextAlignmentOptions.Left, false);
                _balance = CountUpText.Make(bal, 0);
            }

            private static RectTransform CircleBase(RectTransform parent, Color ring, out Image ringImage)
            {
                var outer = Ui.Box(parent, ring, 0, "Circle");
                outer.sprite = Sprites.Circle; outer.type = Image.Type.Simple;
                outer.rectTransform.Size(Circle, Circle);
                ringImage = outer;
                var fill = Ui.Box(outer.transform, Theme.Hex(0xFF1B1F1B), 0, "Fill");
                fill.sprite = Sprites.Circle; fill.type = Image.Type.Simple;
                fill.rectTransform.Fill(2, 2, 2, 2);
                fill.color = Color.Lerp(Theme.Gold.WithAlpha(0.10f), Color.black.WithAlpha(0.28f), 0.5f);
                var content = Ui.Node("Content", outer.transform).Fill(2, 2, 2, 2);
                return content;
            }

            public void Destroy() { if (_block != null) UnityEngine.Object.Destroy(_block.gameObject); }

            public void Refresh(AppState s, int index, bool active, bool split)
            {
                var r = s.Round;
                var hand = r.Hands[index];
                var n = hand.Cards.Count;
                var betAmount = hand.Bet != 0 ? hand.Bet : r.Bet;

                _fanHost.gameObject.SetActive(n > 0);
                if (n > 0)
                {
                    _fanHost.sizeDelta = new Vector2(FeltMetrics.CardWidth + (Mathf.Max(0, n - 1)) * 66f + 20, FeltMetrics.CardHeight);
                    _fan.Sync(hand.Cards, FeltMetrics.CardWidth, FeltMetrics.CardHeight, (card, ci, count) =>
                    {
                        // Cards overlap their predecessor by 24 units (the Flutter row's translate), and fan out 4° each.
                        var x = 20f + ci * FeltMetrics.CardWidth - (ci == 0 ? 0f : 24f) + FeltMetrics.CardWidth / 2f;
                        card.anchoredPosition = new Vector2(x - (count > 1 ? 0 : 0), -FeltMetrics.CardHeight / 2f);
                        card.localRotation = Quaternion.Euler(0, 0, -(ci - (count - 1) / 2f) * 4f);
                    });
                    var le = _fanHost.GetComponent<LayoutElement>();
                    le.preferredWidth = _fanHost.sizeDelta.x; le.minWidth = le.preferredWidth;
                }
                else _fan.Clear();

                var hasBet = betAmount > 0;
                _betChip.SetActive(hasBet);
                _betText.gameObject.SetActive(hasBet);
                _betPlaceholder.SetActive(!hasBet);
                _betText.text = "$" + TableCatalog.FormatChips(betAmount);

                _totalCircle.parent.gameObject.SetActive(n > 0);
                var busted = hand.Status == HandStatus.Busted;
                var blackjack = hand.Status == HandStatus.Blackjack;
                _totalRing.color = busted ? Theme.Lose.WithAlpha(0.6f) : blackjack ? Theme.Gold : Theme.Gold.WithAlpha(0.45f);
                _totalText.color = busted ? Theme.LoseLight : Theme.Gold;
                _totalText.text = BlackjackRules.HandValue(hand.Cards).ToString();

                Ui.StyleRing(_plateOuter, active ? Theme.Gold.WithAlpha(0.55f) : Color.white.WithAlpha(0.1f), 26, 1.5f);
                Ui.Style(_plateInner, active ? Theme.Gold.WithAlpha(0.16f) : Color.black.WithAlpha(0.64f), 24.5f);
                _handLabel.text = TableCalc.HandLabel(hand);
                _handLabel.color = active ? Theme.Gold : Theme.TextPrimary.WithAlpha(0.9f);
                _avatarInitial.text = s.DisplayName.Length > 0 ? s.DisplayName.Substring(0, 1).ToUpperInvariant() : "G";
                _balance.SetValue(r.Chips);
            }
        }
    }
}
