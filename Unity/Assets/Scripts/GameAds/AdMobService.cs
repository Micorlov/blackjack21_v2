using System;
using Blackjack.Game.Services;
using GoogleMobileAds.Api;
using GoogleMobileAds.Common;
using GoogleMobileAds.Ump.Api;
using UnityEngine;

namespace Blackjack.Game.Ads
{
    /// <summary>
    /// Google AdMob behind <see cref="IAds"/>: consent first, then one rewarded video, one interstitial and one
    /// bottom banner kept loaded. A failed load is retried the next time the game asks, and a withdrawn consent
    /// drops whatever is loaded, so ads can never hold the game up.
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
        private bool _showingFullscreen;
        private int _generation;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Register() => ServiceFactories.Ads = () => new AdMobService();

        public void Init()
        {
            try
            {
                // Obsolete, but still the switch that delivers every SDK callback — consent included — on the
                // main thread. ExecuteInUpdate only runs work we queue ourselves.
#pragma warning disable 0618
                MobileAds.RaiseAdEventsOnUnityMainThread = true;
#pragma warning restore 0618
                // Main-thread callbacks wait for this object, which the SDK only makes when first used. Consent has to
                // answer before that on a fresh install, so without this its callback never arrives and ads never start.
                MobileAdsEventExecutor.Initialize();
                // Consent stored from an earlier launch still counts, so ads need not wait for this launch's check.
                ApplyConsent();
                ConsentInformation.Update(new ConsentRequestParameters(), updateError =>
                {
                    if (updateError != null)
                    {
                        Debug.LogWarning("Ad consent check failed: " + updateError.Message);
                        // A failed check still leaves the last stored answer. Outside a regulated region that answer
                        // already allows ads; where it does not, nothing is requested.
                        ApplyConsent();
                        return;
                    }
                    ConsentForm.LoadAndShowConsentFormIfRequired(formError =>
                    {
                        if (formError != null) Debug.LogWarning("Ad consent form failed: " + formError.Message);
                        ApplyConsent();
                    });
                });
            }
            catch (Exception e)
            {
                Debug.LogWarning("Ads did not start: " + e.Message);
            }
        }

        private void ApplyConsent()
        {
            if (ConsentInformation.CanRequestAds()) StartIfAllowed();
            else StopAds();
        }

        private void StartIfAllowed()
        {
            if (_started || !ConsentInformation.CanRequestAds()) return;
            _started = true;
            // Before Initialize, so the first request already carries it. The game is not child-directed
            // (terms are 18+). Unspecified is this plugin's "do not apply child or teen treatment" value.
            // Ads are capped at Teen because Play rates the app Teen in some regions and 18+ in others.
            MobileAds.SetRequestConfiguration(new RequestConfiguration
            {
                AgeRestrictedTreatment = AgeRestrictedTreatment.Unspecified,
                MaxAdContentRating = MaxAdContentRating.T,
            });
            MobileAds.Initialize(_ =>
            {
                LoadRewarded();
                LoadInterstitial();
                LoadBanner();
            });
        }

        private void StopAds()
        {
            _generation++;
            _started = false;
            _loadingRewarded = false;
            _loadingInterstitial = false;
            _bannerRetryAt = DateTime.MinValue;
            DestroyBanner();
            // A video already on screen lives in the Show* method, not these fields, and closes itself.
            // Nothing new is loaded once _started is false.
            SafeDestroy(ref _rewarded);
            SafeDestroy(ref _interstitial);
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
            try
            {
                if (_rewarded != null && !_rewarded.CanShowAd()) SafeDestroy(ref _rewarded);
                if (!_started || _rewarded != null || _loadingRewarded) return;
                _loadingRewarded = true;
                var generation = _generation;
                RewardedAd.Load(AdConfig.RewardedUnit, new AdRequest(), (ad, error) =>
                {
                    if (generation != _generation || !_started)
                    {
                        if (generation == _generation) _loadingRewarded = false;
                        ad?.Destroy();
                        return;
                    }
                    _loadingRewarded = false;
                    if (error != null || ad == null) Debug.LogWarning("Rewarded ad did not load: " + error);
                    else _rewarded = ad;
                });
            }
            catch (Exception e)
            {
                _loadingRewarded = false;
                Debug.LogWarning("Rewarded ad did not load: " + e.Message);
            }
        }

        private void LoadInterstitial()
        {
            try
            {
                if (_interstitial != null && !_interstitial.CanShowAd()) SafeDestroy(ref _interstitial);
                if (!_started || _interstitial != null || _loadingInterstitial) return;
                _loadingInterstitial = true;
                var generation = _generation;
                InterstitialAd.Load(AdConfig.InterstitialUnit, new AdRequest(), (ad, error) =>
                {
                    if (generation != _generation || !_started)
                    {
                        if (generation == _generation) _loadingInterstitial = false;
                        ad?.Destroy();
                        return;
                    }
                    _loadingInterstitial = false;
                    if (error != null || ad == null) Debug.LogWarning("Interstitial ad did not load: " + error);
                    else _interstitial = ad;
                });
            }
            catch (Exception e)
            {
                _loadingInterstitial = false;
                Debug.LogWarning("Interstitial ad did not load: " + e.Message);
            }
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
            try
            {
                if (!_started || _banner != null || DateTime.UtcNow < _bannerRetryAt) return;
                var size = AdSize.GetCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(AdSize.FullWidth);
                var banner = new BannerView(AdConfig.BannerUnit, size, AdPosition.Bottom);
                var generation = _generation;
                // Stay hidden until a creative arrives, so an empty banner cannot cover the table or steal taps.
                banner.Hide();
                _banner = banner;
                banner.OnBannerAdLoaded += () =>
                {
                    if (generation != _generation || _banner != banner) return;
                    var height = banner.GetHeightInPixels();
                    if (height <= 0f && Screen.dpi > 0f) height = 50f * Screen.dpi / 160f;
                    _bannerHeight = height;
                    banner.Show();
                };
                banner.OnBannerAdLoadFailed += error =>
                {
                    Debug.LogWarning("Banner ad did not load: " + error);
                    if (_banner == banner) DestroyBanner();
                    else banner.Destroy();
                    if (generation == _generation) _bannerRetryAt = DateTime.UtcNow + BannerRetry;
                };
                banner.LoadAd(new AdRequest());
            }
            catch (Exception e)
            {
                Debug.LogWarning("Banner ad did not load: " + e.Message);
                DestroyBanner();
                _bannerRetryAt = DateTime.UtcNow + BannerRetry;
            }
        }

        private void DestroyBanner()
        {
            _bannerHeight = 0f;
            if (_banner == null) return;
            try { _banner.Destroy(); }
            catch (Exception e) { Debug.LogWarning("Banner cleanup failed: " + e.Message); }
            _banner = null;
        }

        public void ShowRewarded(Action<bool> done)
        {
            LoadRewarded();
            var ad = _rewarded;
            _rewarded = null;
            if (ad == null || _showingFullscreen)
            {
                done?.Invoke(false);
                return;
            }

            var earned = false;
            var settled = false;
            void Finish()
            {
                if (settled) return;
                settled = true;
                _showingFullscreen = false;
                try { ad.Destroy(); }
                catch (Exception e) { Debug.LogWarning("Rewarded cleanup failed: " + e.Message); }
                LoadRewarded();
                try { done?.Invoke(earned); }
                catch (Exception e) { Debug.LogWarning("Rewarded ad callback failed: " + e.Message); }
            }
            ad.OnAdFullScreenContentClosed += Finish;
            ad.OnAdFullScreenContentFailed += _ => Finish();
            try
            {
                _showingFullscreen = true;
                ad.Show(_ => earned = true);
            }
            catch (Exception e)
            {
                Debug.LogWarning("Rewarded ad did not show: " + e.Message);
                Finish();
            }
        }

        public bool ShowInterstitial()
        {
            LoadInterstitial();
            var ad = _interstitial;
            _interstitial = null;
            if (ad == null || _showingFullscreen) return false;

            var settled = false;
            void Finish()
            {
                if (settled) return;
                settled = true;
                _showingFullscreen = false;
                try { ad.Destroy(); }
                catch (Exception e) { Debug.LogWarning("Interstitial cleanup failed: " + e.Message); }
                LoadInterstitial();
            }
            ad.OnAdFullScreenContentClosed += Finish;
            ad.OnAdFullScreenContentFailed += _ => Finish();
            try
            {
                _showingFullscreen = true;
                ad.Show();
                return true;
            }
            catch (Exception e)
            {
                Debug.LogWarning("Interstitial ad did not show: " + e.Message);
                Finish();
                return false;
            }
        }

        public bool PrivacyOptionsRequired =>
            ConsentInformation.PrivacyOptionsRequirementStatus == PrivacyOptionsRequirementStatus.Required;

        public void ShowPrivacyOptions() => ConsentForm.ShowPrivacyOptionsForm(error =>
        {
            if (error != null) Debug.LogWarning("Ad privacy form failed: " + error.Message);
            ApplyConsent();
        });

        private static void SafeDestroy(ref RewardedAd ad)
        {
            if (ad == null) return;
            try { ad.Destroy(); }
            catch (Exception e) { Debug.LogWarning("Rewarded cleanup failed: " + e.Message); }
            ad = null;
        }

        private static void SafeDestroy(ref InterstitialAd ad)
        {
            if (ad == null) return;
            try { ad.Destroy(); }
            catch (Exception e) { Debug.LogWarning("Interstitial cleanup failed: " + e.Message); }
            ad = null;
        }
    }
}
