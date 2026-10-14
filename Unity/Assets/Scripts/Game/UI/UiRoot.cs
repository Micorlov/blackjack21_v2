using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The canvas every screen is drawn on, scaled from a 412x892 phone-sized reference.</summary>
    public sealed class UiRoot : MonoBehaviour
    {
        public const float ReferenceWidth = 412f;
        public const float ReferenceHeight = 892f;

        public Canvas Canvas { get; private set; }

        /// <summary>The area inside the system bars / notch; screens live here.</summary>
        public RectTransform Safe { get; private set; }

        /// <summary>Full-screen layer above everything — toasts, dialogs.</summary>
        public RectTransform Overlay { get; private set; }

        /// <param name="offscreenSize">When rendering to a texture (screenshots) the real screen size is unknown to
        /// Unity, so the scale that <see cref="CanvasScaler"/> would pick is computed here instead.</param>
        public static UiRoot Create(Camera renderCamera = null, Rect? safeArea = null, Vector2? offscreenSize = null)
        {
            var go = new GameObject("UiRoot", typeof(RectTransform));
            var root = go.AddComponent<UiRoot>();

            root.Canvas = go.AddComponent<Canvas>();
            if (renderCamera == null)
            {
                root.Canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            }
            else
            {
                root.Canvas.renderMode = RenderMode.ScreenSpaceCamera;
                root.Canvas.worldCamera = renderCamera;
                root.Canvas.planeDistance = 1f;
            }

            var scaler = go.AddComponent<CanvasScaler>();
            if (offscreenSize.HasValue)
            {
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ConstantPixelSize;
                scaler.scaleFactor = ScaleFor(offscreenSize.Value);
            }
            else
            {
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                scaler.referenceResolution = new Vector2(ReferenceWidth, ReferenceHeight);
                scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
                scaler.matchWidthOrHeight = 0.5f;
            }
            go.AddComponent<GraphicRaycaster>();

            var background = Ui.Box(go.transform, Theme.Surface, 0, "Background");
            background.rectTransform.Fill();

            root.Safe = Ui.Node("Safe", go.transform).Fill();
            var fitter = root.Safe.gameObject.AddComponent<SafeAreaFitter>();
            fitter.Override = safeArea;
            fitter.ScreenSizeOverride = offscreenSize;
            fitter.Apply();
            root.Overlay = Ui.Node("Overlay", go.transform).Fill();

            if (Object.FindFirstObjectByType<EventSystem>() == null)
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            return root;
        }

        /// <summary>The scale <see cref="CanvasScaler"/> picks for MatchWidthOrHeight at 0.5 (log-space blend).</summary>
        public static float ScaleFor(Vector2 screen) =>
            Mathf.Pow(2f, Mathf.Lerp(Mathf.Log(screen.x / ReferenceWidth, 2f), Mathf.Log(screen.y / ReferenceHeight, 2f), 0.5f));
    }

    /// <summary>Insets a node to the screen's safe area (cutouts, gesture bar) and tracks changes.</summary>
    public sealed class SafeAreaFitter : MonoBehaviour
    {
        public Rect? Override;
        public Vector2? ScreenSizeOverride;
        private Rect _applied;
        private Vector2Int _screen;

        private Vector2Int ScreenSize() => ScreenSizeOverride.HasValue
            ? new Vector2Int((int)ScreenSizeOverride.Value.x, (int)ScreenSizeOverride.Value.y)
            : new Vector2Int(Screen.width, Screen.height);

        private void OnEnable() => Apply();

        private void Update()
        {
            if (_applied != CurrentArea() || _screen != ScreenSize()) Apply();
        }

        private Rect CurrentArea() => Override ?? Screen.safeArea;

        public void Apply()
        {
            var rt = (RectTransform)transform;
            var area = CurrentArea();
            _applied = area;
            _screen = ScreenSize();
            if (_screen.x <= 0 || _screen.y <= 0) return;
            rt.anchorMin = new Vector2(area.xMin / _screen.x, area.yMin / _screen.y);
            rt.anchorMax = new Vector2(area.xMax / _screen.x, area.yMax / _screen.y);
            rt.offsetMin = rt.offsetMax = Vector2.zero;
        }
    }
}
