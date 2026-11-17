using System;
using UnityEngine;
#if UNITY_ANDROID && !UNITY_EDITOR
using Unity.Notifications.Android;
using UnityEngine.Android;
#endif

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Local notifications on Android (the daily-bonus, streak and 8 PM evening-gift reminders, and friend/leaderboard alerts).
    /// Scheduled on the device, never from a server. Every call is a no-op off Android and never throws.
    /// </summary>
    public sealed class UnityNotifier : ILocalNotifier
    {
        private const int DailyBonusId = 210;
        private const int StreakId = 211;
        private const int EveningGiftId = 212;
        // The dev-APK test notification (see QaNotifHook). Never scheduled in a release, but a tap on it is read the same way.
        private const int QaEveningGiftId = 213;
        private const string PermissionName = "android.permission.POST_NOTIFICATIONS";

#if UNITY_ANDROID && !UNITY_EDITOR
        private bool _ready;

        public bool HasPermission => Permission.HasUserAuthorizedPermission(PermissionName);

        public void Init()
        {
            try
            {
                Register("leaderboard", "Leaderboard", "Alerts when a friend passes your score");
                Register("daily_bonus", "Daily bonus", "Reminder when the free daily chips are ready to claim");
                Register("streak", "Play streak", "Reminder when today's play-day streak is about to lapse");
                Register("evening_gift", "Evening gift", "A daily 8 PM reminder that free play chips are waiting");
                _ready = true;
            }
            catch (Exception e) { Debug.LogWarning("Notifications unavailable: " + e.Message); }
        }

        private static void Register(string id, string name, string description) =>
            AndroidNotificationCenter.RegisterNotificationChannel(new AndroidNotificationChannel
            {
                Id = id, Name = name, Description = description, Importance = Importance.High,
            });

        public void RequestPermission(Action<bool> granted)
        {
            if (HasPermission) { granted(true); return; }
            var callbacks = new PermissionCallbacks();
            callbacks.PermissionGranted += _ => granted(true);
            callbacks.PermissionDenied += _ => granted(false);
            callbacks.PermissionDeniedAndDontAskAgain += _ => granted(false);
            Permission.RequestUserPermission(PermissionName, callbacks);
        }

        public bool Show(string title, string body)
        {
            if (!_ready) return false;
            try
            {
                AndroidNotificationCenter.SendNotification(Build(title, body, DateTime.Now), "leaderboard");
                return true;
            }
            catch (Exception e) { Debug.LogWarning("Notification failed: " + e.Message); return false; }
        }

        public void ScheduleDailyBonusReminder(TimeSpan after, int chips) =>
            Schedule(DailyBonusId, "daily_bonus", "Your daily chips are ready!",
                $"Claim your free {chips} chips and grab a seat at the table.", after);

        public void CancelDailyBonusReminder() => Cancel(DailyBonusId);

        public void ScheduleStreakReminder(TimeSpan after, int streak) =>
            Schedule(StreakId, "streak", $"Your {streak}-day streak ends tonight", "Play one hand to keep it going.", after);

        public void CancelStreakReminder() => Cancel(StreakId);

        public void ScheduleEveningGift(DateTime firstAt)
        {
            if (!_ready) return;
            try
            {
                AndroidNotificationCenter.CancelScheduledNotification(EveningGiftId);
                var n = Build("Your free $500 chips are waiting!",
                    "Tap to collect your evening gift. Play chips for the game only, no real money.", firstAt);
                n.RepeatInterval = TimeSpan.FromDays(1);
                AndroidNotificationCenter.SendNotificationWithExplicitID(n, "evening_gift", EveningGiftId);
            }
            catch (Exception e) { Debug.LogWarning("Evening gift scheduling failed: " + e.Message); }
        }

        public void CancelEveningGift() => Cancel(EveningGiftId);

        /// <summary>
        /// The notification's tap launches the activity with its id as an intent extra; read it, then replace the activity's
        /// intent with an empty one so the same tap is never seen again on a later resume.
        /// </summary>
        public bool ConsumeEveningGiftTap()
        {
            if (!_ready) return false;
            try
            {
                var data = AndroidNotificationCenter.GetLastNotificationIntent();
                if (data == null || (data.Id != EveningGiftId && data.Id != QaEveningGiftId)) return false;
                using var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                using var activity = player.GetStatic<AndroidJavaObject>("currentActivity");
                using var blank = new AndroidJavaObject("android.content.Intent");
                activity.Call("setIntent", blank);
                Debug.Log("[Notif] evening gift notification tapped (id " + data.Id + ")");
                return true;
            }
            catch (Exception e) { Debug.LogWarning("Reading the notification tap failed: " + e.Message); return false; }
        }

#if BJ_QA_NOTIF
        /// <summary>Dev APK only: a one-off evening-gift notification <paramref name="seconds"/> from now, so QA need not wait for 20:00.</summary>
        public void QaScheduleGiftIn(int seconds)
        {
            if (!_ready) return;
            var n = Build("Your free $500 chips are waiting!",
                "Tap to collect your evening gift. Play chips for the game only, no real money.", DateTime.Now.AddSeconds(seconds));
            AndroidNotificationCenter.CancelScheduledNotification(QaEveningGiftId);
            AndroidNotificationCenter.SendNotificationWithExplicitID(n, "evening_gift", QaEveningGiftId);
            Debug.Log("[QA] test evening-gift notification scheduled in " + seconds + "s");
        }
#endif

        private void Schedule(int id, string channel, string title, string body, TimeSpan after)
        {
            if (!_ready) return;
            try
            {
                // The fixed id makes re-scheduling idempotent: it replaces the pending one.
                AndroidNotificationCenter.CancelScheduledNotification(id);
                AndroidNotificationCenter.SendNotificationWithExplicitID(Build(title, body, DateTime.Now + after), channel, id);
            }
            catch (Exception e) { Debug.LogWarning("Scheduling failed: " + e.Message); }
        }

        private void Cancel(int id)
        {
            if (!_ready) return;
            try { AndroidNotificationCenter.CancelScheduledNotification(id); }
            catch (Exception e) { Debug.LogWarning("Cancel failed: " + e.Message); }
        }

        private static AndroidNotification Build(string title, string body, DateTime fireAt) => new AndroidNotification
        {
            Title = title, Text = body, FireTime = fireAt, SmallIcon = "icon_small", LargeIcon = "icon_large",
        };
#else
        public bool HasPermission => true;
        public void Init() { }
        public void RequestPermission(Action<bool> granted) => granted(true);
        public bool Show(string title, string body) => false;
        public void ScheduleDailyBonusReminder(TimeSpan after, int chips) { }
        public void CancelDailyBonusReminder() { }
        public void ScheduleStreakReminder(TimeSpan after, int streak) { }
        public void CancelStreakReminder() { }
        public void ScheduleEveningGift(DateTime firstAt) { }
        public void CancelEveningGift() { }
        public bool ConsumeEveningGiftTap() => false;
#endif
    }
}
