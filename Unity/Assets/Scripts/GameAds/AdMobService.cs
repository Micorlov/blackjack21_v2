using System;
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
            ConsentInformation.Update(new ConsentRequestParameters(), updateError =>
            {
                if (updateError != null)
                {
                    Debug.LogWarning("Ad consent check failed: " + updateError.Message);
                    return;
                }
                ConsentForm.LoadAndShowConsentFormIfRequired(formError =>
                {
                    if (formError != null) Debug.LogWarning("Ad consent form failed: " + formError.Message);
                    StartIfAllowed();
                });
            });
        }

        private void StartIfAllowed()
        {
            if (_started || !ConsentInformation.CanRequestAds()) return;
            _started = true;
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

        public bool ShowInterstitial()
        {
            LoadInterstitial();
            var ad = _interstitial;
            _interstitial = null;
            if (ad == null) return false;

            void Finish()
            {
                ad.Destroy();
                LoadInterstitial();
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
        });
    }
}
