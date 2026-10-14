using Blackjack.Game.Services;
using Blackjack.Game.UI;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Blackjack.Game
{
    /// <summary>
    /// Builds the whole game at startup — services, the controller and the UI — so the "Main" scene can be empty.
    /// Only runs for the Main scene, so tests that build their own stages are left alone.
    /// </summary>
    public static class GameBootstrap
    {
        public const string MainScene = "Main";
        private const int TargetFrameRate = 60;

        public static GameController Controller { get; private set; }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void OnLoad()
        {
            if (SceneManager.GetActiveScene().name != MainScene) return;
            Launch();
        }

        public static GameController Launch()
        {
            Application.targetFrameRate = TargetFrameRate;
            Screen.sleepTimeout = SleepTimeout.SystemSetting;

            // A canvas in overlay mode needs no camera, but Unity warns when nothing renders; this also paints the bars.
            if (Camera.main == null)
            {
                var camera = new GameObject("Camera", typeof(Camera)).GetComponent<Camera>();
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = Theme.ShellBlack;
                camera.cullingMask = 0;
                camera.tag = "MainCamera";
            }

            var host = new GameObject("Game");
            Object.DontDestroyOnLoad(host);
            var controller = host.AddComponent<GameController>();
            var sound = host.AddComponent<UnitySoundService>();

            var services = new GameServices
            {
                Sound = sound,
                Haptics = new AndroidHaptics(),
                Store = new PlayerPrefsSaveStore(),
                Notifier = new UnityNotifier(),
                Platform = new UnityPlatform(),
                Social = CreateSocial(),
                Analytics = CreateAnalytics(),
            };
            controller.Init(services);
            Loc.Use(controller.State.LanguageOverride);
            Fonts.EnsureScript(Loc.Code);

            AppRoot.Attach(UiRoot.Create(), controller);

            // Invite links: handle the one that launched the app, and any that arrive while it runs.
            Application.deepLinkActivated += controller.HandleIncomingLink;
            if (!string.IsNullOrEmpty(Application.absoluteURL)) controller.HandleIncomingLink(Application.absoluteURL);

            Controller = controller;
            return controller;
        }

        // Firebase-backed services are added by the Firebase integration; until then the game runs offline.
        private static ISocialService CreateSocial() => new NullSocial();
        private static IAnalytics CreateAnalytics() => new NullAnalytics();
    }
}
