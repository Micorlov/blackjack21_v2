using System;
using Blackjack.Game;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    /// <summary>The 8 PM evening gift: scheduling, the date-keyed +500 on a tap, the Settings switch and the permission timing.</summary>
    public sealed class EveningGiftTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        [Test]
        public void Boot_schedulesTonightAt8pm_withoutAskingForPermission()
        {
            var rig = _rig = new Rig(boot: true);
            Assert.AreEqual(new DateTime(2026, 8, 10, 20, 0, 0), rig.Notifier.GiftAt);
            Assert.AreEqual(0, rig.Notifier.PermissionRequests, "the system dialog never appears on a cold start");
        }

        [Test]
        public void Boot_withoutPermission_stillDoesNotAsk()
        {
            var rig = _rig = new Rig(boot: false);
            rig.Notifier.HasPermission = false;
            rig.C.OnAppResumed();
            Assert.AreEqual(0, rig.Notifier.PermissionRequests);
        }

        [Test]
        public void Resume_afterTheEveningOrATimeZoneMove_reschedulesTheNext8pm()
        {
            var rig = _rig = new Rig(boot: true);
            rig.Now = new DateTime(2026, 8, 10, 21, 15, 0);
            rig.C.OnAppResumed();
            Assert.AreEqual(new DateTime(2026, 8, 11, 20, 0, 0), rig.Notifier.GiftAt, "past 8 PM, so tomorrow");
            rig.Now = new DateTime(2026, 8, 11, 3, 0, 0); // the clock moved west/east: the device now reads 03:00
            rig.C.OnAppResumed();
            Assert.AreEqual(new DateTime(2026, 8, 11, 20, 0, 0), rig.Notifier.GiftAt);
        }

        [Test]
        public void Tap_creditsFiveHundredOncePerDay_andAgainTheNextDay()
        {
            var rig = _rig = new Rig(boot: true);
            var chips = rig.Round.Chips;

            rig.Notifier.GiftTapped = true;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            Assert.AreEqual(chips + 500, rig.Round.Chips, "first tap credits");
            StringAssert.Contains("$500", rig.C.State.Toast);
            StringAssert.Contains("play chips", rig.C.State.Toast, "the toast says these are play chips");

            rig.Notifier.GiftTapped = true;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            Assert.AreEqual(chips + 500, rig.Round.Chips, "a second tap the same day is a no-op");
            Assert.IsFalse(rig.C.ClaimEveningGift());

            rig.Now = rig.Now.AddDays(1);
            rig.Notifier.GiftTapped = true;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            Assert.AreEqual(chips + 1000, rig.Round.Chips, "a new date pays again");
            Assert.AreEqual(Points.DayKeyOf(rig.Now), rig.C.State.EveningGiftKey);
        }

        [Test]
        public void Resume_withoutATap_paysNothing()
        {
            var rig = _rig = new Rig(boot: true);
            var chips = rig.Round.Chips;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            Assert.AreEqual(chips, rig.Round.Chips);
        }

        [Test]
        public void Tap_doesNotTouchTheDailyBonusLadder()
        {
            var rig = _rig = new Rig(boot: true);
            rig.Notifier.GiftTapped = true;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            Assert.IsNull(rig.C.State.LastDailyBonusClaimAt, "the ladder is not auto-claimed");
            Assert.AreEqual(0, rig.C.State.DailyBonusStreakDay);

            var chips = rig.Round.Chips;
            rig.C.ClaimDailyBonus();
            Assert.AreEqual(chips + 250, rig.Round.Chips, "the ladder still pays its own day-1 reward");
        }

        [Test]
        public void DailyReminderSwitch_cancelsAndReschedules()
        {
            var rig = _rig = new Rig(boot: true);
            Assert.IsNotNull(rig.Notifier.GiftAt);
            rig.C.ToggleNotifDaily();
            Assert.IsFalse(rig.C.State.NotifDaily);
            Assert.IsNull(rig.Notifier.GiftAt, "off cancels the pending 8 PM");
            rig.C.OnAppResumed();
            Assert.IsNull(rig.Notifier.GiftAt, "and it stays off across a resume");
            rig.C.ToggleNotifDaily();
            Assert.AreEqual(new DateTime(2026, 8, 10, 20, 0, 0), rig.Notifier.GiftAt, "on re-arms it");
        }

        [Test]
        public void EveningGiftKey_survivesASaveAndLoad()
        {
            var rig = _rig = new Rig(boot: true);
            rig.Notifier.GiftTapped = true;
            rig.C.OnAppResumed();
            rig.Advance(1.5);
            rig.C.FlushSave();
            var back = Blackjack.Game.Services.SavedGameJson.FromJson(Blackjack.Game.Services.SavedGameJson.ToJson(rig.Store.Saved));
            Assert.AreEqual("2026-08-10", back.EveningGiftKey);
            Assert.Greater(back.FirstSeenAtMs, 0);
        }
    }
}
