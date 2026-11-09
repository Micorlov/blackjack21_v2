using System;
using System.IO;
using System.Text.RegularExpressions;
using Blackjack.Game.Ads;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    /// <summary>The Play release must request this publisher's units, never Google's samples.</summary>
    public sealed class AdReleaseTests
    {
        private static string ProjectRoot()
        {
            var fromEnv = Environment.GetEnvironmentVariable("BJ_PROJECT");
            var starts = string.IsNullOrEmpty(fromEnv)
                ? new[] { Directory.GetCurrentDirectory(), AppContext.BaseDirectory }
                : new[] { fromEnv, Directory.GetCurrentDirectory(), AppContext.BaseDirectory };
            foreach (var start in starts)
            {
                var dir = new DirectoryInfo(start);
                while (dir != null)
                {
                    if (File.Exists(Path.Combine(dir.FullName, "ProjectSettings", "ProjectSettings.asset")))
                        return dir.FullName;
                    dir = dir.Parent;
                }
            }
            Assert.Fail("Could not find the Unity project from " + Directory.GetCurrentDirectory());
            return "";
        }

        private static string ReadProjectFile(string relative)
        {
            var path = Path.Combine(ProjectRoot(), relative);
            if (!File.Exists(path)) Assert.Fail("Missing " + path);
            return File.ReadAllText(path);
        }

        [Test]
        public void ReleaseUnits_belongToThisPublisher_andAreNotSamples()
        {
            Assert.IsFalse(AdConfig.USE_TEST_ADS);
            Assert.IsFalse(AdConfig.UseTestAds, "EditMode is the release configuration: ADMOB_TEST_ADS is not defined");
            Assert.AreEqual("ca-app-pub-2693008307172998~5118761930", AdConfig.AndroidAppId);

            foreach (var unit in new[] { AdConfig.ReleaseBanner, AdConfig.ReleaseInterstitial, AdConfig.ReleaseRewarded })
            {
                StringAssert.StartsWith("ca-app-pub-2693008307172998/", unit);
                StringAssert.DoesNotContain(AdConfig.SamplePublisher, unit);
            }
            Assert.AreEqual(AdConfig.ReleaseBanner, AdConfig.BannerUnit);
            Assert.AreEqual(AdConfig.ReleaseInterstitial, AdConfig.InterstitialUnit);
            Assert.AreEqual(AdConfig.ReleaseRewarded, AdConfig.RewardedUnit);
            StringAssert.Contains(AdConfig.SamplePublisher, AdConfig.SampleBanner);
        }

        [Test]
        public void ManifestAndSettings_useTheRealAppId_andKeepTheAdvertisingId()
        {
            var manifest = ReadProjectFile("Assets/Plugins/Android/BlackjackExtras.androidlib/src/main/AndroidManifest.xml");
            var settings = ReadProjectFile("Assets/GoogleMobileAds/Resources/GoogleMobileAdsSettings.asset");
            StringAssert.Contains(AdConfig.AndroidAppId, manifest);
            StringAssert.Contains("adMobAndroidAppId: " + AdConfig.AndroidAppId, settings);
            StringAssert.Contains("com.google.android.gms.permission.AD_ID", manifest);
            StringAssert.DoesNotContain("tools:node=\"remove\"", manifest);
            StringAssert.Contains("com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT", manifest);
            StringAssert.Contains("google_analytics_adid_collection_enabled", manifest);
            StringAssert.DoesNotContain(AdConfig.SamplePublisher, manifest);
            StringAssert.DoesNotContain(AdConfig.SamplePublisher, settings);
        }

        [Test]
        public void Version_isNewerThanTheLivePlayRelease()
        {
            // Live on Play is 1.8.2 (12). Update this test when cutting the next release.
            var source = ReadProjectFile("Assets/Scripts/Editor/BuildTools.cs");
            var settings = ReadProjectFile("ProjectSettings/ProjectSettings.asset");
            var code = Regex.Match(source, @"VersionCode = (\d+);");
            Assert.IsTrue(code.Success);
            Assert.Greater(int.Parse(code.Groups[1].Value), 12);
            StringAssert.Contains("VersionName = \"1.8.3\"", source);
            StringAssert.Contains("bundleVersion: 1.8.3", settings);
            StringAssert.Contains("AndroidBundleVersionCode: 13", settings);
        }
    }
}
