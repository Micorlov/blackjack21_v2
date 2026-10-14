using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Game.Services;
using Firebase.Analytics;
using Firebase.Crashlytics;
using UnityEngine;

namespace Blackjack.Game.Firebase
{
    /// <summary>
    /// Anonymous usage counts and crash reports. Switching it off tells the SDKs to stop collecting, not just this
    /// app to stop calling them.
    /// </summary>
    public sealed class FirebaseAnalyticsService : IAnalytics
    {
        private bool _enabled = true;

        public void SetEnabled(bool enabled)
        {
            _enabled = enabled;
            try
            {
                FirebaseAnalytics.SetAnalyticsCollectionEnabled(enabled);
                Crashlytics.IsCrashlyticsCollectionEnabled = enabled;
            }
            catch (Exception e) { Debug.LogWarning("Analytics.SetEnabled failed: " + e.Message); }
        }

        public void LogEvent(string name, IReadOnlyDictionary<string, object> parameters = null)
        {
            if (!_enabled) return;
            try
            {
                if (parameters == null || parameters.Count == 0) { FirebaseAnalytics.LogEvent(name); return; }
                FirebaseAnalytics.LogEvent(name, parameters.Select(p => ToParameter(p.Key, p.Value)).ToArray());
            }
            catch (Exception e) { Debug.LogWarning($"Analytics.LogEvent({name}) failed: {e.Message}"); }
        }

        public void LogScreen(string screen)
        {
            if (!_enabled) return;
            try
            {
                FirebaseAnalytics.LogEvent(FirebaseAnalytics.EventScreenView,
                    new Parameter(FirebaseAnalytics.ParameterScreenName, screen));
            }
            catch (Exception e) { Debug.LogWarning($"Analytics.LogScreen({screen}) failed: {e.Message}"); }
        }

        private static Parameter ToParameter(string key, object value) => value switch
        {
            int i => new Parameter(key, i),
            long l => new Parameter(key, l),
            double d => new Parameter(key, d),
            float f => new Parameter(key, (double)f),
            bool b => new Parameter(key, b ? 1 : 0),
            _ => new Parameter(key, Convert.ToString(value)),
        };
    }
}
