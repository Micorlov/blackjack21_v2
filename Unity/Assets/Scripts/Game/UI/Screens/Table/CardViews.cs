using System;
using System.Collections.Generic;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>Playing-card visuals: the cream face with its rank and suits, the gold-striped back, soft shadows.</summary>
    public static class CardViews
    {
        private static void AddShadow(RectTransform host, float w, float h, float scale, float alpha, float blur, float offset)
        {
            var shadow = Ui.Box(host, Color.black.WithAlpha(alpha), 0, "Shadow");
            shadow.sprite = Gfx.SoftShadow();
            shadow.type = Image.Type.Sliced;
            shadow.pixelsPerUnitMultiplier = 3f / Mathf.Max(0.5f, scale);
            var pad = blur * scale;
            shadow.rectTransform.IgnoreLayout();
            shadow.rectTransform.Pin(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0, -offset * scale),
                new Vector2(w + pad, h + pad));
        }

        // The design's card shadow: a drop of 4% of the width, blurred over 10% on each side. Wider, it greys the
        // corner index of the card beneath.
        private const float CardShadowBlur = 58f * 0.2f;
        private const float CardShadowDrop = 58f * 0.04f;

        /// <summary>Below this width a card is drawn compact (the other seats' cards): one corner index, the pip low.</summary>
        private const float CompactBelow = 60f;

        /// <summary>The mirrored bottom-right index only fits clear of the centre pip on a card this wide (the hero's).</summary>
        private const float MirroredIndexFrom = 80f;

        private static readonly Color CourtBorder = new Color(150 / 255f, 110 / 255f, 40 / 255f, 0.75f);
        private static readonly Color CourtFill = Theme.Hex(0xFFF7E9C4);

        /// <summary>
        /// A card face in the Seat's classic style: the rank and suit in the corner (mirrored in the opposite one on
        /// full-size cards), a large centre pip, and a framed panel for the court cards. Ranks are Sora and never
        /// smaller than <see cref="Type.Floor"/>. The returned node is the layout-sized root; its first child
        /// carries the animation.
        /// </summary>
        public static RectTransform Face(Transform parent, PlayingCard card, float width, float height, bool shadow = true)
        {
            var root = Ui.Node("Card", parent);
            root.Size(width, height);
            var anim = Ui.Node("Anim", root).Fill();
            var scale = width / 58f;
            if (shadow) AddShadow(anim, width, height, scale, 0.42f, CardShadowBlur, CardShadowDrop);

            var face = Ui.Box(anim, Color.white, 0, "Face");
            face.sprite = Gfx.CardFace();
            face.type = Image.Type.Simple;
            face.rectTransform.Fill();

            var color = card.IsRed ? Theme.CardRed : Theme.CardBlack;
            var compact = width < CompactBelow;
            Index(anim, card, color, width, compact, mirrored: false);
            if (width >= MirroredIndexFrom) Index(anim, card, color, width, compact, mirrored: true);

            var court = card.Rank == "J" || card.Rank == "Q" || card.Rank == "K";
            if (court) Court(anim, card, color, width, height, compact);
            else Pip(anim, card.Suit, color, width, height, compact);
            return root;
        }

        private static void Index(RectTransform anim, PlayingCard card, Color color, float w, bool compact, bool mirrored)
        {
            var corner = Ui.Node(mirrored ? "IndexBR" : "Index", anim);
            corner.IgnoreLayout();
            var rankSize = Mathf.Max(Type.Floor, w * (compact ? 0.34f : 0.3f));
            var suitSize = w * (compact ? 0.26f : 0.19f);
            var boxW = Mathf.Max(w * 0.3f, rankSize * (card.Rank == "10" ? 1.25f : 0.8f));
            var boxH = rankSize + suitSize + w * 0.02f;
            // Pinned by its centre so the mirrored copy turns in place rather than swinging out past the corner.
            var anchor = mirrored ? new Vector2(1, 0) : new Vector2(0, 1);
            var inset = new Vector2(w * 0.035f + boxW / 2f, w * 0.06f + boxH / 2f);
            corner.Pin(anchor, new Vector2(0.5f, 0.5f), mirrored ? new Vector2(-inset.x, inset.y) : new Vector2(inset.x, -inset.y), new Vector2(boxW, boxH));
            if (mirrored) corner.localRotation = Quaternion.Euler(0, 0, 180);

            var rank = Ui.Text(corner, card.Rank, rankSize, color, FontKind.SoraBold, TextAlignmentOptions.Top, false, -6f, 0, "Rank");
            rank.rectTransform.IgnoreLayout();
            rank.rectTransform.Pin(new Vector2(0.5f, 1), new Vector2(0.5f, 1), Vector2.zero, new Vector2(boxW, rankSize * 1.05f));
            var pip = Ui.Box(corner, color, 0, "Pip");
            pip.sprite = Sprites.Suit(card.Suit);
            pip.type = Image.Type.Simple;
            pip.preserveAspect = true;
            pip.rectTransform.IgnoreLayout();
            pip.rectTransform.Pin(new Vector2(0.5f, 1), new Vector2(0.5f, 1), new Vector2(0, -rankSize - w * 0.02f), new Vector2(suitSize, suitSize));
        }

        private static void Pip(RectTransform anim, string suit, Color color, float w, float h, bool compact)
        {
            var size = w * (compact ? 0.5f : 0.52f);
            var big = Ui.Box(anim, color, 0, "BigPip");
            big.sprite = Sprites.Suit(suit);
            big.type = Image.Type.Simple;
            big.preserveAspect = true;
            big.rectTransform.IgnoreLayout();
            // A compact card shows its pip low and to the right, clear of the corner index the next card leaves showing.
            var offset = compact ? new Vector2(w * 0.11f, -h * 0.14f) : Vector2.zero;
            big.rectTransform.PinCentre(offset, new Vector2(size, size));
        }

        private static void Court(RectTransform anim, PlayingCard card, Color color, float w, float h, bool compact)
        {
            // The design's court panel: inset 17%/21% on a full card, tucked bottom-right on a compact one.
            var panel = Ui.Node("Court", anim);
            panel.IgnoreLayout();
            if (compact) panel.Fill(w * 0.34f, h * 0.40f, w * 0.10f, h * 0.08f);
            else panel.Fill(w * 0.21f, h * 0.17f, w * 0.21f, h * 0.17f);
            var fill = Ui.Box(panel, CourtFill, Theme.Xxs, "Fill");
            fill.rectTransform.Fill();
            var line = Ui.Box(panel, CourtBorder, Theme.Xxs, "Border");
            Ui.StyleRing(line, CourtBorder, Theme.Xxs, 1f);
            line.rectTransform.Fill();
            var letter = Ui.Text(panel, card.Rank, Mathf.Max(Type.Floor, w * (compact ? 0.3f : 0.36f)), color, FontKind.SoraBold,
                TextAlignmentOptions.Center, false, 0, 0, "Letter");
            letter.rectTransform.IgnoreLayout();
            if (compact)
            {
                letter.rectTransform.Fill();
                return;
            }
            letter.rectTransform.Fill(0, 0, 0, h * 0.12f);
            var suit = Ui.Box(panel, color, 0, "Suit");
            suit.sprite = Sprites.Suit(card.Suit);
            suit.type = Image.Type.Simple;
            suit.preserveAspect = true;
            suit.rectTransform.IgnoreLayout();
            suit.rectTransform.Pin(new Vector2(0.5f, 0), new Vector2(0.5f, 0), new Vector2(0, h * 0.05f), new Vector2(w * 0.22f, w * 0.22f));
        }

        public static RectTransform Back(Transform parent, float width, float height, bool shadow = true)
        {
            var root = Ui.Node("CardBack", parent);
            root.Size(width, height);
            var anim = Ui.Node("Anim", root).Fill();
            var scale = width / 58f;
            if (shadow) AddShadow(anim, width, height, scale, 0.5f, CardShadowBlur, CardShadowDrop);
            var back = Ui.Box(anim, Color.white, 0, "Back");
            back.sprite = Gfx.CardBack();
            back.type = Image.Type.Simple;
            back.rectTransform.Fill();
            return root;
        }

        public static Transform AnimOf(RectTransform card) => card.Find("Anim");

        /// <summary>Eases a card in as it is dealt: it drops 12 units, un-tilts 4 degrees, scales .92→1 and fades in.</summary>
        public static void DealIn(RectTransform card)
        {
            var anim = AnimOf(card);
            if (anim == null) return;
            anim.gameObject.AddComponent<DealInAnimation>();
        }
    }

    /// <summary>The deal-in motion — the design's <c>bjDeal</c>, 350ms ease-out.</summary>
    public sealed class DealInAnimation : MonoBehaviour
    {
        private const float Duration = 0.35f;
        private float _start;
        private CanvasGroup _group;
        private RectTransform _rt;

        private void Awake()
        {
            _group = gameObject.AddComponent<CanvasGroup>();
            _rt = (RectTransform)transform;
            _start = Time.unscaledTime;
            Apply(0f);
        }

        private void Update()
        {
            var t = Mathf.Clamp01((Time.unscaledTime - _start) / Duration);
            Apply(1f - Mathf.Pow(1f - t, 3f));
            if (t >= 1f) Destroy(this);
        }

        private void Apply(float t)
        {
            _group.alpha = t;
            _rt.anchoredPosition = new Vector2(0, 12f * (1f - t));
            _rt.localRotation = Quaternion.Euler(0, 0, -4f * (1f - t));
            _rt.localScale = Vector3.one * (0.92f + 0.08f * t);
        }

        private void OnDestroy()
        {
            if (_group != null) { _group.alpha = 1; Destroy(_group); }
            if (_rt != null) { _rt.anchoredPosition = Vector2.zero; _rt.localRotation = Quaternion.identity; _rt.localScale = Vector3.one; }
        }
    }

    /// <summary>The dealer's hole card: face-down until revealed, then it turns over in place (500ms, eased).</summary>
    public sealed class FlipCard : MonoBehaviour
    {
        private const float Duration = 0.5f;
        private RectTransform _back, _face;
        private bool _revealed;
        private float _start = -1f;

        public static FlipCard Make(Transform parent, PlayingCard card, float w, float h, bool revealed)
        {
            var root = Ui.Node("HoleCard", parent);
            root.Size(w, h);
            var back = CardViews.Back(root, w, h);
            back.Fill();
            var face = CardViews.Face(root, card, w, h);
            face.Fill();
            var flip = root.gameObject.AddComponent<FlipCard>();
            flip._back = back; flip._face = face; flip._revealed = revealed;
            flip.Pose(revealed ? 1f : 0f);
            return flip;
        }

        public RectTransform Root => (RectTransform)transform;

        public void Set(bool revealed, PlayingCard card = default)
        {
            if (revealed == _revealed) return;
            _revealed = revealed;
            if (revealed) _start = Time.unscaledTime; else { _start = -1f; Pose(0f); }
        }

        private void Update()
        {
            if (_start < 0f) return;
            var t = Mathf.Clamp01((Time.unscaledTime - _start) / Duration);
            Pose(t);
            if (t >= 1f) _start = -1f;
        }

        private void Pose(float linear)
        {
            // Emphasised in/out cubic.
            var t = linear < 0.5f ? 4f * linear * linear * linear : 1f - Mathf.Pow(-2f * linear + 2f, 3f) / 2f;
            var faceUp = t >= 0.5f;
            _back.gameObject.SetActive(!faceUp);
            _face.gameObject.SetActive(faceUp);
            // rotateY(t*pi): the visible width follows |cos|, and the face is shown un-mirrored.
            var width = Mathf.Max(0.02f, Mathf.Abs(Mathf.Cos(t * Mathf.PI)));
            (faceUp ? _face : _back).localScale = new Vector3(width, 1f, 1f);
        }
    }

    /// <summary>
    /// A row of cards positioned by absolute offsets under one host. New cards animate in alone; a shorter
    /// hand (a new round) clears and rebuilds, so a card joining the fan never restarts the others.
    /// </summary>
    public sealed class CardFan
    {
        private readonly RectTransform _host;
        private readonly List<RectTransform> _cards = new List<RectTransform>();
        private readonly List<PlayingCard> _shown = new List<PlayingCard>();

        public CardFan(RectTransform host) { _host = host; }

        public int Count => _cards.Count;
        public IReadOnlyList<RectTransform> Cards => _cards;

        public void Clear()
        {
            foreach (var c in _cards) if (c != null) UnityEngine.Object.Destroy(c.gameObject);
            _cards.Clear();
            _shown.Clear();
        }

        /// <summary>Makes the fan show <paramref name="cards"/>. <paramref name="place"/> positions card i (anchored top-left, size w x h).</summary>
        public void Sync(IReadOnlyList<PlayingCard> cards, float w, float h, Action<RectTransform, int, int> place,
            Func<Transform, int, PlayingCard, RectTransform> create = null)
        {
            if (cards.Count < _cards.Count) Clear();
            for (var i = 0; i < cards.Count; i++)
            {
                if (i < _cards.Count)
                {
                    if (_shown[i].Equals(cards[i])) { place(_cards[i], i, cards.Count); continue; }
                    UnityEngine.Object.Destroy(_cards[i].gameObject);
                    _cards.RemoveAt(i); _shown.RemoveAt(i);
                }
                var card = create != null ? create(_host, i, cards[i]) : CardViews.Face(_host, cards[i], w, h);
                card.IgnoreLayout();
                card.anchorMin = card.anchorMax = new Vector2(0, 1);
                card.pivot = new Vector2(0.5f, 0.5f);
                card.sizeDelta = new Vector2(w, h);
                CardViews.DealIn(card);
                _cards.Insert(i, card);
                _shown.Insert(i, cards[i]);
                place(card, i, cards.Count);
            }
            // Re-place everything: the row's overall width depends on the count.
            for (var i = 0; i < _cards.Count; i++) place(_cards[i], i, cards.Count);
        }
    }
}
