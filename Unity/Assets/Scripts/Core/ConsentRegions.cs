using System;
using System.Collections.Generic;

namespace Blackjack.Core
{
    /// <summary>
    /// Where Google's consent platform (UMP) is expected to ask: the EEA, the UK and Switzerland. UMP itself decides from the
    /// device's location whether a form is needed; this list only decides what the game does until UMP has answered, so
    /// nothing optional is collected there before the player has chosen. The region comes from the device's region setting.
    /// An empty or unknown region is NOT restricted: UMP decides, and the game collects by default until the player or UMP says no.
    /// </summary>
    public static class ConsentRegions
    {
        private static readonly HashSet<string> Restricted = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            // EU member states
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT",
            "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
            // rest of the EEA
            "IS", "LI", "NO",
            // United Kingdom, its Crown dependencies and Gibraltar, which follow UK GDPR
            "GB", "JE", "GG", "IM", "GI",
            // Switzerland
            "CH",
        };

        public static bool IsConsentRestricted(string isoRegion) =>
            !string.IsNullOrWhiteSpace(isoRegion) && Restricted.Contains(isoRegion.Trim());
    }

    /// <summary>
    /// Whether usage and crash reports may be collected. On by default; off when the player switched them off, and in the
    /// EEA, UK and Switzerland also off unless Google's consent platform says the player agreed (<paramref name="consentGranted"/>).
    /// </summary>
    public static class AnalyticsPolicy
    {
        /// <param name="playerOptedIn">The Settings switch (true unless the player switched it off).</param>
        /// <param name="isoRegion">Device region; only used until consent is known.</param>
        /// <param name="consentGranted">UMP's answer for analytics storage, or null while it has not answered.</param>
        public static bool Allowed(bool playerOptedIn, string isoRegion, bool? consentGranted)
        {
            if (!playerOptedIn) return false;
            if (consentGranted.HasValue) return consentGranted.Value;
            return !ConsentRegions.IsConsentRestricted(isoRegion);
        }
    }

    /// <summary>The four Google consent-mode signals, as the player answered Google's consent platform (UMP).</summary>
    public readonly struct ConsentSignals
    {
        public readonly bool AnalyticsStorage, AdStorage, AdUserData, AdPersonalization;

        public ConsentSignals(bool analyticsStorage, bool adStorage, bool adUserData, bool adPersonalization)
        {
            AnalyticsStorage = analyticsStorage; AdStorage = adStorage; AdUserData = adUserData; AdPersonalization = adPersonalization;
        }

        public static readonly ConsentSignals AllGranted = new ConsentSignals(true, true, true, true);
        public static readonly ConsentSignals AllDenied = new ConsentSignals(false, false, false, false);
    }
}
