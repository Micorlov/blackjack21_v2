using Blackjack.Game;
using Blackjack.Game.Services;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class ConsentRegionTests
    {
        [TestCase("DE"), TestCase("fr"), TestCase("IE"), TestCase("SE"), TestCase("NO"), TestCase("IS"), TestCase("LI"),
         TestCase("GB"), TestCase("CH"), TestCase("GI"), TestCase("JE"), TestCase("GG"), TestCase("IM"), TestCase(" de ")]
        public void EeaUkAndSwitzerland_areConsentRestricted(string region) =>
            Assert.IsTrue(ConsentRegions.IsConsentRestricted(region), region ?? "(null)");

        [TestCase("US"), TestCase("IL"), TestCase("CA"), TestCase("BR"), TestCase("JP"), TestCase("AU"), TestCase("IN"), TestCase("MX"), TestCase(""), TestCase(null), TestCase("  ")]
        public void OtherRegions_andAnUnknownRegion_areNot(string region) => Assert.IsFalse(ConsentRegions.IsConsentRestricted(region), region);

        [Test]
        public void AllTwentySevenEuMembersAreCovered()
        {
            foreach (var c in new[] { "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT",
                                      "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE" })
                Assert.IsTrue(ConsentRegions.IsConsentRestricted(c), c);
        }

        [Test]
        public void Analytics_isOnByDefault_followsTheSwitch_andWhereRequiredTheConsentAnswer()
        {
            Assert.IsTrue(AnalyticsPolicy.Allowed(true, "US", null));
            Assert.IsTrue(AnalyticsPolicy.Allowed(true, "", null), "an unknown region is not restricted: UMP decides");
            Assert.IsFalse(AnalyticsPolicy.Allowed(false, "US", null), "the player's opt-out wins");
            Assert.IsFalse(AnalyticsPolicy.Allowed(false, "DE", true), "an opt-out wins over consent too");
            Assert.IsFalse(AnalyticsPolicy.Allowed(true, "DE", null), "nothing is collected in the EEA before UMP has answered");
            Assert.IsFalse(AnalyticsPolicy.Allowed(true, "GB", false), "consent declined");
            Assert.IsTrue(AnalyticsPolicy.Allowed(true, "DE", true), "consent granted");
            Assert.IsFalse(AnalyticsPolicy.Allowed(true, "US", false), "UMP can also deny outside the list");
        }

        [Test]
        public void AnalyticsIsOnByDefault_forNewPlayers()
        {
            var rig = new Rig();
            Assert.IsTrue(rig.C.State.AnalyticsOn);
            Assert.IsFalse(rig.C.State.AnalyticsChoiceMade);
            rig.Dispose();

            var fresh = new SavedGame();
            Assert.IsTrue(fresh.AnalyticsOn);
            Assert.IsFalse(fresh.AnalyticsChoiceMade);
        }

        private static Rig BootWith(SavedGame saved, string country = "US", ConsentSignals? consent = null, bool privacyOptions = false)
        {
            var rig = new Rig(1, false);
            rig.Store.Saved = saved;
            rig.Ads.Consent = consent;
            rig.Ads.PrivacyOptionsRequired = privacyOptions;
            rig.C.Init(new GameServices
            {
                Sound = rig.Sound, Store = rig.Store, Notifier = rig.Notifier, Analytics = rig.Analytics, Social = rig.Social, Ads = rig.Ads,
                Platform = new FixedCountry(country),
            }, () => rig.Now, new System.Random(1), true);
            return rig;
        }

        [Test]
        public void ASaveWithNoExplicitChoice_isOn_evenWhenOldVersionsSavedFalse()
        {
            var rig = BootWith(new SavedGame { AnalyticsOn = false, AnalyticsChoiceMade = false, OnboardingDone = true });
            Assert.IsTrue(rig.C.State.AnalyticsOn);
            Assert.AreEqual(true, rig.Analytics.Enabled);
            rig.Dispose();
        }

        [Test]
        public void AnExplicitChoice_isHonoured()
        {
            var off = BootWith(new SavedGame { AnalyticsOn = false, AnalyticsChoiceMade = true, OnboardingDone = true });
            Assert.IsFalse(off.C.State.AnalyticsOn);
            Assert.AreEqual(false, off.Analytics.Enabled);
            off.Dispose();

            var on = BootWith(new SavedGame { AnalyticsOn = true, AnalyticsChoiceMade = true, OnboardingDone = true });
            Assert.IsTrue(on.C.State.AnalyticsOn);
            on.Dispose();
        }

        [Test]
        public void InTheEea_collectionWaitsForTheConsentAnswer_andIsPassedAsConsentMode()
        {
            var rig = BootWith(new SavedGame { OnboardingDone = true }, "DE", null, true);
            Assert.AreEqual(false, rig.Analytics.Enabled, "denied until UMP answers");
            Assert.IsFalse(rig.Analytics.LastConsent.Value.AnalyticsStorage);

            rig.Ads.Consent = new ConsentSignals(true, true, false, false);
            rig.Ads.RaiseConsentChanged();
            Assert.AreEqual(true, rig.Analytics.Enabled);
            Assert.IsTrue(rig.Analytics.LastConsent.Value.AdStorage);
            Assert.IsFalse(rig.Analytics.LastConsent.Value.AdUserData);

            rig.Ads.Consent = ConsentSignals.AllDenied;
            rig.Ads.RaiseConsentChanged();
            Assert.AreEqual(false, rig.Analytics.Enabled);
            rig.Dispose();
        }

        [Test]
        public void InTheEea_theSwitchOpensTheConsentForm_insteadOfLocking()
        {
            var rig = BootWith(new SavedGame { OnboardingDone = true }, "FR", ConsentSignals.AllGranted, true);
            Assert.IsTrue(rig.C.AnalyticsUsesConsentForm);
            var us = BootWith(new SavedGame { OnboardingDone = true }, "US");
            Assert.IsFalse(us.C.AnalyticsUsesConsentForm);
            us.C.SetAnalytics(false);
            Assert.AreEqual(false, us.Analytics.Enabled);
            Assert.IsTrue(us.C.State.AnalyticsChoiceMade);
            rig.Dispose();
            us.Dispose();
        }

        private sealed class FixedCountry : IPlatform
        {
            public FixedCountry(string c) { CountryCode = c; }
            public string PlatformName => "test";
            public string CountryCode { get; }
            public string AppVersion => "test";
            public bool Share(string text) => false;
            public bool OpenUrl(string url) => false;
            public string GetClipboard() => "";
            public void SetClipboard(string text) { }
        }
    }
}
