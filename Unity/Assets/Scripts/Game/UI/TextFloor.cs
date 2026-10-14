using TMPro;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Keeps a label at <see cref="Type.Floor"/> or larger as it is drawn on screen, however its parents are
    /// scaled. The felt is a fixed-unit canvas scaled from 0.65 to 1.4, so a 14-unit label there can land at 9;
    /// this raises the authored size just enough to cancel the scale-down and leaves it alone otherwise.
    /// </summary>
    [RequireComponent(typeof(TMP_Text))]
    public sealed class TextFloor : MonoBehaviour
    {
        private const float Epsilon = 0.001f;

        private TMP_Text _text;
        private float _size, _min, _max;
        private bool _autoSize;
        private float _appliedScale = -1f;

        /// <summary>Adds the floor to <paramref name="text"/>, remembering its current size as the authored one.</summary>
        public static T Apply<T>(T text) where T : TMP_Text
        {
            var floor = text.Ensure<TextFloor>();
            floor.Capture();
            return text;
        }

        /// <summary>
        /// How much larger (or smaller) than its font size a node is drawn, relative to the canvas units every
        /// rule is written in: its own scale divided by the root canvas's.
        /// </summary>
        public static float OnScreenScale(Transform node)
        {
            var canvas = node.GetComponentInParent<Canvas>();
            if (canvas == null) return 1f;
            var root = canvas.rootCanvas.transform;
            var rootScale = Mathf.Abs(root.lossyScale.y);
            return rootScale < Epsilon ? 1f : Mathf.Abs(node.lossyScale.y) / rootScale;
        }

        /// <summary>Takes the label's present size as authored; call after changing its size by hand.</summary>
        public void Capture()
        {
            _text = GetComponent<TMP_Text>();
            _autoSize = _text.enableAutoSizing;
            _size = _text.fontSize;
            _min = _text.fontSizeMin;
            _max = _text.fontSizeMax;
            _appliedScale = -1f;
            Enforce();
        }

        private void LateUpdate() => Enforce();

        private void Enforce()
        {
            if (_text == null) return;
            var scale = OnScreenScale(transform);
            if (Mathf.Abs(scale - _appliedScale) < Epsilon) return;
            _appliedScale = scale;
            var least = scale < Epsilon ? Type.Floor : Type.Floor / scale;
            if (_autoSize)
            {
                _text.fontSizeMin = Mathf.Max(_min, least);
                _text.fontSizeMax = Mathf.Max(_max, least);
            }
            else _text.fontSize = Mathf.Max(_size, least);
        }
    }
}
