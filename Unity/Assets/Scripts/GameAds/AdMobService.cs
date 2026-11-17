using System;
using System.Globalization;
using Blackjack.Core;
using Blackjack.Game.Services;
using GoogleMobileAds.Api;
using GoogleMobileAds.Common;
using GoogleMobileAds.Ump.Api;
using UnityEngine;

namespace Blackjack.Game.Ads
{
    /// <summary>
    /// Google AdMob behind <see cref="IAds"/>: consent first, then one rewarded video and one interstitial kept
    /// loaded. A failed load is retried the next time the game asks, so ads can never hold the game up.
    /// </summary>
    public sealed class AdMobService : IAds
    {
        private static readonly TimeSpan BannerRetry = TimeSpan.FromSeconds(30);

        private RewardedAd _rewarded;
        private BannerView _banner;
        private float _bannerHeight;
        private DateTime _bannerRetryAt;
        private InterstitialAd _interstitial;
        private bool _loadingRewarded;
        private bool _loadingInterstitial;
        private bool _started;
        private bool _consentChecked;

        public event Action ConsentChanged;

        /// <summary>
        /// Google consent mode from what UMP recorded: nothing to ask means everything is allowed; once answered, the IAB TCF
        /// purpose consents decide (purpose 1 is storage, 3 and 4 personalisation, 7 measurement); required but unanswered means denied.
        /// Null until the launch check has run.
        /// </summary>
        public ConsentSignals? Consent
        {
            get
            {
                if (!_consentChecked) return null;
                switch (ConsentInformation.ConsentStatus)
                {
                    case ConsentStatus.NotRequired: return ConsentSignals.AllGranted;
                    case ConsentStatus.Required: return ConsentSignals.AllDenied;
                    case ConsentStatus.Obtained:
                        var p = ReadPurposeConsents();
                        if (p == null) return ConsentSignals.AllDenied;
                        bool P(int n) => p.Length >= n && p[n - 1] == '1';
                        return new ConsentSignals(analyticsStorage: P(1), adStorage: P(1), adUserData: P(1) && P(7),
                            adPersonalization: P(1) && P(3) && P(4));
                    default: return null;
                }
            }
        }

        /// <summary>The TCF purpose consent string UMP stores in the app's default preferences, e.g. "1010000011"; null when absent.</summary>
        private static string ReadPurposeConsents()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                using (var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                using (var activity = player.GetStatic<AndroidJavaObject>("currentActivity"))
                using (var manager = new AndroidJavaClass("android.preference.PreferenceManager"))
                using (var prefs = manager.CallStatic<AndroidJavaObject>("getDefaultSharedPreferences", activity))
                {
                    var tcf = prefs.Call<string>("getString", "IABTCF_PurposeConsents", "");
                    return string.IsNullOrEmpty(tcf) ? null : tcf;
                }
            }
            catch (Exception e) { Debug.LogWarning("Consent: could not read TCF purposes: " + e.Message); }
#endif
            return null;
        }

        /// <summary>Device region (ISO 3166-1 alpha-2), the only location signal the game has; empty when unknown.</summary>
        private static string Region
        {
            get
            {
#if BJ_FIREBASE_EMULATOR
                var qa = QaOverrides.Extra("bj_region");
                if (qa != null) return qa;
#endif
                try { return RegionInfo.CurrentRegion.TwoLetterISORegionName; }
                catch (Exception) { return ""; }
            }
        }

        /// <summary>
        /// Never set from the region: the game is for ages 13 and over, and the under-age tag would stop UMP from asking anyone.
        /// Only QA builds can set it, from a launch extra, to observe the SDK.
        /// </summary>
        private static bool UnderAgeOfConsent
        {
            get
            {
#if BJ_FIREBASE_EMULATOR
                if (QaOverrides.Extra("bj_tfua") == "on") return true;
#endif
                return false;
            }
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Register() => ServiceFactories.Ads = () => new AdMobService();

        public void Init()
        {
            MobileAds.RaiseAdEventsOnUnityMainThread = true;
            // Main-thread callbacks wait for this object, which the SDK only makes when first used. Consent has to answer
            // before that on a fresh install, so without this its callback never arrives and ads never start.
            MobileAdsEventExecutor.Initialize();
            // Consent given on an earlier launch still counts, so ads need not wait for this launch's check.
            StartIfAllowed();
            // Google's consent platform decides from the device's location whether to ask (EEA, UK, Switzerland) and does nothing
            // elsewhere. The game is for ages 13 and over, so it never sets the under-age tag, which would suppress the form.
            var parameters = new ConsentRequestParameters { TagForUnderAgeOfConsent = UnderAgeOfConsent };
#if BJ_FIREBASE_EMULATOR
            // QA builds only: force a geography and flip the tag from launch extras to observe the SDK. Never in a release.
            if (QaOverrides.Extra("bj_geo") == "eea")
                parameters.ConsentDebugSettings = new ConsentDebugSettings { DebugGeography = DebugGeography.EEA };
#endif
            Debug.Log($"UMP: asking with region={Region} tagForUnderAgeOfConsent={parameters.TagForUnderAgeOfConsent}");
            ConsentInformation.Update(parameters, updateError =>
            {
                if (updateError != null)
                {
                    Debug.LogWarning("Ad consent check failed: " + updateError.Message);
                    ConsentChanged?.Invoke();
                    return;
                }
                _consentChecked = true;
                Debug.Log($"UMP: updated, status={ConsentInformation.ConsentStatus} canRequestAds={ConsentInformation.CanRequestAds()} privacyOptions={ConsentInformation.PrivacyOptionsRequirementStatus}");
                ConsentForm.LoadAndShowConsentFormIfRequired(formError =>
                {
                    if (formError != null) Debug.LogWarning("Ad consent form failed: " + formError.Message);
                    Debug.Log($"UMP: form step finished, status={ConsentInformation.ConsentStatus} canRequestAds={ConsentInformation.CanRequestAds()} privacyOptions={ConsentInformation.PrivacyOptionsRequirementStatus}");
                    StartIfAllowed();
                    ConsentChanged?.Invoke();
                });
            });
        }

        private void StartIfAllowed()
        {
            if (_started || !ConsentInformation.CanRequestAds()) return;
            _started = true;
            // The game is for ages 13 and up, minors included, and has no age screen. Every ad request is age-restricted, and the
            // treatment is Teen everywhere (Child only in a QA build that sets the under-age tag). Teen allows no
            // personalised ads or remarketing. The rating cap asks for ads rated Teen or lower. Must precede MobileAds.Initialize.
            MobileAds.SetRequestConfiguration(new RequestConfiguration
            {
                AgeRestrictedTreatment = UnderAgeOfConsent ? AgeRestrictedTreatment.Child : AgeRestrictedTreatment.Teen,
                MaxAdContentRating = MaxAdContentRating.T,
            });
            Debug.Log($"Ads: region={Region} ageTreatment={(UnderAgeOfConsent ? "Child" : "Teen")} maxRating=T canRequestAds={ConsentInformation.CanRequestAds()}");
            MobileAds.Initialize(_ =>
            {
                LoadRewarded();
                LoadInterstitial();
                LoadBanner();
            });
        }

        public bool RewardedReady
        {
            get
            {
                LoadRewarded();
                return _rewarded != null;
            }
        }

        private void LoadRewarded()
        {
            if (_rewarded != null && !_rewarded.CanShowAd()) { _rewarded.Destroy(); _rewarded = null; }
            if (!_started || _rewarded != null || _loadingRewarded) return;
            _loadingRewarded = true;
            RewardedAd.Load(AdConfig.RewardedUnit, new AdRequest(), (ad, error) =>
            {
                _loadingRewarded = false;
                if (error != null || ad == null) Debug.LogWarning("Rewarded ad did not load: " + error);
                else _rewarded = ad;
            });
        }

        private void LoadInterstitial()
        {
            if (_interstitial != null && !_interstitial.CanShowAd()) { _interstitial.Destroy(); _interstitial = null; }
            if (!_started || _interstitial != null || _loadingInterstitial) return;
            _loadingInterstitial = true;
            InterstitialAd.Load(AdConfig.InterstitialUnit, new AdRequest(), (ad, error) =>
            {
                _loadingInterstitial = false;
                if (error != null || ad == null) Debug.LogWarning("Interstitial ad did not load: " + error);
                else _interstitial = ad;
            });
        }

        /// <summary>Asked every frame by the UI, which keeps this much room free; a failed banner is retried from here.</summary>
        public float BannerHeightPixels
        {
            get
            {
                LoadBanner();
                return _bannerHeight;
            }
        }

        private void LoadBanner()
        {
            if (!_started || _banner != null || DateTime.UtcNow < _bannerRetryAt) return;
            var size = AdSize.GetCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(AdSize.FullWidth);
            var banner = new BannerView(AdConfig.BannerUnit, size, AdPosition.Bottom);
            _banner = banner;
            banner.OnBannerAdLoaded += () => _bannerHeight = banner.GetHeightInPixels();
            banner.OnBannerAdLoadFailed += error =>
            {
                Debug.LogWarning("Banner ad did not load: " + error);
                banner.Destroy();
                _banner = null;
                _bannerHeight = 0;
                _bannerRetryAt = DateTime.UtcNow + BannerRetry;
            };
            banner.LoadAd(new AdRequest());
        }

        public void ShowRewarded(Action<bool> done)
        {
            LoadRewarded();
            var ad = _rewarded;
            _rewarded = null;
            if (ad == null) { done(false); return; }

            var earned = false;
            void Finish()
            {
                ad.Destroy();
                LoadRewarded();
                done(earned);
            }
            ad.OnAdFullScreenContentClosed += Finish;
            ad.OnAdFullScreenContentFailed += _ => Finish();
            ad.Show(_ => earned = true);
        }

        public bool InterstitialReady
        {
            get
            {
                LoadInterstitial();
                return _interstitial != null;
            }
        }

        public bool ShowInterstitial(Action closed = null)
        {
            LoadInterstitial();
            var ad = _interstitial;
            _interstitial = null;
            if (ad == null) return false;

            void Finish()
            {
                ad.Destroy();
                LoadInterstitial();
                closed?.Invoke();
            }
            ad.OnAdFullScreenContentClosed += Finish;
            ad.OnAdFullScreenContentFailed += _ => Finish();
            ad.Show();
            return true;
        }

        public bool PrivacyOptionsRequired =>
            ConsentInformation.PrivacyOptionsRequirementStatus == PrivacyOptionsRequirementStatus.Required;

        public void ShowPrivacyOptions() => ConsentForm.ShowPrivacyOptionsForm(error =>
        {
            if (error != null) Debug.LogWarning("Ad privacy form failed: " + error.Message);
            StartIfAllowed();
            ConsentChanged?.Invoke();
        });
    }
}
