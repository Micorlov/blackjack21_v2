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

        /// <summary>A card face. The returned node is the layout-sized root; its first child carries the animation.</summary>
        public static RectTransform Face(Transform parent, PlayingCard card, float width, float height, bool shadow = true)
        {
            var root = Ui.Node("Card", parent);
            root.Size(width, height);
            var anim = Ui.Node("Anim", root).Fill();
            var scale = width / 58f;
            if (shadow) AddShadow(anim, width, height, scale, 0.42f, 28f, 7f);

            var face = Ui.Box(anim, Color.white, 0, "Face");
            face.sprite = Gfx.CardFace();
            face.type = Image.Type.Simple;
            face.rectTransform.Fill();

            var color = card.IsRed ? Theme.CardRed : Theme.CardBlack;
            var rank = Ui.Text(anim, card.Rank, 25 * scale, color, FontKind.SoraBold, TextAlignmentOptions.TopLeft, false, 0, 0, "Rank");
            rank.rectTransform.IgnoreLayout();
            rank.rectTransform.Pin(new Vector2(0, 1), new Vector2(0, 1), new Vector2(6.5f * scale, 0f), new Vector2(40 * scale, 34 * scale));

            var pip = Ui.Box(anim, color, 0, "Pip");
            pip.sprite = Sprites.Suit(card.Suit);
            pip.type = Image.Type.Simple;
            pip.rectTransform.IgnoreLayout();
            pip.rectTransform.Pin(new Vector2(0, 1), new Vector2(0, 1), new Vector2(9 * scale, -34 * scale), new Vector2(15 * scale, 15 * scale));

            var big = Ui.Box(anim, color, 0, "BigPip");
            big.sprite = Sprites.Suit(card.Suit);
            big.type = Image.Type.Simple;
            big.rectTransform.IgnoreLayout();
            big.rectTransform.Pin(new Vector2(1, 0), new Vector2(1, 0), new Vector2(-6 * scale, 6 * scale), new Vector2(30 * scale, 30 * scale));
            return root;
        }

        public static RectTransform Back(Transform parent, float width, float height, bool shadow = true)
        {
            var root = Ui.Node("CardBack", parent);
            root.Size(width, height);
            var anim = Ui.Node("Anim", root).Fill();
            var scale = width / 58f;
            if (shadow) AddShadow(anim, width, height, scale, 0.5f, 34f, 12f);
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
