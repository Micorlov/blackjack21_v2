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
    /// Anonymous usage counts and crash reports. Collection is on from launch (the manifest no longer switches it off), so
    /// first_open is counted; switching it off, or declining Google's consent form, tells the SDKs to stop collecting, not just
    /// this app to stop calling them.
    /// </summary>
    public sealed class FirebaseAnalyticsService : IAnalytics
    {
        /// <summary>
        /// True while usage and crash reports may be collected: on unless the player switched them off or, in the EEA, UK and
        /// Switzerland, Google's consent form did not grant it. The install and error records in <see cref="FirebaseRegistration"/>
        /// follow it too. Starts true because the SDKs start collecting.
        /// </summary>
        public static bool CollectionAllowed { get; private set; } = true;

        private bool _enabled = true;

        public void SetEnabled(bool enabled)
        {
            _enabled = enabled;
            CollectionAllowed = enabled;
            try
            {
#if !BJ_FIREBASE_EMULATOR
                // Explicit every time: Crashlytics keeps its last override across launches.
                FirebaseAnalytics.SetAnalyticsCollectionEnabled(enabled);
                Crashlytics.IsCrashlyticsCollectionEnabled = enabled;
#endif
            }
            catch (Exception e) { Debug.LogWarning("Analytics.SetEnabled failed: " + e.Message); }
        }

        public void SetConsent(Core.ConsentSignals consent)
        {
            try
            {
#if !BJ_FIREBASE_EMULATOR
                FirebaseAnalytics.SetConsent(new Dictionary<ConsentType, ConsentStatus>
                {
                    { ConsentType.AnalyticsStorage, consent.AnalyticsStorage ? ConsentStatus.Granted : ConsentStatus.Denied },
                    { ConsentType.AdStorage, consent.AdStorage ? ConsentStatus.Granted : ConsentStatus.Denied },
                    { ConsentType.AdUserData, consent.AdUserData ? ConsentStatus.Granted : ConsentStatus.Denied },
                    { ConsentType.AdPersonalization, consent.AdPersonalization ? ConsentStatus.Granted : ConsentStatus.Denied },
                });
#endif
                Debug.Log($"Consent mode: analytics_storage={consent.AnalyticsStorage} ad_storage={consent.AdStorage} ad_user_data={consent.AdUserData} ad_personalization={consent.AdPersonalization}");
            }
            catch (Exception e) { Debug.LogWarning("Analytics.SetConsent failed: " + e.Message); }
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
