namespace Blackjack.Game.Ads
{
    /// <summary>
    /// Every AdMob id the game uses. A Play release requests <see cref="ReleaseBanner"/>,
    /// <see cref="ReleaseInterstitial"/> and <see cref="ReleaseRewarded"/>. Google's sample publisher
    /// is used only when <see cref="USE_TEST_ADS"/> is set, or when the adb build defines ADMOB_TEST_ADS.
    /// </summary>
    public static class AdConfig
    {
        /// <summary>Keep equal to GoogleMobileAdsSettings.asset and the BlackjackExtras manifest.</summary>
        public const string AndroidAppId = "ca-app-pub-2693008307172998~5118761930";

        /// <summary>Google's public sample publisher. A Play release must never request it.</summary>
        public const string SamplePublisher = "ca-app-pub-3940256099942544";

        /// <summary>Left false for the Play release. The adb APK still forces sample units via ADMOB_TEST_ADS.</summary>
        public const bool USE_TEST_ADS = false;

        public const string ReleaseBanner = "ca-app-pub-2693008307172998/1350520276";
        public const string ReleaseInterstitial = "ca-app-pub-2693008307172998/2053614897";
        public const string ReleaseRewarded = "ca-app-pub-2693008307172998/6844721230";

        public const string SampleBanner = SamplePublisher + "/9214589741";
        public const string SampleInterstitial = SamplePublisher + "/1033173712";
        public const string SampleRewarded = SamplePublisher + "/5224354917";

#if ADMOB_TEST_ADS
        private const bool TestBuild = true;
#else
        private const bool TestBuild = false;
#endif

        public static bool UseTestAds => USE_TEST_ADS || TestBuild;

        public static string BannerUnit => UseTestAds ? SampleBanner : ReleaseBanner;
        public static string InterstitialUnit => UseTestAds ? SampleInterstitial : ReleaseInterstitial;
        public static string RewardedUnit => UseTestAds ? SampleRewarded : ReleaseRewarded;
    }
}
