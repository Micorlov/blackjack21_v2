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

        /// <summary>Below this a node is mid-animation (a pop-in, a squash), not really drawn that small.</summary>
        private const float SmallestScale = 0.25f;

        private TMP_Text _text;
        private float _size, _min, _max;
        private bool _autoSize;
        private float _appliedScale = -1f;
        private Transform _root;

        /// <summary>
        /// Adds the floor to <paramref name="text"/>, remembering its current size as the authored one. Call it after
        /// <see cref="Ui.Shrink"/> and any other sizing; calling it again re-reads the authored size safely.
        /// </summary>
        public static T Apply<T>(T text) where T : TMP_Text
        {
            var floor = text.GetComponent<TextFloor>();
            if (floor != null) floor.Restore();
            else floor = text.gameObject.AddComponent<TextFloor>();
            floor.Capture();
            return text;
        }

        /// <summary>Puts back the authored sizes, so a second capture does not read a size this raised.</summary>
        private void Restore()
        {
            if (_text == null) return;
            _text.fontSize = _size;
            _text.fontSizeMin = _min;
            _text.fontSizeMax = _max;
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

        private void Capture()
        {
            _text = GetComponent<TMP_Text>();
            _autoSize = _text.enableAutoSizing;
            _size = _text.fontSize;
            _min = _text.fontSizeMin;
            _max = _text.fontSizeMax;
            _appliedScale = -1f;
            Enforce();
        }

        // Added by Ui.Text under a FloorScope, before the caller has finished sizing the label (Shrink and the like):
        // the authored size is read on the first frame instead.
        private void Start()
        {
            if (_text == null) Capture();
        }

        private void LateUpdate() => Enforce();

        private void Enforce()
        {
            if (_text == null) return;
            if (_root == null)
            {
                var canvas = GetComponentInParent<Canvas>();
                if (canvas == null) return;
                _root = canvas.rootCanvas.transform;
            }
            var rootScale = Mathf.Abs(_root.lossyScale.y);
            var scale = rootScale < Epsilon ? 1f : Mathf.Abs(transform.lossyScale.y) / rootScale;
            if (Mathf.Abs(scale - _appliedScale) < Epsilon) return;
            _appliedScale = scale;
            var least = Type.Floor / Mathf.Max(scale, SmallestScale);
            if (_autoSize)
            {
                _text.fontSizeMin = Mathf.Max(_min, least);
                _text.fontSizeMax = Mathf.Max(_max, least);
            }
            else _text.fontSize = Mathf.Max(_size, least);
        }
    }

    /// <summary>
    /// Marks a scaled subtree (the felt) whose labels all keep <see cref="Type.Floor"/>: <see cref="Ui.Text"/> gives
    /// every label created under it a <see cref="TextFloor"/>. A nested scope with <see cref="On"/> false opts out.
    /// </summary>
    public sealed class FloorScope : MonoBehaviour
    {
        public bool On = true;

        public static bool Covers(Transform parent)
        {
            var scope = parent.GetComponentInParent<FloorScope>(true);
            return scope != null && scope.On;
        }
    }
}
