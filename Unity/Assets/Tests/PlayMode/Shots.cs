using System.Collections;
using System.IO;
using Blackjack.Game.UI;
using UnityEngine;

namespace Blackjack.PlayTests
{
    /// <summary>Renders the live UI to a PNG so screens can be reviewed without a device.</summary>
    internal static class Shots
    {
        public const int Width = 1080;
        public const int Height = 2340;

        public static string OutDir
        {
            get
            {
                var dir = System.Environment.GetEnvironmentVariable("BJ_SHOTS");
                if (string.IsNullOrEmpty(dir)) dir = Path.Combine(Application.temporaryCachePath, "shots");
                Directory.CreateDirectory(dir);
                return dir;
            }
        }

        public sealed class Stage
        {
            public Camera Camera;
            public RenderTexture Target;
            public UiRoot Root;
        }

        public static Stage Create()
        {
            var camGo = new GameObject("ShotCamera");
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Theme.Surface;
            cam.orthographic = true;
            var target = new RenderTexture(Width, Height, 24, RenderTextureFormat.ARGB32);
            cam.targetTexture = target;
            cam.enabled = false; // rendered by hand in Capture
            // Screen.safeArea is the whole (virtual) screen in tests; pin a phone-like inset for realism.
            var root = UiRoot.Create(cam, new Rect(0, 0, Width, Height), new Vector2(Width, Height));
            return new Stage { Camera = cam, Target = target, Root = root };
        }

        public static IEnumerator Capture(Stage stage, string name, int settleFrames = 4, float settleSeconds = 0.9f)
        {
            for (var i = 0; i < settleFrames; i++) yield return null;
            yield return new WaitForSecondsRealtime(settleSeconds);
            Canvas.ForceUpdateCanvases();
            stage.Camera.Render();
            var previous = RenderTexture.active;
            RenderTexture.active = stage.Target;
            var tex = new Texture2D(Width, Height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, Width, Height), 0, 0);
            tex.Apply();
            RenderTexture.active = previous;
            File.WriteAllBytes(Path.Combine(OutDir, name + ".png"), tex.EncodeToPNG());
            Object.Destroy(tex);
        }

        public static void Destroy(Stage stage)
        {
            Object.Destroy(stage.Root.gameObject);
            Object.Destroy(stage.Camera.gameObject);
            stage.Target.Release();
        }
    }
}
