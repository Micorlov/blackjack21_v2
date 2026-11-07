namespace Blackjack.Game.Ads
{
    /// <summary>Every AdMob unit ID the game uses, and the one switch between Google's sample units and ours.</summary>
    public static class AdConfig
    {
        /// <summary>Flip to false for a Play release. Builds made with ADMOB_TEST_ADS (the adb APK) stay on test units regardless.</summary>
        public const bool USE_TEST_ADS = true;

#if ADMOB_TEST_ADS
        // The adb build sits on the developer's phone, and real ads there break AdMob policy.
        private const bool TestBuild = true;
#else
        private const bool TestBuild = false;
#endif

        public static bool UseTestAds => USE_TEST_ADS || TestBuild;

        // Google's public sample units.
        private const string TestBanner = "ca-app-pub-3940256099942544/9214589741";
        private const string TestInterstitial = "ca-app-pub-3940256099942544/1033173712";
        private const string TestRewarded = "ca-app-pub-3940256099942544/5224354917";

        public const string RealBannerPlaceholder = "ca-app-pub-2693008307172998/REPLACE_WITH_BANNER_UNIT";
        private const string RealBanner = RealBannerPlaceholder;
        private const string RealInterstitial = "ca-app-pub-2693008307172998/2053614897";
        private const string RealRewarded = "ca-app-pub-2693008307172998/6844721230";

        public static string BannerUnit => UseTestAds ? TestBanner : RealBanner;
        public static string InterstitialUnit => UseTestAds ? TestInterstitial : RealInterstitial;
        public static string RewardedUnit => UseTestAds ? TestRewarded : RealRewarded;
    }
}
