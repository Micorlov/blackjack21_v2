using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Vibration patterns standing in for iOS-style impact feedback. Android only; every call is a no-op
    /// elsewhere and never throws — a missing vibrator must not break a hand.
    /// </summary>
    public sealed class AndroidHaptics : IHaptics
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        private AndroidJavaObject _vibrator;
        private AndroidJavaClass _effect;
        private int _sdk;
        private bool _ready;

        private void Init()
        {
            if (_ready) return;
            _ready = true;
            try
            {
                using var version = new AndroidJavaClass("android.os.Build$VERSION");
                _sdk = version.GetStatic<int>("SDK_INT");
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                using var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                _vibrator = activity.Call<AndroidJavaObject>("getSystemService", "vibrator");
                if (_sdk >= 26) _effect = new AndroidJavaClass("android.os.VibrationEffect");
            }
            catch (System.Exception e) { Debug.LogWarning("Haptics unavailable: " + e.Message); _vibrator = null; }
        }

        private void Pulse(long milliseconds, int amplitude)
        {
            Init();
            if (_vibrator == null) return;
            try
            {
                if (_sdk >= 26)
                    using (var wave = _effect.CallStatic<AndroidJavaObject>("createOneShot", milliseconds, amplitude))
                        _vibrator.Call("vibrate", wave);
                else
                    _vibrator.Call("vibrate", milliseconds);
            }
            catch (System.Exception e) { Debug.LogWarning("Vibrate failed: " + e.Message); }
        }
#else
        private static void Pulse(long milliseconds, int amplitude) { }
#endif

        public void Selection() => Pulse(8, 70);
        public void Light() => Pulse(14, 110);
        public void Medium() => Pulse(24, 170);
        public void Heavy() => Pulse(42, 255);
        public void Vibrate() => Pulse(140, 220);
    }
}
