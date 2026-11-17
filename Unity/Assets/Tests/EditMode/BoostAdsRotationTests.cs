using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Blackjack.Game;
using Blackjack.Game.Services;
using NUnit.Framework;
using UnityEngine;

namespace Blackjack.Core.Tests
{
    /// <summary>Comeback Boost as a disclosed, switchable setting.</summary>
    public sealed class ComebackBoostTests
    {
        private static readonly RoundResult[] TwoLosses = { RoundResult.Win, RoundResult.Loss, RoundResult.Loss };
        private Rig _rig;

        [TearDown] public void TearDown() { _rig?.Dispose(); _rig = null; }

        [Test]
        public void On_boostStillAppliesToAShortStackAndToTwoLosses()
        {
            Assert.AreEqual(3, Comeback.TriesFor(100, T.Bronze, Array.Empty<RoundResult>(), true));
            Assert.AreEqual(3, Comeback.TriesFor(5000, T.Bronze, TwoLosses, true));
            Assert.AreEqual(1, Comeback.TriesFor(5000, T.Bronze, Array.Empty<RoundResult>(), true), "healthy stack, no streak");
        }

        [Test]
        public void Off_isAStraightDeal_evenShortStackedOnALosingStreak()
        {
            Assert.AreEqual(1, Comeback.TriesFor(100, T.Bronze, TwoLosses, false));
            Assert.AreEqual(1, Comeback.TriesFor(5000, T.Bronze, TwoLosses, false));
            Assert.AreEqual(1, Comeback.TriesFor(100, T.Bronze, Array.Empty<RoundResult>(), false));
        }

        [Test]
        public void Deal_takesTheTopPairWhenOff_andTheBestOfThreeWhenOn()
        {
            // Four seats (8 cards), then three hero pairs 5-6, K-A, 2-3 on top of the shoe, then the dealer's cards.
            string[] order = { "2", "3", "2", "3", "2", "3", "2", "3", "5", "6", "K", "A", "2", "3", "9", "8", "7", "7" };
            RoundState Start(bool on) => new RoundState
            {
                Chips = 100, Stake = T.Bronze, Bet = 25, ComebackOn = on,
                NpcSeats = RoundEngine.RollNpcSeats(25, new System.Random(1)),
            };
            var off = RoundEngine.Deal(Start(false), T.Stacked(order), T.Names);
            CollectionAssert.AreEqual(T.Cards("5", "6"), off.Hands[0].Cards);
            var on = RoundEngine.Deal(Start(true), T.Stacked(order), T.Names);
            Assert.AreEqual(21, BlackjackRules.HandValue(on.Hands[0].Cards));
        }

        [Test]
        public void DefaultIsOn_forANewPlayerAndForAnOldSaveWithoutTheKey()
        {
            Assert.IsTrue(new RoundState().ComebackOn);
            Assert.IsTrue(new SavedGame().ComebackOn);
            _rig = new Rig();
            Assert.IsTrue(_rig.Round.ComebackOn);
            var legacy = SavedGameJson.FromJson("{\"v\":1,\"chips\":900}");
            Assert.IsTrue(legacy.ComebackOn, "players who never touched it stay on");
        }

        [Test]
        public void TheChoicePersists_throughASaveAndARelaunch()
        {
            _rig = new Rig();
            _rig.C.ToggleComeback();
            Assert.IsFalse(_rig.Round.ComebackOn);
            _rig.C.FlushSave();
            Assert.IsFalse(_rig.Store.Saved.ComebackOn);
            var back = SavedGameJson.FromJson(SavedGameJson.ToJson(_rig.Store.Saved));
            Assert.IsFalse(back.ComebackOn);

            var go = new GameObject("Relaunch");
            var c = go.AddComponent<GameController>();
            c.Init(new GameServices { Store = _rig.Store }, () => _rig.Now, new System.Random(1));
            Assert.IsFalse(c.State.Round.ComebackOn);
            c.ToggleComeback();
            Assert.IsTrue(c.State.Round.ComebackOn);
            UnityEngine.Object.DestroyImmediate(go);
        }

        [Test]
        public void TheSettingSurvivesTheNextHand()
        {
            _rig = new Rig();
            _rig.C.ToggleComeback();
            _rig.C.NextHand();
            Assert.IsFalse(_rig.Round.ComebackOn);
        }
    }

    /// <summary>Interstitial pacing, the rewarded offer and its caps. Numbers are asserted so a silent change fails a test.</summary>
    public sealed class AdPolicyTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() { _rig?.Dispose(); _rig = null; }

        [Test]
        public void Constants_areTheShippedNumbers()
        {
            Assert.AreEqual(3, AdPacing.HandsBetween);
            Assert.AreEqual(TimeSpan.FromSeconds(90), AdPacing.MinGap);
            Assert.AreEqual(1.0, GameController.BreakAdDelaySeconds, "the delay that keeps a Next Hand tap from becoming an ad tap");
            Assert.AreEqual(500, AdReward.Chips);
            Assert.AreEqual(TimeSpan.FromMinutes(30), AdReward.Cooldown);
            Assert.AreEqual(5, AdReward.DailyCap);
        }

        [Test]
        public void Interstitial_needsBothTheHandsAndTheGap()
        {
            var t0 = new DateTime(2026, 8, 10, 14, 0, 0);
            Assert.IsFalse(AdPacing.IsDue(AdPacing.HandsBetween, t0, t0.AddSeconds(89), true));
            Assert.IsFalse(AdPacing.IsDue(AdPacing.HandsBetween - 1, t0, t0.AddMinutes(10), true));
            Assert.IsTrue(AdPacing.IsDue(AdPacing.HandsBetween, t0, t0.AddSeconds(90), true));
        }

        [Test]
        public void Interstitial_neverComesMidHand()
        {
            _rig = new Rig();
            _rig.Ads.InterstitialReady = true;
            _rig.C.Set(s => s with { TutorialDismissed = true });
            _rig.C.EnterTable(T.Bronze);
            _rig.Advance(2);
            _rig.C.PlaceBet(25);
            _rig.C.DealRound();
            // A whole hand is dealt and played out (the turn timer stands for the hero); the ad can only be asked for by Next Hand.
            _rig.Advance(60);
            Assert.AreEqual(0, _rig.Ads.InterstitialsShown, "no ad while a hand is being dealt or played");
            Assert.IsFalse(_rig.C.State.AdBreakActive);
        }

        [Test]
        public void Rewarded_stopsAtTheDailyCap_andResetsTheNextDay()
        {
            _rig = new Rig();
            _rig.Ads.RewardedReady = true;
            _rig.C.Set(s => s with { Round = s.Round with { Chips = 10 } });
            for (var i = 0; i < AdReward.DailyCap; i++)
            {
                _rig.C.WatchAdForChips();
                _rig.Now += AdReward.Cooldown;
            }
            var paid = 10 + AdReward.DailyCap * AdReward.Chips;
            Assert.AreEqual(paid, _rig.Round.Chips);
            Assert.IsFalse(_rig.C.RewardedOfferAvailable, "cooled down but the cap is reached");
            _rig.C.WatchAdForChips();
            Assert.AreEqual(paid, _rig.Round.Chips, "a sixth video today pays nothing");

            _rig.Now = new DateTime(2026, 8, 11, 9, 0, 0);
            Assert.IsTrue(_rig.C.RewardedOfferAvailable);
            _rig.C.WatchAdForChips();
            Assert.AreEqual(paid + AdReward.Chips, _rig.Round.Chips);
        }

        [Test]
        public void Rewarded_countSurvivesASave()
        {
            _rig = new Rig();
            _rig.Ads.RewardedReady = true;
            _rig.C.WatchAdForChips();
            _rig.C.FlushSave();
            Assert.AreEqual(1, _rig.Store.Saved.AdRewardsToday);
            Assert.AreEqual(Points.DayKeyOf(_rig.Now), _rig.Store.Saved.AdRewardsDayKey);
        }

        [Test]
        public void LowChipsOffer_firesOncePerDip_onlyWhenAVideoIsAvailable()
        {
            _rig = new Rig();
            _rig.C.Set(s => s with { Round = s.Round with { Stake = T.Bronze, Chips = 20 } });
            var offers = 0;
            _rig.C.LowChipsOffer += () => offers++;

            _rig.C.NextHand();
            Assert.AreEqual(0, offers, "no video loaded, nothing to offer");

            _rig.Ads.RewardedReady = true;
            _rig.C.NextHand();
            Assert.AreEqual(1, offers);
            _rig.C.NextHand();
            Assert.AreEqual(1, offers, "not again until the stack has recovered");

            _rig.C.Set(s => s with { Round = s.Round with { Chips = 5000 } });
            _rig.C.NextHand();
            _rig.C.Set(s => s with { Round = s.Round with { Chips = 20 } });
            _rig.C.NextHand();
            Assert.AreEqual(2, offers);
        }

        [Test]
        public void LowChipsOffer_isNotStackedOnABetweenHandsAd()
        {
            _rig = new Rig();
            _rig.Ads.RewardedReady = true;
            _rig.Ads.InterstitialReady = true;
            _rig.C.Set(s => s with { TutorialDismissed = true, Round = s.Round with { Stake = T.Bronze, Chips = 20 } });
            var offers = 0;
            _rig.C.LowChipsOffer += () => offers++;
            for (var i = 1; i < AdPacing.HandsBetween; i++) { _rig.C.NextHand(); _rig.Advance(1.2); }
            var before = offers;
            _rig.C.NextHand(); // the ad is due on this one
            Assert.IsTrue(_rig.C.State.AdBreakActive);
            Assert.AreEqual(before, offers, "an interstitial and a rewarded offer never land together");
        }

        [Test]
        public void NoSdkOrNoConsent_justMeansNoAds_andNothingThrows()
        {
            _rig = new Rig(); // NullAds: nothing loaded, consent unknown
            Assert.IsFalse(_rig.C.RewardedOfferAvailable);
            Assert.DoesNotThrow(() => _rig.C.WatchAdForChips());
            Assert.DoesNotThrow(() => { for (var i = 0; i < 6; i++) _rig.C.NextHand(); });
            Assert.AreEqual(0, _rig.Ads.InterstitialsShown);
            Assert.IsFalse(_rig.C.State.AdBreakActive);
            Assert.IsNull(_rig.C.State.LastAdRewardAt);
        }
    }

    /// <summary>The rotating 8 PM text, one per day, and that every variant exists in all ten languages.</summary>
    public sealed class EveningGiftCopyTests
    {
        private static readonly string[] Langs = { "en", "de", "es", "fr", "pt", "ru", "zh", "ja", "ar", "he" };

        private static Dictionary<string, string> Table(string code)
        {
            var path = Path.Combine(Application.dataPath, "Resources", "Locales", code + ".json");
            var map = new Dictionary<string, string>();
            foreach (var line in File.ReadAllLines(path))
            {
                var m = Regex.Match(line, "^\"([^\"]+)\": \"(.*)\",?$");
                if (m.Success) map[m.Groups[1].Value] = m.Groups[2].Value;
            }
            return map;
        }

        [Test]
        public void OneReminderPerDay_atEightPm_eachWithItsOwnDate()
        {
            var first = new DateTime(2026, 8, 10, 20, 0, 0);
            var up = EveningGift.Upcoming(first);
            Assert.AreEqual(EveningGift.DaysAhead, up.Count);
            Assert.AreEqual(up.Count, up.Select(u => u.At.Date).Distinct().Count(), "never two on one date");
            Assert.IsTrue(up.All(u => u.At.Hour == EveningGift.Hour && u.At.Minute == 0));
            Assert.AreEqual(first, up[0].At);
        }

        [Test]
        public void TheCopyRotatesAcrossDays_andIsStableWithinADay()
        {
            var day = new DateTime(2026, 8, 10);
            var seen = new HashSet<int>();
            for (var i = 0; i < EveningGift.Variants; i++)
            {
                var v = EveningGift.VariantFor(day.AddDays(i));
                Assert.That(v, Is.InRange(1, EveningGift.Variants));
                Assert.AreNotEqual(v, EveningGift.VariantFor(day.AddDays(i + 1)), "tomorrow's text differs from today's");
                Assert.AreEqual(v, EveningGift.VariantFor(day.AddDays(i).AddHours(20)), "same date, same text");
                seen.Add(v);
            }
            Assert.AreEqual(EveningGift.Variants, seen.Count, "every variant gets its turn");
            Assert.AreEqual(5, EveningGift.Variants);
            Assert.That(EveningGift.VariantFor(new DateTime(2025, 1, 1)), Is.InRange(1, 5), "dates before the epoch still map");
        }

        [Test]
        public void EveryVariantIsTranslated_andNeverImpliesRealMoney()
        {
            var en = Table("en");
            var banned = new[] { "cash out", "withdraw", "real casino", "win money", "jackpot" };
            for (var n = 1; n <= EveningGift.Variants; n++)
                foreach (var kind in new[] { "eveningTitle", "eveningBody" })
                {
                    var key = kind + n;
                    Assert.IsTrue(en.ContainsKey(key), key);
                    foreach (var b in banned) StringAssert.DoesNotContain(b, en[key].ToLowerInvariant());
                    foreach (var code in Langs.Where(c => c != "en"))
                    {
                        var t = Table(code);
                        Assert.IsTrue(t.ContainsKey(key), code + " " + key);
                        Assert.AreNotEqual(en[key], t[key], code + " " + key + " is still English");
                    }
                }
        }

        [Test]
        public void ComebackAndRewardedCopy_isInEveryLanguage_withoutEnglishLeftovers()
        {
            var en = Table("en");
            var keys = new[]
            {
                "comebackLabel", "comebackSublabel", "guideComebackBody", "rewardOfferTitle", "rewardOfferBody", "rewardWatchAction",
                "rewardNoThanks", "rewardCardTitle", "rewardCardReady", "rewardCardTomorrow", "notifDailySublabel", "settingsSectionPrivacy",
                "analyticsLabel", "analyticsSublabel", "analyticsSublabelForm", "privacyChoicesLabel", "deleteAccountLabel", "deleteAccountBody",
            };
            foreach (var code in Langs.Where(c => c != "en"))
            {
                var t = Table(code);
                foreach (var k in keys)
                {
                    Assert.IsTrue(t.ContainsKey(k), code + " lacks " + k);
                    Assert.AreNotEqual(en[k], t[k], code + " " + k + " is still English");
                }
            }
        }

        [Test]
        public void EveryLanguageHasEveryEnglishKey()
        {
            var en = Table("en");
            foreach (var code in Langs.Where(c => c != "en"))
            {
                var t = Table(code);
                var missing = en.Keys.Where(k => !t.ContainsKey(k)).ToArray();
                Assert.IsEmpty(missing, code + " is missing: " + string.Join(", ", missing));
            }
        }
    }
}
