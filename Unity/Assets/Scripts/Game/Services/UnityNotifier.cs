using System;
using UnityEngine;
#if UNITY_ANDROID && !UNITY_EDITOR
using Unity.Notifications.Android;
using UnityEngine.Android;
#endif

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Local notifications on Android (the daily-bonus and streak reminders, and friend/leaderboard alerts).
    /// Scheduled on the device, never from a server. Every call is a no-op off Android and never throws.
    /// </summary>
    public sealed class UnityNotifier : ILocalNotifier
    {
        private const int DailyBonusId = 210;
        private const int StreakId = 211;
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
#endif
    }
}
