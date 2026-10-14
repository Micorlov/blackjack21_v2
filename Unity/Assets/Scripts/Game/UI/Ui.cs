using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>Tiny builder DSL over uGUI: every screen is assembled in code, Flutter-style.</summary>
    public static class Ui
    {
        // ---- nodes and anchoring ----------------------------------------------------------------

        public static RectTransform Node(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            go.transform.SetParent(parent, false);
            return (RectTransform)go.transform;
        }

        /// <summary>Stretches the node over its parent, inset by the given margins.</summary>
        public static RectTransform Fill(this RectTransform rt, float left = 0, float top = 0, float right = 0, float bottom = 0)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = new Vector2(left, bottom);
            rt.offsetMax = new Vector2(-right, -top);
            return rt;
        }

        /// <summary>Places the node by anchor/pivot/position/size, for free-form layouts like the felt.</summary>
        public static RectTransform Pin(this RectTransform rt, Vector2 anchor, Vector2 pivot, Vector2 position, Vector2 size)
        {
            rt.anchorMin = anchor;
            rt.anchorMax = anchor;
            rt.pivot = pivot;
            rt.anchoredPosition = position;
            rt.sizeDelta = size;
            return rt;
        }

        public static RectTransform PinCentre(this RectTransform rt, Vector2 position, Vector2 size) =>
            rt.Pin(new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), position, size);

        /// <summary>Anchors along an edge of the parent: stretched horizontally, fixed height.</summary>
        public static RectTransform PinTop(this RectTransform rt, float height, float top = 0, float left = 0, float right = 0)
        {
            rt.anchorMin = new Vector2(0, 1);
            rt.anchorMax = new Vector2(1, 1);
            rt.pivot = new Vector2(0.5f, 1);
            rt.offsetMin = new Vector2(left, -top - height);
            rt.offsetMax = new Vector2(-right, -top);
            return rt;
        }

        public static RectTransform PinBottom(this RectTransform rt, float height, float bottom = 0, float left = 0, float right = 0)
        {
            rt.anchorMin = new Vector2(0, 0);
            rt.anchorMax = new Vector2(1, 0);
            rt.pivot = new Vector2(0.5f, 0);
            rt.offsetMin = new Vector2(left, bottom);
            rt.offsetMax = new Vector2(-right, bottom + height);
            return rt;
        }

        // ---- layout element helpers --------------------------------------------------------------

        public static T Ensure<T>(this Component c) where T : Component
        {
            var existing = c.GetComponent<T>();
            return existing != null ? existing : c.gameObject.AddComponent<T>();
        }

        /// <summary>Preferred and minimum size inside a layout group (null leaves that axis alone).</summary>
        public static RectTransform Size(this RectTransform rt, float? width = null, float? height = null)
        {
            var le = rt.Ensure<LayoutElement>();
            if (width.HasValue) { le.preferredWidth = width.Value; le.minWidth = width.Value; }
            if (height.HasValue) { le.preferredHeight = height.Value; le.minHeight = height.Value; }
            // Outside a layout group nothing reads the LayoutElement, so size the rect itself too.
            rt.sizeDelta = new Vector2(width ?? rt.sizeDelta.x, height ?? rt.sizeDelta.y);
            return rt;
        }

        public static RectTransform MinSize(this RectTransform rt, float? width = null, float? height = null)
        {
            var le = rt.Ensure<LayoutElement>();
            if (width.HasValue) le.minWidth = width.Value;
            if (height.HasValue) le.minHeight = height.Value;
            return rt;
        }

        /// <summary>Takes a share of the free space in a stack (Flutter's Expanded/flex).</summary>
        public static RectTransform Flex(this RectTransform rt, float weight = 1)
        {
            var le = rt.Ensure<LayoutElement>();
            le.flexibleWidth = weight;
            le.flexibleHeight = weight;
            return rt;
        }

        public static RectTransform FlexW(this RectTransform rt, float weight = 1)
        {
            rt.Ensure<LayoutElement>().flexibleWidth = weight;
            return rt;
        }

        public static RectTransform FlexH(this RectTransform rt, float weight = 1)
        {
            rt.Ensure<LayoutElement>().flexibleHeight = weight;
            return rt;
        }

        public static RectTransform IgnoreLayout(this RectTransform rt)
        {
            rt.Ensure<LayoutElement>().ignoreLayout = true;
            return rt;
        }

        public static RectTransform Spacer(Transform parent, float size = 0, float flex = 0)
        {
            var rt = Node("Spacer", parent);
            var le = rt.Ensure<LayoutElement>();
            le.preferredWidth = size; le.preferredHeight = size;
            le.minWidth = size; le.minHeight = size;
            le.flexibleWidth = flex; le.flexibleHeight = flex;
            return rt;
        }

        public static TextAnchor MirrorAnchor(TextAnchor a)
        {
            switch (a)
            {
                case TextAnchor.UpperLeft: return TextAnchor.UpperRight;
                case TextAnchor.UpperRight: return TextAnchor.UpperLeft;
                case TextAnchor.MiddleLeft: return TextAnchor.MiddleRight;
                case TextAnchor.MiddleRight: return TextAnchor.MiddleLeft;
                case TextAnchor.LowerLeft: return TextAnchor.LowerRight;
                case TextAnchor.LowerRight: return TextAnchor.LowerLeft;
                default: return a;
            }
        }

        // ---- stacks --------------------------------------------------------------------------------

        public static RectOffset Pad(float all) => new RectOffset((int)all, (int)all, (int)all, (int)all);
        public static RectOffset Pad(float horizontal, float vertical) =>
            new RectOffset((int)horizontal, (int)horizontal, (int)vertical, (int)vertical);
        public static RectOffset Pad(float left, float top, float right, float bottom) =>
            new RectOffset((int)left, (int)right, (int)top, (int)bottom);

        /// <summary>A vertical stack. <paramref name="stretch"/> widens children to the stack; false lets them keep their width.</summary>
        public static RectTransform VStack(Transform parent, float spacing = 0, RectOffset padding = null,
            TextAnchor align = TextAnchor.UpperLeft, bool stretch = true, string name = "VStack")
        {
            var rt = Node(name, parent);
            var g = rt.gameObject.AddComponent<VerticalLayoutGroup>();
            g.spacing = spacing;
            g.padding = padding ?? new RectOffset();
            g.childAlignment = Loc.IsRtl ? MirrorAnchor(align) : align;
            g.childControlWidth = true;
            g.childControlHeight = true;
            g.childForceExpandWidth = stretch;
            g.childForceExpandHeight = false;
            return rt;
        }

        public static RectTransform HStack(Transform parent, float spacing = 0, RectOffset padding = null,
            TextAnchor align = TextAnchor.MiddleLeft, bool stretch = false, string name = "HStack")
        {
            var rt = Node(name, parent);
            var g = rt.gameObject.AddComponent<HorizontalLayoutGroup>();
            g.spacing = spacing;
            g.padding = padding ?? new RectOffset();
            // Right-to-left languages read a row from the right: reverse its order and mirror its alignment.
            g.reverseArrangement = Loc.IsRtl;
            g.childAlignment = Loc.IsRtl ? MirrorAnchor(align) : align;
            g.childControlWidth = true;
            g.childControlHeight = true;
            g.childForceExpandWidth = false;
            // Never force-expand height: a flexible row makes every group above it report itself as flexible and
            // balloon to the whole screen. Rows that should match heights simply share padding.
            g.childForceExpandHeight = false;
            return rt;
        }

        /// <summary>Makes a node grow to fit its children (for scroll content and auto-height cards).</summary>
        public static RectTransform FitContent(this RectTransform rt, bool vertical = true, bool horizontal = false)
        {
            var f = rt.Ensure<ContentSizeFitter>();
            f.verticalFit = vertical ? ContentSizeFitter.FitMode.PreferredSize : ContentSizeFitter.FitMode.Unconstrained;
            f.horizontalFit = horizontal ? ContentSizeFitter.FitMode.PreferredSize : ContentSizeFitter.FitMode.Unconstrained;
            return rt;
        }

        // ---- boxes ----------------------------------------------------------------------------------

        /// <summary>A solid or rounded rectangle image on its own node.</summary>
        public static Image Box(Transform parent, Color color, float radius = 0, string name = "Box")
        {
            var rt = Node(name, parent);
            var img = rt.gameObject.AddComponent<FlatImage>();
            Style(img, color, radius);
            return img;
        }

        public static void Style(Image img, Color color, float radius)
        {
            img.color = color;
            img.raycastTarget = false;
            var fit = img.GetComponent<RoundedFit>();
            if (radius <= 0.01f)
            {
                if (fit != null) UnityEngine.Object.Destroy(fit);
                img.sprite = null;
                img.type = Image.Type.Simple;
                return;
            }
            img.sprite = Sprites.Rounded;
            img.type = Image.Type.Sliced;
            if (fit == null) fit = img.gameObject.AddComponent<RoundedFit>();
            fit.Radius = radius;
            fit.Apply();
        }

        /// <summary>Styles an image as a rounded outline: transparent inside, <paramref name="thickness"/> units wide.</summary>
        public static void StyleRing(Image img, Color color, float radius, float thickness)
        {
            img.color = color;
            img.raycastTarget = false;
            img.sprite = Sprites.RoundedRing(thickness * Sprites.RoundedBorder / Mathf.Max(1f, radius));
            img.type = Image.Type.Sliced;
            var fit = img.GetComponent<RoundedFit>();
            if (fit == null) fit = img.gameObject.AddComponent<RoundedFit>();
            fit.Radius = radius;
            fit.RingThickness = thickness;
            fit.Apply();
        }

        /// <summary>
        /// A filled rounded panel with an optional border, laid out as a vertical stack. Returns the inner
        /// content node; its parent chain already participates in layout.
        /// </summary>
        public static RectTransform Card(Transform parent, Color fill, float radius = Theme.RadiusLg,
            Color? border = null, float borderWidth = 1, RectOffset padding = null, float spacing = 0,
            bool stretch = true, string name = "Card")
        {
            // In a horizontal row a card sizes to its content; rows give a card a share explicitly with FlexW.
            if (parent.GetComponent<HorizontalLayoutGroup>() != null) stretch = false;

            // The inner panel always fills its border. Whether the whole card may grow is stated on the outermost
            // node's LayoutElement, because a layout group otherwise reports itself flexible whenever its child is.
            RectTransform outermost = null;
            Transform host = parent;
            if (border.HasValue)
            {
                var outer = Box(parent, border.Value, radius, name + "Border");
                StyleRing(outer, border.Value, radius, borderWidth);
                var g = outer.gameObject.AddComponent<VerticalLayoutGroup>();
                g.padding = Pad(borderWidth);
                g.childControlWidth = true; g.childControlHeight = true;
                g.childForceExpandWidth = true; g.childForceExpandHeight = false;
                host = outer.transform;
                outermost = outer.rectTransform;
            }
            var inner = Box(host, fill, Mathf.Max(0, border.HasValue ? radius - borderWidth : radius), name);
            if (!border.HasValue) outermost = inner.rectTransform;
            var ig = inner.gameObject.AddComponent<VerticalLayoutGroup>();
            ig.padding = padding ?? new RectOffset();
            ig.spacing = spacing;
            ig.childControlWidth = true; ig.childControlHeight = true;
            ig.childForceExpandWidth = stretch; ig.childForceExpandHeight = false;
            if (!stretch) outermost.Ensure<LayoutElement>().flexibleWidth = 0;
            return inner.rectTransform;
        }

        // ---- text -----------------------------------------------------------------------------------

        public static UiText Text(Transform parent, string text, float size, Color color,
            FontKind font = FontKind.Sora, TextAlignmentOptions align = TextAlignmentOptions.TopLeft,
            bool wrap = true, float spacing = 0, float lineSpacing = 0, string name = "Text")
        {
            var rt = Node(name, parent);
            var t = rt.gameObject.AddComponent<UiText>();
            t.font = Fonts.Get(font);
            t.fontSize = size;
            t.color = color;
            t.SetAlignment(align);
            t.SetSpacing(spacing);
            t.lineSpacing = lineSpacing;
            t.textWrappingMode = wrap ? TextWrappingModes.Normal : TextWrappingModes.NoWrap;
            t.overflowMode = TextOverflowModes.Overflow;
            t.raycastTarget = false;
            t.richText = true;
            t.text = text;
            if (!wrap)
            {
                // One-line labels get a fixed line box like the Flutter design's `height:` values: the monospace
                // font's natural line is far taller than the 1.15 the design specifies.
                var mono = font == FontKind.Mono || font == FontKind.MonoBold;
                var box = size * (mono ? 1.15f : 1.28f);
                t.rectTransform.Size(null, box);
                t.SetAlignment(ToMiddle(align));
            }
            return t;
        }

        private static TextAlignmentOptions ToMiddle(TextAlignmentOptions a)
        {
            switch (a)
            {
                case TextAlignmentOptions.TopLeft: return TextAlignmentOptions.Left;
                case TextAlignmentOptions.Top: return TextAlignmentOptions.Center;
                case TextAlignmentOptions.TopRight: return TextAlignmentOptions.Right;
                default: return a;
            }
        }

        // ---- interaction ----------------------------------------------------------------------------

        /// <summary>
        /// Lets a one-line label shrink to fit the room it is given instead of overflowing — Flutter's
        /// FittedBox(scaleDown). Used instead of ellipsis, which TMP applies unreliably across fallback fonts.
        /// </summary>
        public static T Shrink<T>(this T text, float minScale = 0.55f) where T : TMP_Text
        {
            text.enableAutoSizing = true;
            text.fontSizeMax = text.fontSize;
            text.fontSizeMin = text.fontSize * minScale;
            return text;
        }

        public static Pressable MakePressable(this RectTransform rt, Action onClick)
        {
            var p = rt.Ensure<Pressable>();
            p.OnClick = onClick;
            return p;
        }
    }

    /// <summary>
    /// An <see cref="Image"/> that takes no part in layout. A stock sliced Image reports its un-multiplied border
    /// size as its preferred size (96 units for our rounded sprite), which would inflate every container behind it.
    /// </summary>
    public sealed class FlatImage : Image
    {
        public override float minWidth => 0;
        public override float minHeight => 0;
        public override float preferredWidth => 0;
        public override float preferredHeight => 0;
    }

    /// <summary>
    /// Keeps a 9-sliced rounded rect's corner radius true as its size changes: the radius is capped at half the
    /// shorter side, so a very wide, short rect (a pill) gets round ends rather than elliptical ones.
    /// </summary>
    [RequireComponent(typeof(Image))]
    public sealed class RoundedFit : MonoBehaviour
    {
        public float Radius = 12f;

        /// <summary>When above zero this draws an outline of that thickness (in units) instead of a filled shape.</summary>
        public float RingThickness;
        private Image _image;

        private void OnEnable() => Apply();
        private void OnRectTransformDimensionsChange() => Apply();

        public void Apply()
        {
            if (_image == null) _image = GetComponent<Image>();
            if (_image == null || _image.sprite == null) return;
            var rect = ((RectTransform)transform).rect;
            var r = Mathf.Max(1f, Mathf.Min(Radius, Mathf.Min(rect.width, rect.height) / 2f));
            _image.pixelsPerUnitMultiplier = Sprites.RoundedBorder / r;
            if (RingThickness > 0f)
                _image.sprite = Sprites.RoundedRing(RingThickness * Sprites.RoundedBorder / r);
        }
    }

    /// <summary>Tap target with a pressed-state squash and a disabled look. Needs a raycastable Graphic.</summary>
    public sealed class Pressable : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler, IPointerClickHandler
    {
        public Action OnClick;
        private bool _interactable = true;
        private CanvasGroup _group;
        private Vector3 _restScale = Vector3.one;

        public bool Interactable
        {
            get => _interactable;
            set
            {
                _interactable = value;
                Group.alpha = value ? 1f : 0.35f;
            }
        }

        private CanvasGroup Group => _group != null ? _group : (_group = this.Ensure<CanvasGroup>());

        private void Awake()
        {
            _restScale = transform.localScale;
            // Every pressable needs something to hit-test; a transparent image does it without drawing.
            if (GetComponent<Graphic>() == null)
            {
                var hit = gameObject.AddComponent<FlatImage>();
                hit.color = Color.clear;
            }
            foreach (var g in GetComponents<Graphic>()) g.raycastTarget = true;
        }

        public void OnPointerDown(PointerEventData e) { if (_interactable) transform.localScale = _restScale * 0.97f; }
        public void OnPointerUp(PointerEventData e) => transform.localScale = _restScale;
        public void OnPointerExit(PointerEventData e) => transform.localScale = _restScale;

        public void OnPointerClick(PointerEventData e)
        {
            if (_interactable) OnClick?.Invoke();
        }
    }
}
