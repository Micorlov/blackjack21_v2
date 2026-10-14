using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The Seat felt: one 384 x 520 design canvas (see <see cref="FeltMetrics"/>) scaled to the room it is given,
    /// holding the table art, the dealer's fixtures and print, the dealer, the four opponents on the curve and the
    /// hero's own place. Built once; refreshed in place so cards animate alone.
    /// </summary>
    public sealed class FeltView
    {
        private const float RailOverhang = 40f;
        private const float FixtureInset = 18f;
        private const float PrintLineGap = 24f;
        private const float PrintRadius = 357f;
        private const float PrintHeight = 22f;

        private readonly GameController _g;
        private RectTransform _host, _canvas, _tray, _discard, _shoe, _placard, _print, _note;
        private RawImage _feltImage;
        private Material _feltMaterial;
        private Dyn _placardText;
        private DealerView _dealer;
        private readonly SeatView[] _seats = new SeatView[TableCatalog.OpponentSeats];
        private HeroView _hero;
        private FeltEffects _effects;
        private AppState _state;
        private Vector2 _lastSize;
        private FeltMetrics _metrics;

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

            BuildFixtures();
            BuildPrint();

            _dealer = new DealerView();
            _dealer.Build(_canvas);
            var seatsLayer = Ui.Node("Seats", _canvas).Fill();
            _hero = new HeroView();
            _hero.Build(_canvas);
            // Names and totals sit above every card, the hero's included, as on the design.
            var pillsLayer = Ui.Node("SeatPills", _canvas).Fill();
            for (var i = 0; i < _seats.Length; i++)
            {
                _seats[i] = new SeatView();
                _seats[i].Build(seatsLayer, pillsLayer, i);
            }
            _effects = new FeltEffects(_canvas);
        }

        /// <summary>The dealer's chip tray, the discard holder, the shoe, and the placard with the table limits.</summary>
        private void BuildFixtures()
        {
            _tray = Fixture("ChipTray", Gfx.ChipTray(), Gfx.TraySize);
            _discard = Fixture("Discard", Gfx.DiscardHolder(), Gfx.DiscardSize);
            _shoe = Fixture("Shoe", Gfx.Shoe(), Gfx.ShoeSize);

            var card = Ui.Card(_canvas, Theme.Ivory, Theme.Xxs, null, 0, Ui.Pad(Theme.Sm, Theme.Xs), 0, false, "Placard");
            _placard = card;
            _placard.FitContent(true, true);
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            _placardText = new Dyn(card);
        }

        private RectTransform Fixture(string name, Sprite art, Vector2 size)
        {
            var img = Ui.Box(_canvas, Color.white, 0, name);
            img.sprite = art;
            img.type = Image.Type.Simple;
            img.rectTransform.sizeDelta = size;
            return img.rectTransform;
        }

        /// <summary>The print on the felt, bent along the table's curve.</summary>
        private void BuildPrint()
        {
            _print = Ui.Text(_canvas, Loc.T("feltPaysThreeToTwo"), Type.FeltPrint, Theme.FeltPrint, TextAlignmentOptions.Center, false, 0, "Print").rectTransform;
            ArcText.Apply(_print.GetComponent<TMP_Text>(), PrintRadius);
            _note = Ui.Text(_canvas, Loc.T("feltDealerStands"), Type.FeltNote, Theme.Ivory, TextAlignmentOptions.Center, false, 0, "Note").rectTransform;
            ArcText.Apply(_note.GetComponent<TMP_Text>(), PrintRadius);
        }

        public void Refresh(AppState state)
        {
            _state = state;
            Relayout();
        }

        public void Tick()
        {
            if (_host == null) return;
            if (_host.rect.size != _lastSize) Relayout();
            _dealer.Tick();
            _effects.Tick();
        }

        private void Relayout()
        {
            if (_state == null) return;
            var size = _host.rect.size;
            if (size.x < 8 || size.y < 8) return;
            _lastSize = size;

            var r = _state.Round;
            var m = FeltMetrics.For(size.x, size.y);
            _metrics = m;

            _canvas.sizeDelta = new Vector2(m.CanvasWidth, m.CanvasHeight);
            _canvas.localScale = Vector3.one * m.Scale;
            _canvas.anchoredPosition = Vector2.zero;
            _feltMaterial.SetVector("_Canvas", new Vector4(m.CanvasWidth, m.CanvasHeight, 0, 0));
            _feltMaterial.SetVector("_Rail", new Vector4(m.Y(FeltMetrics.RailSide), m.Y(FeltMetrics.RailMiddle), RailOverhang, FeltMetrics.WoodEdge));

            LayoutFixtures(m, r.Stake);

            var printWidth = m.ContentWidth - 2 * Theme.Space48;
            _print.At(m.CentreX, m.Y(FeltMetrics.PrintTop));
            _print.sizeDelta = new Vector2(printWidth, PrintHeight);
            _note.At(m.CentreX, m.Y(FeltMetrics.PrintTop) + PrintLineGap);
            _note.sizeDelta = new Vector2(printWidth, PrintHeight);

            _dealer.Refresh(_state, m);
            var friends = Roster.TableSeats(_state.Friends, r.Stake?.Key);
            for (var i = 0; i < _seats.Length; i++) _seats[i].Refresh(_state, m, i < friends.Count ? friends[i] : null);
            _hero.Refresh(_state, m);
            _effects.Refresh(_state, m);
        }

        private void LayoutFixtures(FeltMetrics m, TableStake stake)
        {
            var left = m.Inset + FixtureInset;
            var right = m.Inset + m.ContentWidth - FixtureInset;
            _tray.At(m.CentreX, FeltMetrics.WoodEdge + Theme.Xs + Theme.Xxs);
            _discard.At(left + Theme.Xs, FeltMetrics.WoodEdge - Theme.Xxs, new Vector2(0, 1));
            _shoe.At(right, FeltMetrics.FixturesTop, new Vector2(1, 1));
            _placard.At(left - Theme.Xs, m.Y(FeltMetrics.PlacardTop), new Vector2(0, 1));
            _placard.gameObject.SetActive(stake != null);
            _placardText.Update(stake == null ? "" : $"{stake.Key}|{Loc.Code}", host =>
            {
                if (stake == null) return;
                PlacardLine(host, "feltMin", stake.Min);
                PlacardLine(host, "feltMax", stake.Max);
            });
        }

        private static void PlacardLine(RectTransform host, string key, int amount) =>
            Ui.Text(host, Loc.T(key, ("amount", "$" + TableCatalog.FormatChips(amount))), Type.Numeral(Type.Floor),
                Theme.PillInk, TextAlignmentOptions.Center, false);
    }
}
