#if BJ_QA_NOTIF
using System;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Dev APK only (<c>BJ_QA_NOTIF</c>, set by <c>BuildTools.BuildAndroid</c>, never by <c>BuildAndroidRelease</c>). Reads launch extras
    /// so the emulator can exercise the evening gift and the review prompt without waiting:
    /// <c>adb shell am start -n PKG/com.unity3d.player.UnityPlayerGameActivity --ei bj_qa_gift_secs 60 --ez bj_qa_seasoned true</c>.
    /// </summary>
    public static class QaNotifHook
    {
        public static void Apply(GameController controller, ILocalNotifier notifier)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                using var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                using var intent = activity.Call<AndroidJavaObject>("getIntent");
                if (intent == null) return;
                var secs = intent.Call<int>("getIntExtra", "bj_qa_gift_secs", 0);
                if (secs > 0 && notifier is UnityNotifier unity) unity.QaScheduleGiftIn(secs);
                if (intent.Call<bool>("getBooleanExtra", "bj_qa_seasoned", false)) controller.QaMakeSeasoned();
                if (intent.Call<bool>("getBooleanExtra", "bj_qa_bigwin", false)) controller.QaForceBigWin = true;
            }
            catch (Exception e) { Debug.LogWarning("QaNotifHook: " + e.Message); }
#endif
        }
    }
}
#endif
