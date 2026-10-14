using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Dialogs and bottom sheets above the screens. Owns a stack so the Android back button closes the
    /// topmost one first (wired to <see cref="GameController.OverlayBack"/>).
    /// </summary>
    public sealed class Overlays
    {
        private readonly RectTransform _layer;
        private readonly List<Entry> _stack = new List<Entry>();

        private sealed class Entry
        {
            public GameObject Root;
            public Action OnClose;
        }

        public Overlays(RectTransform layer) { _layer = layer; }

        public bool Any => _stack.Count > 0;

        public bool CloseTop()
        {
            if (_stack.Count == 0) return false;
            var top = _stack[_stack.Count - 1];
            _stack.RemoveAt(_stack.Count - 1);
            top.OnClose?.Invoke();
            if (top.Root != null) UnityEngine.Object.Destroy(top.Root);
            return true;
        }

        public void CloseAll() { while (CloseTop()) { } }

        private RectTransform Scrim(float alpha, Action onTap, out Entry entry)
        {
            var root = Ui.Node("Overlay", _layer).Fill();
            var scrim = Ui.Box(root, Theme.Scrim.WithAlpha(alpha), 0, "Scrim");
            scrim.rectTransform.Fill();
            scrim.raycastTarget = true;
            scrim.rectTransform.MakePressable(onTap);
            // Stop the press squash on the whole-screen scrim.
            scrim.rectTransform.GetComponent<Pressable>().enabled = true;
            entry = new Entry { Root = root.gameObject };
            _stack.Add(entry);
            return root;
        }

        /// <summary>A centred dialog card. <paramref name="build"/> fills its content stack.</summary>
        public Action Dialog(Action<RectTransform, Action> build, Color? border = null, float alpha = 0.6f, Action onClose = null)
        {
            Entry entry = null;
            Action close = () => { if (entry != null && _stack.Remove(entry)) { entry.OnClose?.Invoke(); UnityEngine.Object.Destroy(entry.Root); } };
            var root = Scrim(alpha, close, out entry);
            entry.OnClose = onClose;

            var holder = Ui.VStack(root, 0, Ui.Pad(24, 0), TextAnchor.MiddleCenter, true, "DialogHolder").Fill();
            holder.GetComponent<VerticalLayoutGroup>().childForceExpandHeight = false;
            var card = Ui.Card(holder, Theme.Panel, 22, border ?? Theme.Border, 1, Ui.Pad(22, 26, 22, 22), 0, true, "Dialog");
            // Taps on the card must not fall through to the scrim.
            card.parent.GetComponent<Image>().raycastTarget = true;
            card.GetComponent<Image>().raycastTarget = true;
            build(card, close);
            return close;
        }

        /// <summary>A full-screen opaque page above everything (the legal documents). Back closes it.</summary>
        public Action Page(Action<RectTransform, Action> build)
        {
            var root = Ui.Node("Page", _layer).Fill();
            var bg = Ui.Box(root, Theme.Surface, 0, "PageBackground");
            bg.rectTransform.Fill();
            bg.raycastTarget = true;
            var safe = Ui.Node("Safe", root).Fill();
            safe.gameObject.AddComponent<SafeAreaFitter>();
            var entry = new Entry { Root = root.gameObject };
            _stack.Add(entry);
            Action close = () => { if (_stack.Remove(entry)) { entry.OnClose?.Invoke(); UnityEngine.Object.Destroy(entry.Root); } };
            build(safe, close);
            return close;
        }

        /// <summary>A bottom sheet with rounded top corners.</summary>
        public Action Sheet(Action<RectTransform, Action> build, float maxHeightFraction = 0.62f, Color? border = null, Action onClose = null)
        {
            Entry entry = null;
            Action close = () => { if (entry != null && _stack.Remove(entry)) { entry.OnClose?.Invoke(); UnityEngine.Object.Destroy(entry.Root); } };
            var root = Scrim(0.5f, close, out entry);
            entry.OnClose = onClose;

            var sheet = Ui.Card(root, Theme.Surface, 24, border ?? Theme.Gold.WithAlpha(0.3f), 1, Ui.Pad(16, 10, 16, 22), 0, true, "Sheet");
            var outer = (RectTransform)sheet.parent;
            outer.anchorMin = new Vector2(0, 0);
            outer.anchorMax = new Vector2(1, 0);
            outer.pivot = new Vector2(0.5f, 0);
            outer.offsetMin = Vector2.zero;
            outer.offsetMax = new Vector2(0, 0);
            outer.FitContent();
            outer.GetComponent<Image>().raycastTarget = true;
            sheet.GetComponent<Image>().raycastTarget = true;

            var grip = Ui.Box(sheet, Theme.Border, 2, "Grip");
            grip.rectTransform.Size(40, 4);
            sheet.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.UpperCenter;
            build(sheet, close);
            return close;
        }
    }

    /// <summary>The toast banner and the floating quick-chat reaction, driven from state.</summary>
    public sealed class ToastLayer
    {
        private readonly RectTransform _toast;
        private readonly TextMeshProUGUI _toastText;
        private readonly CanvasGroup _toastGroup;
        private readonly RectTransform _reaction;
        private readonly TextMeshProUGUI _reactionText;
        private readonly CanvasGroup _reactionGroup;
        private string _lastToast = "";
        private int _lastReactionId;
        private float _reactionStart = -10f;

        public ToastLayer(RectTransform parent)
        {
            var toastBox = Ui.Card(parent, Theme.NavSurface, Theme.RadiusXl, Theme.Gold.WithAlpha(0.4f), 1, Ui.Pad(16, 9), 0, false, "Toast");
            _toast = (RectTransform)toastBox.parent;
            _toast.anchorMin = _toast.anchorMax = new Vector2(0.5f, 1);
            _toast.pivot = new Vector2(0.5f, 1);
            _toast.anchoredPosition = new Vector2(0, -58);
            _toast.sizeDelta = new Vector2(0, 0);
            _toast.FitContent(true, true);
            _toastText = Ui.Text(toastBox, "", 15, Theme.Gold, FontKind.SoraSemiBold, TextAlignmentOptions.Center, true);
            _toastText.rectTransform.Ensure<LayoutElement>().preferredWidth = 330;
            _toastGroup = _toast.gameObject.AddComponent<CanvasGroup>();
            _toastGroup.alpha = 0; _toastGroup.blocksRaycasts = false; _toastGroup.interactable = false;

            var reactionBox = Ui.Card(parent, Theme.NavSurface.WithAlpha(0.95f), Theme.RadiusPill, Theme.Gold, 1, Ui.Pad(16, 8), 0, false, "Reaction");
            _reaction = (RectTransform)reactionBox.parent;
            _reaction.anchorMin = _reaction.anchorMax = new Vector2(0.5f, 0.62f);
            _reaction.pivot = new Vector2(0.5f, 0.5f);
            _reaction.FitContent(true, true);
            _reactionText = Ui.Text(reactionBox, "", 15, Theme.GoldLight, FontKind.SoraBold, TextAlignmentOptions.Center, false);
            _reactionGroup = _reaction.gameObject.AddComponent<CanvasGroup>();
            _reactionGroup.alpha = 0; _reactionGroup.blocksRaycasts = false; _reactionGroup.interactable = false;
        }

        public void Apply(AppState s)
        {
            if (s.Toast != _lastToast)
            {
                _lastToast = s.Toast;
                if (s.Toast.Length > 0) _toastText.text = s.Toast;
            }
            if (s.ReactionId != _lastReactionId)
            {
                _lastReactionId = s.ReactionId;
                if (s.ReactionFloat.Length > 0) { _reactionText.text = s.ReactionFloat; _reactionStart = Time.unscaledTime; }
            }
        }

        /// <summary>Called every frame: eases the toast in/out and floats the reaction up (the design's 1.6s float).</summary>
        public void Tick()
        {
            var want = _lastToast.Length > 0 ? 1f : 0f;
            _toastGroup.alpha = Mathf.MoveTowards(_toastGroup.alpha, want, Time.unscaledDeltaTime / 0.25f);

            var t = (Time.unscaledTime - _reactionStart) / 1.6f;
            if (t is < 0f or > 1f) { _reactionGroup.alpha = 0; return; }
            var opacity = t < 0.15f ? t / 0.15f : t < 0.78f ? 1f : (1f - t) / 0.22f;
            _reactionGroup.alpha = Mathf.Clamp01(opacity);
            _reaction.anchoredPosition = new Vector2(0, 10f - 56f * t);
        }
    }
}
