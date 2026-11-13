using System;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Google Play's native in-app review card (<c>BlackjackExtras.androidlib</c>, <c>PlayReview.java</c>). Play decides
    /// whether the card appears and reports nothing back. Does nothing in the Editor and off Android.
    /// </summary>
    public sealed class PlayReview : IReviewPrompter
    {
        public void Request(Action<bool> completed) => completed(Ask());

        /// <summary>True when Play was asked for the card.</summary>
        public static bool Ask()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                using var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                using var review = new AndroidJavaClass("com.micorlov.blackjack21_v2.extras.PlayReview");
                review.CallStatic("ask", activity);
                return true;
            }
            catch (Exception e) { Debug.LogWarning("Review request failed: " + e.Message); return false; }
#else
            return false;
#endif
        }
    }
}
