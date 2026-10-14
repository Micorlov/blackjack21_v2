using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The hero's turn clock: a gold bar that empties over <see cref="GameController.TurnSeconds"/> and the seconds
    /// left. It reads the controller every frame instead of joining the panel's rebuild signature, so the panel
    /// is not rebuilt sixty times a second. Hidden whenever no clock runs (timer off, a tutorial hand).
    /// </summary>
    public sealed class TurnTimerView : MonoBehaviour
    {
        private const float BarHeight = 3f;

        private GameController _g;
        private GameObject _row;
        private RectTransform _fill;
        private TextMeshProUGUI _seconds;
        private int _shownSeconds = -1;

        public static TurnTimerView Build(RectTransform parent, GameController g)
        {
            var holder = Ui.VStack(parent, 0, null, TextAnchor.MiddleCenter, true, "TurnTimer");
            var view = holder.gameObject.AddComponent<TurnTimerView>();
            view._g = g;

            var row = Ui.HStack(holder, Theme.Md, null, TextAnchor.MiddleCenter, false, "Row");
            view._row = row.gameObject;
            var track = Ui.Box(row, Color.white.WithAlpha(0.12f), Theme.Xxs, "Track");
            track.rectTransform.Size(null, BarHeight);
            track.rectTransform.FlexW();
            var fill = Ui.Box(track.transform, Theme.Gold, Theme.Xxs, "Fill");
            view._fill = fill.rectTransform;
            view._fill.anchorMin = Vector2.zero;
            view._fill.anchorMax = Vector2.one;
            view._fill.pivot = new Vector2(Loc.IsRtl ? 1f : 0f, 0.5f);
            view._fill.offsetMin = view._fill.offsetMax = Vector2.zero;
            view._seconds = Ui.Text(row, "", Type.Numeral(Type.Floor, bold: false), Theme.TextBody, TextAlignmentOptions.Right, false);
            view._seconds.rectTransform.Size(40);
            view.Apply();
            return view;
        }

        private void Update() => Apply();

        private void Apply()
        {
            if (_g == null) return;
            var left = _g.TurnSecondsLeft ?? _g.TurnSecondsPaused;
            _row.SetActive(left.HasValue);
            if (!left.HasValue) return;
            var share = Mathf.Clamp01(left.Value / GameController.TurnSeconds);
            _fill.localScale = new Vector3(share, 1f, 1f);
            var whole = Mathf.CeilToInt(left.Value);
            if (whole == _shownSeconds) return;
            _shownSeconds = whole;
            _seconds.text = Loc.T("gameSecondsLeft", ("n", whole));
            // The last five seconds turn the figure to the loss colour so a running-out clock is noticed.
            _seconds.color = whole <= 5 ? Theme.LoseOnPanel : Theme.TextBody;
        }
    }
}
