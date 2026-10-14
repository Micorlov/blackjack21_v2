using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The app's reusable controls — ports of the Flutter <c>widgets/buttons.dart</c> family and friends.</summary>
    public static class W
    {
        // ---- icons ------------------------------------------------------------------------------------

        public static Image Icon(Transform parent, string name, float size, Color color)
        {
            var rt = Ui.Node("Icon_" + name, parent);
            var img = rt.gameObject.AddComponent<FlatImage>();
            img.sprite = Icons.Get(name);
            img.color = color;
            img.raycastTarget = false;
            img.preserveAspect = true;
            rt.Size(size, size);
            return img;
        }

        public static Image Dot(Transform parent, float size, Color color)
        {
            var img = Ui.Box(parent, color, 0, "Dot");
            img.sprite = Sprites.Circle;
            img.type = Image.Type.Simple;
            img.rectTransform.Size(size, size);
            return img;
        }

        // ---- text helpers -------------------------------------------------------------------------------

        public static TextMeshProUGUI Label(Transform parent, string text, float size, Color color,
            FontKind font = FontKind.Sora, TextAlignmentOptions align = TextAlignmentOptions.Left, bool wrap = true,
            float spacing = 0, float lineSpacing = 0)
        {
            var t = Ui.Text(parent, text, size, color, font, align, wrap, spacing, lineSpacing);
            return t;
        }

        public static TextMeshProUGUI Mono(Transform parent, string text, float size, Color color,
            bool bold = false, TextAlignmentOptions align = TextAlignmentOptions.Left, float spacing = 0)
            => Ui.Text(parent, text, size, color, bold ? FontKind.MonoBold : FontKind.Mono, align, false, spacing);

        public static TextMeshProUGUI Sora(Transform parent, string text, float size, Color color,
            bool bold = false, TextAlignmentOptions align = TextAlignmentOptions.Left, bool wrap = true)
            => Ui.Text(parent, text, size, color, bold ? FontKind.SoraBold : FontKind.Sora, align, wrap);

        public static TextMeshProUGUI Serif(Transform parent, string text, float size, Color color,
            TextAlignmentOptions align = TextAlignmentOptions.Left)
            => Ui.Text(parent, text, size, color, FontKind.SerifItalic, align, true);

        public static RectTransform SectionLabel(Transform parent, string text)
        {
            var box = Ui.VStack(parent, 0, Ui.Pad(2, 4, 2, 10));
            Ui.Text(box, text, 13, Theme.TextFaint, FontKind.SoraSemiBold);
            return box;
        }

        public static RectTransform ScreenTitle(Transform parent, string text)
        {
            var box = Ui.VStack(parent, 0, Ui.Pad(0, 0, 0, 16));
            Ui.Text(box, text, 32, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.TopLeft, true, 0, -10);
            return box;
        }

        // ---- buttons ------------------------------------------------------------------------------------

        private static RectTransform ButtonShell(Transform parent, Color fill, Color? border, float radius, float vPad, float hPad,
            Action onClick, bool enabled, string name, out RectTransform content)
        {
            RectTransform shell;
            if (border.HasValue)
            {
                content = Ui.Card(parent, fill, radius, border, 1.5f, Ui.Pad(hPad, vPad), 0, true, name);
                shell = content;
                // The pressable lives on the outer border node so the whole control is the hit area.
                shell = (RectTransform)content.parent;
            }
            else
            {
                content = Ui.Card(parent, fill, radius, null, 0, Ui.Pad(hPad, vPad), 0, true, name);
                shell = content;
            }
            var group = content.GetComponent<VerticalLayoutGroup>();
            group.childAlignment = TextAnchor.MiddleCenter;
            shell.MinSize(null, Theme.MinTarget);
            var p = shell.MakePressable(onClick);
            p.Interactable = enabled;
            shell.GetComponentInChildren<Image>().raycastTarget = true;
            return shell;
        }

        public static RectTransform GoldButton(Transform parent, string label, Action onClick, float vPad = 16,
            float hPad = 0, float fontSize = 17, bool enabled = true)
        {
            var shell = ButtonShell(parent, Theme.Gold, null, Theme.RadiusLg, vPad, hPad, onClick, enabled, "GoldButton", out var content);
            Ui.Text(content, label, fontSize, Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center, false, 0.2f);
            return shell;
        }

        public static RectTransform ActionPill(Transform parent, string label, Color border, Color background, Color text,
            Action onClick, float vPad = 20, float hPad = 0, float fontSize = 20, bool enabled = true)
        {
            var shell = ButtonShell(parent, background, border, Theme.RadiusLg, vPad, hPad, onClick, enabled, "ActionPill", out var content);
            Ui.Text(content, label, fontSize, text, FontKind.SoraBold, TextAlignmentOptions.Center, false, 0.2f);
            return shell;
        }

        public static RectTransform OutlinePill(Transform parent, string label, Action onClick, float vPad = 15,
            float fontSize = 16, Color? color = null, bool neutral = false, bool enabled = true)
        {
            var c = color ?? Theme.Gold;
            return ActionPill(parent, label,
                neutral ? Theme.BorderStrong : c.WithAlpha(0.45f),
                neutral ? Color.clear : c.WithAlpha(0.1f),
                neutral ? Theme.TextPrimary : c, onClick, vPad, 0, fontSize, enabled);
        }

        public static RectTransform TextLink(Transform parent, string label, Action onClick, Color? color = null,
            float fontSize = 15, bool enabled = true)
        {
            var box = Ui.VStack(parent, 0, Ui.Pad(Theme.Sm, 14), TextAnchor.MiddleCenter, false, "TextLink");
            box.MinSize(null, Theme.MinTarget);
            Ui.Text(box, label, fontSize, color ?? Theme.Gold, FontKind.SoraBold, TextAlignmentOptions.Center, false);
            var p = box.MakePressable(onClick);
            p.Interactable = enabled;
            return box;
        }

        public static RectTransform CircleIconButton(Transform parent, string icon, Action onClick, float iconSize = 24)
        {
            var box = Ui.Box(parent, Color.black.WithAlpha(0.32f), 0, "CircleIconButton");
            box.sprite = Sprites.Circle;
            box.type = Image.Type.Simple;
            box.rectTransform.Size(Theme.MinTarget, Theme.MinTarget);
            var ic = Icon(box.transform, icon, iconSize, Theme.TextPrimary);
            ic.rectTransform.PinCentre(Vector2.zero, new Vector2(iconSize, iconSize));
            ic.rectTransform.Ensure<LayoutElement>().ignoreLayout = true;
            box.rectTransform.MakePressable(onClick);
            return box.rectTransform;
        }

        // ---- chips --------------------------------------------------------------------------------------

        public static RectTransform ChipDisc(Transform parent, Color color, float size, string label = null)
        {
            var rt = Ui.Node("ChipDisc", parent);
            var shadow = Ui.Box(rt, Color.black.WithAlpha(0.5f), 0, "Shadow");
            shadow.sprite = Sprites.Circle;
            shadow.type = Image.Type.Simple;
            shadow.rectTransform.PinCentre(new Vector2(0, -size * 0.08f), new Vector2(size * 1.08f, size * 1.08f));
            var img = Ui.Box(rt, Color.white, 0, "Chip");
            img.sprite = Gfx.Chip(color);
            img.type = Image.Type.Simple;
            img.rectTransform.Fill();
            rt.Size(size, size);
            if (label != null)
            {
                var t = Ui.Text(rt, label, size * 0.25f, Theme.TextPrimary, FontKind.MonoBold, TextAlignmentOptions.Center, false);
                t.rectTransform.Fill();
            }
            return rt;
        }

        public static RectTransform ChipButton(Transform parent, int amount, Color color, bool disabled, Action onClick, float size = 64)
        {
            var disc = ChipDisc(parent, color, Mathf.Max(size, Theme.MinTarget), "$" + amount);
            var p = disc.MakePressable(onClick);
            p.Interactable = !disabled;
            if (disabled) disc.Ensure<CanvasGroup>().alpha = 0.4f;
            disc.GetComponentInChildren<Image>().raycastTarget = true;
            return disc;
        }

        // ---- avatar -------------------------------------------------------------------------------------

        public static RectTransform Avatar(Transform parent, string initial, Color color, float size, bool goldRing = false,
            Color? textColor = null)
        {
            var rt = Ui.Node("Avatar", parent);
            rt.Size(size, size);
            var inner = rt;
            if (goldRing)
            {
                var outer = Ui.Box(rt, Theme.ShellBlack, 0, "RingOuter");
                outer.sprite = Sprites.Circle; outer.type = Image.Type.Simple; outer.rectTransform.Fill();
                var ring = Ui.Box(rt, Theme.Gold, 0, "Ring");
                ring.sprite = Sprites.Circle; ring.type = Image.Type.Simple; ring.rectTransform.Fill(2, 2, 2, 2);
                inner = Ui.Node("Inner", rt).Fill(4, 4, 4, 4);
            }
            var disc = Ui.Box(inner, color, 0, "Disc");
            disc.sprite = Sprites.Circle; disc.type = Image.Type.Simple; disc.rectTransform.Fill();
            var t = Ui.Text(inner, initial, size * 0.42f, textColor ?? Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center, false);
            t.rectTransform.Fill();
            return rt;
        }

        // ---- panels -------------------------------------------------------------------------------------

        public static RectTransform Panel(Transform parent, RectOffset padding = null, float spacing = 0,
            Color? border = null, Color? background = null, float radius = Theme.RadiusLg)
            => Ui.Card(parent, background ?? Theme.Panel, radius, border ?? Theme.Border, 1, padding ?? Ui.Pad(16), spacing);

        public static RectTransform Divider(Transform parent, Color? color = null, float height = 1)
        {
            var img = Ui.Box(parent, color ?? Theme.Border, 0, "Divider");
            img.rectTransform.Size(null, height);
            return img.rectTransform;
        }

        // ---- switch -------------------------------------------------------------------------------------

        /// <summary>An on/off switch. Returns the root; call <see cref="SetSwitch"/> to move it.</summary>
        public static RectTransform Switch(Transform parent, bool on, Action onToggle, bool enabled = true)
        {
            var track = Ui.Box(parent, on ? Theme.Gold : Theme.Border, 0, "Switch");
            track.sprite = Sprites.Circle; track.type = Image.Type.Simple;
            track.rectTransform.Size(52, 30);
            Ui.Style(track, on ? Theme.Gold : Theme.BorderStrong, 15);
            var knob = Ui.Box(track.transform, on ? Theme.GoldInk : Theme.TextPrimary, 0, "Knob");
            knob.sprite = Sprites.Circle; knob.type = Image.Type.Simple;
            knob.rectTransform.Pin(new Vector2(on ? 1 : 0, 0.5f), new Vector2(on ? 1 : 0, 0.5f),
                new Vector2(on ? -4 : 4, 0), new Vector2(22, 22));
            var p = track.rectTransform.MakePressable(onToggle);
            p.Interactable = enabled;
            track.raycastTarget = true;
            return track.rectTransform;
        }

        // ---- scroll -------------------------------------------------------------------------------------

        /// <summary>A vertical scroll view; children go in the returned content stack.</summary>
        public static RectTransform Scroll(Transform parent, RectOffset padding, float spacing,
            bool stretch, bool reverse, out ScrollRect scroll)
        {
            var root = Ui.Node("Scroll", parent);
            var view = Ui.Node("Viewport", root).Fill();
            view.gameObject.AddComponent<RectMask2D>();
            var content = Ui.VStack(view, spacing, padding, TextAnchor.UpperLeft, stretch, "Content");
            content.anchorMin = new Vector2(0, 1);
            content.anchorMax = new Vector2(1, 1);
            content.pivot = new Vector2(0.5f, 1);
            content.offsetMin = content.offsetMax = Vector2.zero;
            content.FitContent();
            scroll = root.gameObject.AddComponent<ScrollRect>();
            scroll.viewport = view;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            scroll.elasticity = 0.08f;
            scroll.scrollSensitivity = 30f;
            scroll.inertia = true;
            scroll.decelerationRate = 0.12f;
            if (reverse)
            {
                // Anchored to the bottom, so growth pushes upward and the newest content stays in reach.
                content.anchorMin = new Vector2(0, 0);
                content.anchorMax = new Vector2(1, 0);
                content.pivot = new Vector2(0.5f, 0);
                content.offsetMin = content.offsetMax = Vector2.zero;
            }
            // A ScrollRect needs a graphic under the finger to receive drags.
            var hit = root.gameObject.AddComponent<FlatImage>();
            hit.color = Color.clear;
            return root;
        }

        public static RectTransform Scroll(Transform parent, RectOffset padding = null, float spacing = 0, bool stretch = true)
            => Scroll(parent, padding, spacing, stretch, false, out _);

        public static ScrollRect ScrollOf(RectTransform content) => content.GetComponentInParent<ScrollRect>();

        // ---- input --------------------------------------------------------------------------------------

        public static TMP_InputField Input(Transform parent, string placeholder, string initial, float fontSize,
            Action<string> onChanged, int characterLimit = 0, TMP_InputField.CharacterValidation validation = TMP_InputField.CharacterValidation.None)
        {
            var box = Ui.Card(parent, Color.black.WithAlpha(0.3f), Theme.RadiusMd, Theme.BorderStrong, 1.5f, Ui.Pad(14, 12), 0, true, "Input");
            var area = Ui.Node("TextArea", box).Fill();
            area.Ensure<LayoutElement>().minHeight = fontSize * 1.6f;
            area.gameObject.AddComponent<RectMask2D>();
            var hint = Ui.Text(area, placeholder, fontSize, Theme.TextFaint, FontKind.Mono, TextAlignmentOptions.Left, false);
            hint.rectTransform.Fill();
            var text = Ui.Text(area, initial ?? "", fontSize, Theme.TextPrimary, FontKind.Mono, TextAlignmentOptions.Left, false);
            text.rectTransform.Fill();
            var field = box.parent.gameObject.AddComponent<TMP_InputField>();
            field.textViewport = area;
            field.textComponent = text;
            field.placeholder = hint;
            field.characterLimit = characterLimit;
            field.characterValidation = validation;
            field.text = initial ?? "";
            field.onValueChanged.AddListener(v => onChanged?.Invoke(v));
            box.GetComponent<Image>().raycastTarget = true;
            ((RectTransform)box.parent).GetComponent<Image>().raycastTarget = true;
            return field;
        }

        // ---- misc ---------------------------------------------------------------------------------------

        public static RawImage Raw(Transform parent, Texture texture, string name = "Raw")
        {
            var rt = Ui.Node(name, parent);
            var raw = rt.gameObject.AddComponent<RawImage>();
            raw.texture = texture;
            raw.raycastTarget = false;
            return raw;
        }
    }

    /// <summary>A number that rolls to its new value instead of snapping — the balance, the round result.</summary>
    public sealed class CountUpText : MonoBehaviour
    {
        private const float Duration = 0.6f;
        private const float HapticGap = 0.125f;

        public TMP_Text Text;
        public string Prefix = "";
        public string Suffix = "";
        public bool Signed;
        public Action OnTick;

        private int _from, _to, _shown;
        private float _start = -1f;
        private float _lastTick;
        private bool _initialised;

        public static CountUpText Make(TMP_Text text, int value, string prefix = "", bool signed = false, Action onTick = null)
        {
            var c = text.gameObject.AddComponent<CountUpText>();
            c.Text = text; c.Prefix = prefix; c.Signed = signed; c.OnTick = onTick;
            c.SetValue(value, animate: false);
            return c;
        }

        public void SetValue(int value, bool animate = true)
        {
            if (_initialised && value == _to) return;
            _from = _initialised && animate ? _shown : value;
            _to = value;
            _initialised = true;
            if (!animate || _from == _to || !Application.isPlaying)
            {
                _shown = _to; _start = -1f; Render(); return;
            }
            _start = Time.unscaledTime;
        }

        private void Update()
        {
            if (_start < 0f) return;
            var t = Mathf.Clamp01((Time.unscaledTime - _start) / Duration);
            var eased = 1f - Mathf.Pow(1f - t, 3f);
            _shown = Mathf.RoundToInt(Mathf.Lerp(_from, _to, eased));
            if (t >= 1f) { _shown = _to; _start = -1f; }
            else if (OnTick != null && Time.unscaledTime - _lastTick >= HapticGap) { _lastTick = Time.unscaledTime; OnTick(); }
            Render();
        }

        private void Render()
        {
            var sign = Signed && _shown > 0 ? "+" : (_shown < 0 ? "-" : "");
            Text.text = sign + Prefix + Core.TableCatalog.FormatChips(Mathf.Abs(_shown)) + Suffix;
        }
    }

    /// <summary>Rebuilds a container's children only when a signature of what it shows changes.</summary>
    public sealed class Dyn
    {
        private readonly RectTransform _host;
        private string _signature;

        public Dyn(RectTransform host) { _host = host; }

        public RectTransform Host => _host;

        public bool Update(string signature, Action<RectTransform> build)
        {
            if (signature == _signature) return false;
            _signature = signature;
            for (var i = _host.childCount - 1; i >= 0; i--) UnityEngine.Object.Destroy(_host.GetChild(i).gameObject);
            build(_host);
            return true;
        }

        public void Invalidate() => _signature = null;
    }
}
