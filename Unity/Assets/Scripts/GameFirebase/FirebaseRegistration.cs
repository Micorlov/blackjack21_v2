using System;
using System.Collections.Generic;
using Blackjack.Game.Services;
using Firebase.Firestore;
using UnityEngine;

namespace Blackjack.Game.Firebase
{
    /// <summary>
    /// Registers the Firebase-backed services before the game starts; present only when the SDK is imported. Also
    /// writes the install ping (once per launch, after the first sign-in) and fatal errors, as the Flutter app did.
    /// </summary>
    public static class FirebaseRegistration
    {
        private const int MaxMessageLength = 500;
        private const int MaxStackLength = 2000;

        private static FirebaseSocialService _social;
        private static bool _installReported;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Register()
        {
            _social = new FirebaseSocialService();
            ServiceFactories.Social = () => _social;
            ServiceFactories.Analytics = () => new FirebaseAnalyticsService();
            Application.logMessageReceived += OnLog;
        }

        internal static void ReportInstallOnce()
        {
            if (_installReported || _social == null || !_social.Available) return;
            _installReported = true;
            Write("installs", new Dictionary<string, object>
            {
                ["appVersion"] = Application.version,
                ["platform"] = Application.platform.ToString().ToLowerInvariant(),
                ["at"] = FieldValue.ServerTimestamp,
            });
        }

        private static void OnLog(string message, string stack, LogType type)
        {
            if (type != LogType.Exception || _social == null || !_social.Available) return;
            Write("errors", new Dictionary<string, object>
            {
                ["message"] = Truncate(message, MaxMessageLength),
                ["stack"] = Truncate(stack, MaxStackLength),
                ["appVersion"] = Application.version,
                ["platform"] = Application.platform.ToString().ToLowerInvariant(),
                ["at"] = FieldValue.ServerTimestamp,
            });
        }

        private static string Truncate(string value, int max) =>
            value == null || value.Length <= max ? value : value.Substring(0, max);

        private static void Write(string collection, Dictionary<string, object> data)
        {
            try { FirebaseFirestore.DefaultInstance.Collection(collection).AddAsync(data); }
            catch (Exception e) { Debug.LogWarning($"Firebase {collection} write failed: {e.Message}"); }
        }
    }
}
