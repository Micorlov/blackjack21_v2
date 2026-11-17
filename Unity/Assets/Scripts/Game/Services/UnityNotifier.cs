using System;
using Blackjack.Core;
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
        // The following days' reminders: one id each, so each can carry its own text.
        private static int EveningGiftIdAt(int i) => i == 0 ? EveningGiftId : 220 + i;
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
            Schedule(DailyBonusId, "daily_bonus", Loc.T("notifDailyBonusTitle"), Loc.T("notifDailyBonusBody", ("chips", chips)), after);

        public void CancelDailyBonusReminder() => Cancel(DailyBonusId);

        public void ScheduleStreakReminder(TimeSpan after, int streak) =>
            Schedule(StreakId, "streak", Loc.T("notifStreakTitle", ("days", streak)), Loc.T("notifStreakBody"), after);

        public void CancelStreakReminder() => Cancel(StreakId);

        public void ScheduleEveningGift(DateTime firstAt)
        {
            if (!_ready) return;
            try
            {
                // shortcut: not repeating, so a player who stays away more than EveningGift.DaysAhead days stops hearing from us;
                // every launch and resume re-arms the next week.
                var upcoming = EveningGift.Upcoming(firstAt);
                for (var i = 0; i < upcoming.Count; i++)
                {
                    var (at, variant) = upcoming[i];
                    var n = Build(Loc.T("eveningTitle" + variant), Loc.T("eveningBody" + variant), at);
                    AndroidNotificationCenter.CancelScheduledNotification(EveningGiftIdAt(i));
                    AndroidNotificationCenter.SendNotificationWithExplicitID(n, "evening_gift", EveningGiftIdAt(i));
                }
            }
            catch (Exception e) { Debug.LogWarning("Evening gift scheduling failed: " + e.Message); }
        }

        private static bool IsEveningGiftId(int id)
        {
            for (var i = 0; i < EveningGift.DaysAhead; i++) if (id == EveningGiftIdAt(i)) return true;
            return false;
        }

        public void CancelEveningGift()
        {
            for (var i = 0; i < EveningGift.DaysAhead; i++) Cancel(EveningGiftIdAt(i));
        }

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
                if (data == null || (!IsEveningGiftId(data.Id) && data.Id != QaEveningGiftId)) return false;
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
            var n = Build(Loc.T("eveningTitle1"), Loc.T("eveningBody1"), DateTime.Now.AddSeconds(seconds));
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
