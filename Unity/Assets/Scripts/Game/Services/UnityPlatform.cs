using System;
using System.Globalization;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>OS integrations: share sheet, links, clipboard, version and region.</summary>
    public sealed class UnityPlatform : IPlatform
    {
        public string PlatformName =>
#if UNITY_ANDROID
            "android";
#elif UNITY_IOS
            "ios";
#else
            "desktop";
#endif

        public string CountryCode
        {
            get
            {
                try { return RegionInfo.CurrentRegion.TwoLetterISORegionName; }
                catch (Exception) { return ""; }
            }
        }

        public string AppVersion => Application.version;

        public bool Share(string text)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using var intent = new AndroidJavaObject("android.content.Intent");
                intent.Call<AndroidJavaObject>("setAction", "android.intent.action.SEND");
                intent.Call<AndroidJavaObject>("setType", "text/plain");
                intent.Call<AndroidJavaObject>("putExtra", "android.intent.extra.TEXT", text);
                using var chooserClass = new AndroidJavaClass("android.content.Intent");
                using var chooser = chooserClass.CallStatic<AndroidJavaObject>("createChooser", intent, "Share");
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                using var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                activity.Call("startActivity", chooser);
                return true;
            }
            catch (Exception e) { Debug.LogWarning("Share failed: " + e.Message); return false; }
#else
            GUIUtility.systemCopyBuffer = text;
            return true;
#endif
        }

        public bool OpenUrl(string url)
        {
            try { Application.OpenURL(url); return true; }
            catch (Exception e) { Debug.LogWarning("OpenURL failed: " + e.Message); return false; }
        }

        public string GetClipboard() => GUIUtility.systemCopyBuffer ?? "";
        public void SetClipboard(string text) => GUIUtility.systemCopyBuffer = text;
    }
}
