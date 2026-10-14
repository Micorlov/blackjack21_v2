using System;
using System.Linq;
using System.IO;
using UnityEditor;
using UnityEditor.Android;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Blackjack.EditorTools
{
    /// <summary>
    /// Project configuration and the Android build, scriptable from the command line:
    /// <c>-executeMethod Blackjack.EditorTools.BuildTools.BuildAndroid</c>.
    /// </summary>
    public static class BuildTools
    {
        public const string ScenePath = "Assets/Scenes/Main.unity";
        public const string OutputDir = "Builds/Android";
        public const string ApkName = "blackjack21-unity.apk";

        public const string PackageId = "com.micorlov.blackjack21_v2";
        // Above the Flutter app's versionCode (8) so `adb install -r` upgrades it in place.
        public const string VersionName = "1.7.0";
        public const int VersionCode = 9;

        public static void Configure()
        {
            EnsureScene();
            ConfigurePlayer();
            ConfigureIcons();
            ConfigureNotificationIcons();
            AssetDatabase.SaveAssets();
            Debug.Log("BuildTools.Configure done");
        }

        private static void EnsureScene()
        {
            Directory.CreateDirectory("Assets/Scenes");
            if (!File.Exists(ScenePath))
            {
                // Everything is built at runtime by GameBootstrap, so the scene itself is empty.
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                EditorSceneManager.SaveScene(scene, ScenePath);
            }
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        }

        private static void ConfigurePlayer()
        {
            var android = NamedBuildTarget.Android;
            PlayerSettings.companyName = "micorlov";
            PlayerSettings.productName = "Blackjack 21";
            PlayerSettings.SetApplicationIdentifier(android, PackageId);
            PlayerSettings.bundleVersion = VersionName;
            PlayerSettings.Android.bundleVersionCode = VersionCode;

            PlayerSettings.colorSpace = ColorSpace.Gamma;
            // Portrait only: the Seat is drawn for a phone held upright. Landscape is switched off outright, so an
            // auto-rotate default can never bring it back.
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
            PlayerSettings.allowedAutorotateToPortrait = true;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = false;
            PlayerSettings.allowedAutorotateToLandscapeRight = false;
            PlayerSettings.SplashScreen.show = false;
            PlayerSettings.SetScriptingBackend(android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel25;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.Android.applicationEntry = AndroidApplicationEntry.Activity;
            PlayerSettings.SetManagedStrippingLevel(android, ManagedStrippingLevel.Low);
            EditorUserBuildSettings.buildAppBundle = false;
            ConfigureFirebaseDefine(android);

            // The Flutter build is signed with the standard debug key; using the same one lets this APK upgrade it in place.
            var keystore = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".android", "debug.keystore");
            if (File.Exists(keystore))
            {
                PlayerSettings.Android.useCustomKeystore = true;
                PlayerSettings.Android.keystoreName = keystore;
                PlayerSettings.Android.keystorePass = "android";
                PlayerSettings.Android.keyaliasName = "androiddebugkey";
                PlayerSettings.Android.keyaliasPass = "android";
            }
            else Debug.LogWarning("No debug keystore at " + keystore + "; Unity will create its own and an in-place upgrade will not work.");
        }

        /// <summary>Turns the Firebase-backed services on only once tools/install_firebase.sh has imported the SDK.</summary>
        private static void ConfigureFirebaseDefine(NamedBuildTarget target)
        {
            const string define = "FIREBASE_SDK";
            var sdkPresent = File.Exists("Assets/Firebase/Plugins/Firebase.App.dll");
            PlayerSettings.GetScriptingDefineSymbols(target, out var current);
            var defines = current.Where(d => d != define).ToList();
            if (sdkPresent) defines.Add(define);
            PlayerSettings.SetScriptingDefineSymbols(target, defines.ToArray());
        }

        private static void ConfigureIcons()
        {
            var foreground = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Icons/ic_launcher_foreground.png");
            var background = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Icons/ic_launcher_background.png");
            var legacy = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Icons/ic_launcher.png");
            if (foreground == null || background == null || legacy == null) { Debug.LogWarning("Launcher icons missing"); return; }

            var android = NamedBuildTarget.Android;
            var adaptive = PlayerSettings.GetPlatformIcons(android, AndroidPlatformIconKind.Adaptive);
            foreach (var icon in adaptive) { icon.SetTexture(background, 0); icon.SetTexture(foreground, 1); }
            PlayerSettings.SetPlatformIcons(android, AndroidPlatformIconKind.Adaptive, adaptive);

            foreach (var kind in new[] { AndroidPlatformIconKind.Round, AndroidPlatformIconKind.Legacy })
            {
                var icons = PlayerSettings.GetPlatformIcons(android, kind);
                foreach (var icon in icons) icon.SetTexture(legacy, 0);
                PlayerSettings.SetPlatformIcons(android, kind, icons);
            }
        }

        // Android needs a white-on-transparent small icon for the status bar and a large icon for the shade.
        private static void ConfigureNotificationIcons()
        {
            Texture2D Readable(string path)
            {
                AssetDatabase.ImportAsset(path);
                var importer = (TextureImporter)AssetImporter.GetAtPath(path);
                if (importer != null && !importer.isReadable)
                {
                    importer.isReadable = true;
                    importer.textureCompression = TextureImporterCompression.Uncompressed;
                    importer.SaveAndReimport();
                }
                return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            }

            var small = Readable("Assets/Icons/icon_small.png");
            var large = Readable("Assets/Icons/icon_large.png");
            if (small == null || large == null) { Debug.LogWarning("Notification icons missing"); return; }
            Unity.Notifications.NotificationSettings.AndroidSettings.ClearDrawableResources();
            Unity.Notifications.NotificationSettings.AndroidSettings.AddDrawableResource("icon_small", small, Unity.Notifications.NotificationIconType.Small);
            Unity.Notifications.NotificationSettings.AndroidSettings.AddDrawableResource("icon_large", large, Unity.Notifications.NotificationIconType.Large);
            // Reminders survive a reboot instead of being lost with it.
            Unity.Notifications.NotificationSettings.AndroidSettings.RescheduleOnDeviceRestart = true;
        }

        public static void BuildAndroid()
        {
            Configure();
            Directory.CreateDirectory(OutputDir);
            var path = Path.Combine(OutputDir, ApkName);
            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = path,
                target = BuildTarget.Android,
                options = BuildOptions.None,
            };
            var report = BuildPipeline.BuildPlayer(options);
            var summary = report.summary;
            Debug.Log($"Build {summary.result}: {summary.totalSize / (1024 * 1024)} MB in {summary.totalTime.TotalSeconds:0}s -> {path}");
            EditorApplication.Exit(summary.result == BuildResult.Succeeded ? 0 : 1);
        }
    }
}
