using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The two celebrations on the felt: confetti thrown from the hero's seat for a natural or a table sweep,
    /// and chips flying from each beaten seat to the hero's plate. Both ignore pointers.
    /// </summary>
    public sealed class FeltEffects
    {
        private const float ConfettiSeconds = 1.4f;
        private const float FlightSeconds = 0.75f;
        private const float FlightStagger = 0.09f;
        private const int ParticleCount = 60;
        private const float Gravity = 1.35f;

        /// <summary>How far below a seat's name pill its bet ring sits.</summary>
        private const float SeatRingDrop = 96f;

        private sealed class Particle
        {
            public RectTransform Rt; public Image Image; public float Angle, Speed, Spin, Delay;
        }

        private sealed class Flight
        {
            public RectTransform Rt; public CanvasGroup Group; public Vector2 From, To; public int Index;
        }

        private readonly RectTransform _layer;
        private readonly List<Particle> _particles = new List<Particle>();
        private readonly List<Flight> _flights = new List<Flight>();
        private float _confettiStart = -10f;
        private float _flightStart = -10f;
        private Vector2 _confettiOrigin;
        private float _reach;
        private string _firedToken = "";

        private static readonly Color[] Palette =
        {
            Theme.Gold, Theme.GoldLight, Theme.Win, Theme.TextPrimary, Theme.GoldDark,
        };

        public FeltEffects(RectTransform canvas)
        {
            _layer = Ui.Node("Effects", canvas).Fill();
        }

        public void Refresh(AppState s, FeltMetrics m)
        {
            RefreshRibbon(s.Round, m);
            RefreshFloat(s.Round, m);
            var r = s.Round;
            if (r.Phase != RoundPhase.Settlement) { Clear(); _firedToken = ""; return; }

            var token = r.Message + "|" + r.RoundNet + "|" + (r.SweepInfo?.TotalWin ?? 0) + "|" + r.Stats.HandsPlayed;
            if (token == _firedToken) return;
            _firedToken = token;

            if (DeservesConfetti(r))
            {
                _confettiOrigin = new Vector2(m.CentreX, m.Y(FeltMetrics.HeroCardsTop));
                _reach = Mathf.Min(m.CanvasWidth, m.CanvasHeight);
                StartConfetti();
            }
            if (r.SweepInfo != null && r.SweepInfo.HeroTook) StartFlights(s, m);
        }

        private static bool DeservesConfetti(RoundState r)
        {
            var blackjack = r.Hands.Any(h => h.Status == HandStatus.Blackjack);
            if (blackjack && r.MessageType == MessageType.Win) return true;
            return r.SweepInfo != null && r.SweepInfo.HeroTook && r.SweepAmount > 0;
        }

        private void Clear()
        {
            foreach (var p in _particles) if (p.Rt != null) Object.Destroy(p.Rt.gameObject);
            foreach (var f in _flights) if (f.Rt != null) Object.Destroy(f.Rt.gameObject);
            _particles.Clear(); _flights.Clear();
            _confettiStart = _flightStart = -10f;
        }

        // ---- confetti -------------------------------------------------------------------------------

        private void StartConfetti()
        {
            foreach (var p in _particles) if (p.Rt != null) Object.Destroy(p.Rt.gameObject);
            _particles.Clear();
            for (var i = 0; i < ParticleCount; i++)
            {
                var wide = Random.value > 0.5f;
                var size = 5f + Random.value * 6f;
                var img = Ui.Box(_layer, Palette[Random.Range(0, Palette.Length)], 0, "Confetti");
                img.rectTransform.Pin(new Vector2(0, 1), new Vector2(0.5f, 0.5f), Vector2.zero,
                    new Vector2(wide ? size : size * 0.55f, size));
                _particles.Add(new Particle
                {
                    Rt = img.rectTransform, Image = img,
                    // Fired upward and outward in a fan, so the burst reads as thrown rather than as rain.
                    Angle = -Mathf.PI / 2f + (Random.value - 0.5f) * 2.2f,
                    Speed = 0.55f + Random.value * 0.75f,
                    Spin = (Random.value - 0.5f) * 12f,
                    Delay = Random.value * 0.15f,
                });
            }
            _confettiStart = Time.unscaledTime;
        }

        // ---- chip flight ------------------------------------------------------------------------------

        private void StartFlights(AppState s, FeltMetrics m)
        {
            foreach (var f in _flights) if (f.Rt != null) Object.Destroy(f.Rt.gameObject);
            _flights.Clear();
            var info = s.Round.SweepInfo;
            var seats = Roster.TableSeats(s.Friends, s.Round.Stake?.Key);
            // Every chip lands in the hero's bet ring; each starts from its seat's own ring on the curve.
            var target = new Vector2(m.CentreX, m.Y(FeltMetrics.BetTop));

            var index = 0;
            foreach (var c in info.Contributors)
            {
                var seat = seats.ToList().FindIndex(f => f.FirstName == c.Name);
                if (seat < 0 || seat >= 4) continue;
                var place = m.SeatSlot(seat);
                var from = new Vector2(place.X, place.Y + SeatRingDrop);
                var chip = W.ChipDisc(_layer, FeltBits.StacksFor(c.Amount).Select(st => st.colour).DefaultIfEmpty(Theme.ChipRed).First(), 30f);
                chip.Pin(new Vector2(0, 1), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(30, 30));
                chip.IgnoreLayout();
                var group = chip.Ensure<CanvasGroup>();
                group.alpha = 0;
                _flights.Add(new Flight { Rt = chip, Group = group, From = from, To = target, Index = index++ });
            }
            _flightStart = Time.unscaledTime;
        }

        public void Tick()
        {
            TickConfetti();
            TickFlights();
            TickRibbon();
            TickFloat();
        }

        // ---- ribbons --------------------------------------------------------------------------------

        private const float RibbonPop = 0.25f;
        private const float RibbonHold = 2.2f;
        private const float RibbonFade = 0.4f;
        private const float RibbonDrop = 10f;
        private const float FloatRise = Theme.Md;
        private const float FloatSeconds = 0.6f;

        private RectTransform _ribbon, _float;

        /// <summary>True while a ribbon is on the felt, so the print under it can step aside.</summary>
        public bool RibbonShowing => _ribbon != null && _ribbonGroup != null && _ribbonGroup.alpha > 0.01f;
        private CanvasGroup _ribbonGroup, _floatGroup;
        private string _ribbonToken = "", _floatToken = "";
        private float _ribbonStart = -10f, _floatStart = -10f;
        private Vector2 _floatAt;

        /// <summary>The banner the design pins over the felt print when something happens to the hero's hand.</summary>
        private static (string token, string title, string detail, bool loss) RibbonFor(RoundState r)
        {
            if (r.Phase == RoundPhase.Settlement || r.Phase == RoundPhase.Betting) return ("", null, null, false);
            var hand = r.Hands[0];
            var bet = "$" + TableCatalog.FormatChips(hand.Bet);
            if (r.Hands.Count > 1)
                return ("split" + r.Hands[1].Bet, Loc.T("ribbonSplit"), "2 × $" + TableCatalog.FormatChips(r.Hands[1].Bet), false);
            if (hand.Status == HandStatus.Blackjack) return ("bj", Loc.T("ribbonBlackjack"), Loc.T("ribbonPays"), false);
            if (hand.Status == HandStatus.Busted) return ("bust" + hand.Bet, Loc.T("ribbonBusted"), "−" + bet, true);
            if (hand.Doubled) return ("double" + hand.Bet, Loc.T("ribbonDoubleDown"), bet, false);
            return ("", null, null, false);
        }

        private void RefreshRibbon(RoundState r, FeltMetrics m)
        {
            var (token, title, detail, loss) = RibbonFor(r);
            if (token == _ribbonToken)
            {
                if (_ribbon != null) _ribbon.At(m.CentreX, m.Y(FeltMetrics.PrintTop) - RibbonDrop);
                return;
            }
            _ribbonToken = token;
            if (_ribbon != null) Object.Destroy(_ribbon.gameObject);
            _ribbon = null;
            if (token.Length == 0) return;

            var row = FeltBits.Pill(_layer, loss ? Theme.LoseOnFelt : Theme.BrassLight, out var root, null, "Ribbon", Theme.Lg, Theme.Xs);
            Ui.Text(row, title, new TextStyle(15, Type.FeltPrint.Font, Type.FeltPrint.Tracking), Theme.PillInk, TextAlignmentOptions.Center, false);
            Ui.Text(row, detail, Type.Numeral(Type.Floor), Theme.PillInk, TextAlignmentOptions.Center, false);
            root.At(m.CentreX, m.Y(FeltMetrics.PrintTop) - RibbonDrop);
            _ribbon = root;
            _ribbonGroup = root.Ensure<CanvasGroup>();
            _ribbonGroup.alpha = 0f;
            _ribbonStart = Time.unscaledTime;
        }

        private void TickRibbon()
        {
            if (_ribbon == null) return;
            var t = Time.unscaledTime - _ribbonStart;
            var pop = Mathf.Clamp01(t / RibbonPop);
            _ribbon.localScale = Vector3.one * Mathf.Lerp(0.8f, 1f, 1f - Mathf.Pow(1f - pop, 3f));
            _ribbonGroup.alpha = t < RibbonPop + RibbonHold ? pop : Mathf.Clamp01(1f - (t - RibbonPop - RibbonHold) / RibbonFade);
        }

        /// <summary>The round's result, floated up from the hero's bet ring: "+$400" in green, "−$100" in red.</summary>
        private void RefreshFloat(RoundState r, FeltMetrics m)
        {
            var token = r.Phase == RoundPhase.Settlement && r.RoundNet != 0 ? r.RoundNet + "|" + r.Stats.HandsPlayed : "";
            // Over the hero's bet ring, clear of the index at the foot of the cards.
            _floatAt = new Vector2(m.CentreX, m.Y(FeltMetrics.BetTop) + Theme.Xs);
            if (token == _floatToken) return;
            _floatToken = token;
            if (_float != null) Object.Destroy(_float.gameObject);
            _float = null;
            if (token.Length == 0) return;

            var won = r.RoundNet > 0;
            var row = FeltBits.Pill(_layer, Color.black.WithAlpha(0.72f), out var root, null, "Float", Theme.Md, Theme.Xxs);
            Ui.Text(row, (won ? "+$" : "−$") + TableCatalog.FormatChips(Mathf.Abs(r.RoundNet)), Type.Numeral(18),
                won ? Theme.WinLight : Theme.LoseOnFelt, TextAlignmentOptions.Center, false);
            _float = root;
            _floatGroup = root.Ensure<CanvasGroup>();
            _floatStart = Time.unscaledTime;
            TickFloat();
        }

        private void TickFloat()
        {
            if (_float == null) return;
            var t = Mathf.Clamp01((Time.unscaledTime - _floatStart) / FloatSeconds);
            var eased = 1f - Mathf.Pow(1f - t, 3f);
            _float.At(_floatAt.x, _floatAt.y - FloatRise * eased);
            _floatGroup.alpha = eased;
        }

        private void TickConfetti()
        {
            if (_particles.Count == 0) return;
            var progress = (Time.unscaledTime - _confettiStart) / ConfettiSeconds;
            if (progress >= 1f)
            {
                foreach (var p in _particles) if (p.Rt != null) Object.Destroy(p.Rt.gameObject);
                _particles.Clear();
                return;
            }
            foreach (var p in _particles)
            {
                var t = Mathf.Clamp01((progress - p.Delay) / (1f - p.Delay));
                if (t <= 0f) { p.Image.enabled = false; continue; }
                p.Image.enabled = true;
                var dx = Mathf.Cos(p.Angle) * p.Speed * _reach * t;
                var dy = Mathf.Sin(p.Angle) * p.Speed * _reach * t + Gravity * _reach * t * t;
                // Held at full opacity for most of the flight, then faded.
                var opacity = t < 0.7f ? 1f : 1f - (t - 0.7f) / 0.3f;
                p.Rt.anchoredPosition = new Vector2(_confettiOrigin.x + dx, -(_confettiOrigin.y + dy));
                p.Rt.localRotation = Quaternion.Euler(0, 0, -p.Spin * t * Mathf.Rad2Deg);
                var c = p.Image.color; c.a = Mathf.Clamp01(opacity); p.Image.color = c;
            }
        }

        private void TickFlights()
        {
            if (_flights.Count == 0) return;
            var progress = (Time.unscaledTime - _flightStart) / FlightSeconds;
            if (progress >= 1f + FlightStagger * _flights.Count)
            {
                foreach (var f in _flights) if (f.Rt != null) Object.Destroy(f.Rt.gameObject);
                _flights.Clear();
                return;
            }
            foreach (var f in _flights)
            {
                var offset = FlightStagger * f.Index / FlightSeconds;
                var t = Mathf.Clamp01((progress - offset) / (1f - offset));
                if (t <= 0f) { f.Group.alpha = 0; continue; }
                var eased = 1f - Mathf.Pow(1f - t, 3f);
                var pos = Vector2.Lerp(f.From, f.To, eased);
                // Lifted off the felt mid-flight and set back down, so the chip arcs.
                var lift = -28f * (1f - Mathf.Abs(2f * eased - 1f));
                f.Rt.anchoredPosition = new Vector2(pos.x, -(pos.y + lift));
                f.Group.alpha = t > 0.85f ? 1f - (t - 0.85f) / 0.15f : 1f;
            }
        }
    }
}
