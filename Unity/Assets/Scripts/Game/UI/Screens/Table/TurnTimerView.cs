using TMPro;
using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// The turn row above the action buttons: a gold label ("Your turn", "Maya is playing"), then either the
    /// hero's clock (a gold bar emptying over <see cref="GameController.TurnSeconds"/> and the seconds left) or a
    /// quiet note ("you play third"). It reads the controller every frame instead of joining the panel's rebuild
    /// signature, so the panel is not rebuilt sixty times a second.
    /// </summary>
    public sealed class TurnTimerView : MonoBehaviour
    {
        private const float BarHeight = 3f;
        private const float SecondsWidth = 40f;
        private const int Hurry = 5;

        private GameController _g;
        private GameObject _track;
        private RectTransform _fill;
        private TextMeshProUGUI _seconds, _note;
        private int _shownSeconds = -1;

        public static TurnTimerView Build(RectTransform parent, GameController g, string label, string note)
        {
            var row = Ui.HStack(parent, Theme.Md, null, TextAnchor.MiddleLeft, false, "TurnRow");
            var view = row.gameObject.AddComponent<TurnTimerView>();
            view._g = g;
            Ui.Text(row, label, new TextStyle(13, FontKind.SoraSemiBold), Theme.Gold, TextAlignmentOptions.Left, false).Shrink();

            var track = Ui.Box(row, Color.white.WithAlpha(0.12f), Theme.Xxs, "Track");
            track.rectTransform.Size(null, BarHeight);
            track.rectTransform.FlexW();
            view._track = track.gameObject;
            var fill = Ui.Box(track.transform, Theme.Gold, Theme.Xxs, "Fill");
            view._fill = fill.rectTransform;
            view._fill.anchorMin = Vector2.zero;
            view._fill.anchorMax = Vector2.one;
            view._fill.pivot = new Vector2(Loc.IsRtl ? 1f : 0f, 0.5f);
            view._fill.offsetMin = view._fill.offsetMax = Vector2.zero;
            view._seconds = Ui.Text(row, "", Type.Numeral(Type.Floor, bold: false), Theme.TextBody, TextAlignmentOptions.Right, false);
            view._seconds.rectTransform.Size(SecondsWidth);

            view._note = Ui.Text(row, note ?? "", Type.Numeral(Type.Floor, bold: false), Theme.TextBody, TextAlignmentOptions.Right, false);
            view._note.rectTransform.FlexW();
            view.Apply();
            return view;
        }

        private void Update() => Apply();

        private void Apply()
        {
            if (_g == null) return;
            var left = _g.TurnSecondsLeft ?? _g.TurnSecondsPaused;
            _track.SetActive(left.HasValue);
            _seconds.gameObject.SetActive(left.HasValue);
            _note.gameObject.SetActive(!left.HasValue);
            if (!left.HasValue) return;
            _fill.localScale = new Vector3(Mathf.Clamp01(left.Value / GameController.TurnSeconds), 1f, 1f);
            var whole = Mathf.CeilToInt(left.Value);
            if (whole == _shownSeconds) return;
            _shownSeconds = whole;
            _seconds.text = Loc.T("gameSecondsLeft", ("n", whole));
            // The last seconds turn the figure to the loss colour so a running-out clock is noticed.
            _seconds.color = whole <= Hurry ? Theme.LoseOnPanel : Theme.TextBody;
        }
    }
}
