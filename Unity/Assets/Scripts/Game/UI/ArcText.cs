using TMPro;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Bends a one-line label along a circular arc, like the print on a casino felt ("Blackjack pays 3 to 2"). It
    /// moves the finished glyph quads, so it runs after <see cref="UiText"/> has shaped and reordered right-to-left
    /// text and after any <see cref="TextFloor"/> resize: whatever TMP lays out is what gets bent.
    /// </summary>
    [RequireComponent(typeof(TMP_Text))]
    public sealed class ArcText : MonoBehaviour
    {
        /// <summary>Radius of the arc in canvas units. Positive curves like a smile (the ends rise), as on the felt.</summary>
        public float Radius = 360f;

        private TMP_Text _text;
        private bool _dirty = true;
        private bool _warping;

        public static ArcText Apply(TMP_Text text, float radius)
        {
            var arc = text.gameObject.AddComponent<ArcText>();
            arc.Radius = radius;
            return arc;
        }

        private void Awake() => _text = GetComponent<TMP_Text>();

        private void OnEnable()
        {
            TMPro_EventManager.TEXT_CHANGED_EVENT.Add(OnTextChanged);
            _dirty = true;
        }

        private void OnDisable() => TMPro_EventManager.TEXT_CHANGED_EVENT.Remove(OnTextChanged);

        private void OnTextChanged(Object changed)
        {
            if (!_warping && changed == _text) _dirty = true;
        }

        private void LateUpdate()
        {
            if (!_dirty || Mathf.Abs(Radius) < 1f) return;
            _dirty = false;
            Warp();
        }

        private void Warp()
        {
            _warping = true;
            _text.ForceMeshUpdate();
            var info = _text.textInfo;
            for (var i = 0; i < info.characterCount; i++)
            {
                var ch = info.characterInfo[i];
                if (!ch.isVisible) continue;
                var vertices = info.meshInfo[ch.materialReferenceIndex].vertices;
                var first = ch.vertexIndex;
                // The glyph turns about the middle of its baseline, which moves onto the arc.
                var pivot = new Vector3((ch.bottomLeft.x + ch.topRight.x) / 2f, ch.baseLine, 0f);
                var angle = pivot.x / Radius;
                var onArc = new Vector3(Radius * Mathf.Sin(angle), ch.baseLine + Radius * (1f - Mathf.Cos(angle)), 0f);
                var turn = Quaternion.Euler(0f, 0f, angle * Mathf.Rad2Deg);
                for (var v = 0; v < 4; v++)
                    vertices[first + v] = turn * (vertices[first + v] - pivot) + onArc;
            }
            _text.UpdateVertexData(TMP_VertexDataUpdateFlags.Vertices);
            _warping = false;
        }
    }
}
