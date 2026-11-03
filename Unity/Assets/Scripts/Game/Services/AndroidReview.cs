using System;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Google Play In-App Review. Android device builds only; elsewhere <see cref="Request"/> reports false.
    /// Never throws and never blocks a hand — any failure just reports "not completed".
    /// </summary>
    public sealed class AndroidReview : IReviewPrompter
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        public void Request(Action<bool> completed)
        {
            // Play callbacks arrive on the Android UI thread; hand the result back to Unity's thread.
            var unity = System.Threading.SynchronizationContext.Current;
            var done = false;
            void Finish(bool ok)
            {
                if (done) return;
                done = true;
                if (unity != null) unity.Post(_ => completed(ok), null); else completed(ok);
            }
            try
            {
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                activity.Call("runOnUiThread", new AndroidJavaRunnable(() => Launch(activity, Finish)));
            }
            catch (Exception e) { Debug.LogWarning("Review unavailable: " + e.Message); Finish(false); }
        }

        private static void Launch(AndroidJavaObject activity, Action<bool> finish)
        {
            try
            {
                using var factory = new AndroidJavaClass("com.google.android.play.core.review.ReviewManagerFactory");
                var manager = factory.CallStatic<AndroidJavaObject>("create", activity);
                var request = manager.Call<AndroidJavaObject>("requestReviewFlow");
                request.Call<AndroidJavaObject>("addOnCompleteListener", new Listener(task =>
                {
                    try
                    {
                        if (!task.Call<bool>("isSuccessful")) { finish(false); return; }
                        var info = task.Call<AndroidJavaObject>("getResult");
                        var launch = manager.Call<AndroidJavaObject>("launchReviewFlow", activity, info);
                        launch.Call<AndroidJavaObject>("addOnCompleteListener", new Listener(t => finish(t.Call<bool>("isSuccessful"))));
                    }
                    catch (Exception e) { Debug.LogWarning("Review launch failed: " + e.Message); finish(false); }
                }));
            }
            catch (Exception e) { Debug.LogWarning("Review request failed: " + e.Message); finish(false); }
        }

        private sealed class Listener : AndroidJavaProxy
        {
            private readonly Action<AndroidJavaObject> _on;
            public Listener(Action<AndroidJavaObject> on) : base("com.google.android.gms.tasks.OnCompleteListener") => _on = on;
            // Called by the Java side with the completed Task.
            public void onComplete(AndroidJavaObject task) => _on(task);
        }
#else
        public void Request(Action<bool> completed) => completed(false);
#endif
    }
}
