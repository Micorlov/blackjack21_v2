using System;
using System.Linq;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class DailyBonusTests
    {
        private static readonly DateTime Claim = new DateTime(2026, 8, 1, 15, 0, 0);

        [Test]
        public void IsReady_whenNeverClaimed_andOnlyAfterTheCooldown()
        {
            Assert.IsTrue(DailyBonus.IsReady(null, Claim));
            Assert.IsFalse(DailyBonus.IsReady(Claim, Claim.AddSeconds(1)));
            Assert.IsFalse(DailyBonus.IsReady(Claim, Claim + DailyBonus.Cooldown - TimeSpan.FromMinutes(1)));
            Assert.IsTrue(DailyBonus.IsReady(Claim, Claim + DailyBonus.Cooldown));
            Assert.IsTrue(DailyBonus.IsReady(Claim, Claim.AddDays(3)));
        }

        [Test]
        public void NextAt_isOneCooldownAfterTheClaim()
        {
            Assert.IsNull(DailyBonus.NextAt(null));
            Assert.AreEqual(Claim + DailyBonus.Cooldown, DailyBonus.NextAt(Claim));
        }

        [Test]
        public void CountdownLabel_roundsUpAndEmptiesWhenReady()
        {
            Assert.AreEqual("23h 59m", DailyBonus.CountdownLabel(Claim, Claim.AddMinutes(1)));
            Assert.AreEqual("41m", DailyBonus.CountdownLabel(Claim, Claim + DailyBonus.Cooldown - TimeSpan.FromMinutes(41)));
            Assert.AreEqual("1m", DailyBonus.CountdownLabel(Claim, Claim + DailyBonus.Cooldown - TimeSpan.FromSeconds(30)));
            Assert.AreEqual("", DailyBonus.CountdownLabel(Claim, Claim + DailyBonus.Cooldown));
        }

        [Test]
        public void NextStreakDay_advancesInsideTheWindowAndResetsOutsideIt()
        {
            Assert.AreEqual(1, DailyBonus.NextStreakDay(0, null, Claim));
            Assert.AreEqual(1, DailyBonus.NextStreakDay(3, null, Claim));
            Assert.AreEqual(3, DailyBonus.NextStreakDay(2, Claim, Claim.AddHours(25)));
            Assert.AreEqual(3, DailyBonus.NextStreakDay(2, Claim, Claim + DailyBonus.StreakWindow), "edge is inclusive");
            Assert.AreEqual(1, DailyBonus.NextStreakDay(2, Claim, Claim + DailyBonus.StreakWindow + TimeSpan.FromSeconds(1)));
            Assert.AreEqual(1, DailyBonus.NextStreakDay(7, Claim, Claim.AddHours(25)), "day 7 wraps");
        }

        [Test]
        public void RewardForDay_paysTheBigPrizeOnDaySeven()
        {
            Assert.AreEqual(250, DailyBonus.RewardForDay(1));
            Assert.AreEqual(250, DailyBonus.RewardForDay(6));
            Assert.AreEqual(1000, DailyBonus.RewardForDay(7));
        }
    }

    public class RebuyTests
    {
        [Test]
        public void IsReady_onlyAfterFourHours()
        {
            var last = new DateTime(2026, 8, 1, 12, 0, 0);
            Assert.IsTrue(Rebuy.IsReady(null, last));
            Assert.IsFalse(Rebuy.IsReady(last, last.AddHours(3)));
            Assert.IsTrue(Rebuy.IsReady(last, last.AddHours(4)));
            Assert.AreEqual("3h 30m", Rebuy.CountdownLabel(last, last.AddMinutes(30)));
        }
    }

    public class PlayStreakTests
    {
        private static readonly DateTime Now = new DateTime(2026, 8, 10, 14, 30, 0);

        [Test]
        public void Advance_extendsOnConsecutiveDaysAndRestartsAfterAGap()
        {
            Assert.AreEqual((4, "2026-08-10"), PlayStreak.Advance(3, "2026-08-09", Now));
            Assert.AreEqual((3, "2026-08-10"), PlayStreak.Advance(3, "2026-08-10", Now), "same day, no change");
            Assert.AreEqual((1, "2026-08-10"), PlayStreak.Advance(3, "2026-08-07", Now));
            Assert.AreEqual((1, "2026-08-10"), PlayStreak.Advance(0, "", Now));
        }

        [Test]
        public void Advance_crossesMonthBoundaries()
        {
            Assert.AreEqual((2, "2026-09-01"), PlayStreak.Advance(1, "2026-08-31", new DateTime(2026, 9, 1, 9, 0, 0)));
        }

        [Test]
        public void Live_lapsesWhenNeitherTodayNorYesterdayWasPlayed()
        {
            Assert.AreEqual(3, PlayStreak.Live(3, "2026-08-10", Now));
            Assert.AreEqual(3, PlayStreak.Live(3, "2026-08-09", Now));
            Assert.AreEqual(0, PlayStreak.Live(3, "2026-08-08", Now));
        }

        [Test]
        public void BonusChips_is50PerDayCappedAtFiveDays()
        {
            Assert.AreEqual(0, PlayStreak.BonusChips(0));
            Assert.AreEqual(150, PlayStreak.BonusChips(3));
            Assert.AreEqual(250, PlayStreak.BonusChips(5));
            Assert.AreEqual(250, PlayStreak.BonusChips(12));
        }

        [Test]
        public void ReminderAt_isTonightIfUnplayedElseTomorrowNight()
        {
            Assert.IsNull(PlayStreak.ReminderAt(0, false, Now));
            Assert.AreEqual(new DateTime(2026, 8, 10, 20, 0, 0), PlayStreak.ReminderAt(2, false, Now));
            Assert.AreEqual(new DateTime(2026, 8, 11, 20, 0, 0), PlayStreak.ReminderAt(2, true, Now));
            Assert.IsNull(PlayStreak.ReminderAt(2, false, new DateTime(2026, 8, 10, 21, 0, 0)), "too late tonight");
        }
    }

    public class PointsTests
    {
        [Test]
        public void Keys_arePaddedAndSortable()
        {
            var t = new DateTime(2026, 3, 5, 7, 9, 0);
            Assert.AreEqual("2026-03-05", Points.DayKeyOf(t));
            Assert.AreEqual("2026-03-05T07", Points.HourKeyOf(t));
        }

        [Test]
        public void Rolled_resetsWhenTheBucketChanged()
        {
            Assert.AreEqual(120, Points.Rolled(120, "2026-03-05T07", "2026-03-05T07"));
            Assert.AreEqual(0, Points.Rolled(120, "2026-03-05T07", "2026-03-05T08"));
        }

        [Test]
        public void RankOf_countsPlayersStrictlyAhead_andPutsAnAbsentHeroLast()
        {
            var players = new[] { new RankedPlayer("a", "A", 50), new RankedPlayer("me", "Me", 30), new RankedPlayer("b", "B", 30) };
            Assert.AreEqual(2, Ranking.RankOf("me", players), "ties do not count as ahead");
            Assert.AreEqual(4, Ranking.RankOf("ghost", players));
        }

        [Test]
        public void Overtakers_listsOnlyThoseWhoJustPassedTheHero()
        {
            var before = new[] { new RankedPlayer("me", "Me", 100), new RankedPlayer("a", "A", 90), new RankedPlayer("b", "B", 120) };
            var after = new[] { new RankedPlayer("me", "Me", 100), new RankedPlayer("a", "A", 130), new RankedPlayer("b", "B", 140) };
            var passed = Ranking.Overtakers(before, after, "me");
            CollectionAssert.AreEqual(new[] { "a" }, passed.Select(p => p.Id).ToArray(), "b was already ahead");
        }

        [Test]
        public void Overtakers_alertsForAStrongNewcomer()
        {
            var before = new[] { new RankedPlayer("me", "Me", 100) };
            var after = new[] { new RankedPlayer("me", "Me", 100), new RankedPlayer("new", "New", 500) };
            Assert.AreEqual(1, Ranking.Overtakers(before, after, "me").Count);
        }
    }

    public class ReferralTests
    {
        private static Friend F(string id, string by) => new Friend(id, id, 0, true, 0, 0, InvitedBy: by);

        [Test]
        public void Unrewarded_skipsEveryoneAlreadyPaid()
        {
            var group = new[] { F("a", "me"), F("b", "me"), F("c", "other") };
            Assert.AreEqual(2, Referrals.Count(group, "me"));
            var unpaid = Referrals.Unrewarded(group, "me", new[] { "a" });
            CollectionAssert.AreEqual(new[] { "b" }, unpaid.Select(f => f.Id).ToArray());
        }
    }

    public class RosterTests
    {
        [Test]
        public void TableSeats_padsASmallGroupWithPracticeBots()
        {
            var real = new[] { new Friend("u1", "Real One", 0, true, 0, 0) };
            var seats = Roster.TableSeats(real, "bronze");
            Assert.AreEqual(4, seats.Count);
            Assert.AreEqual("u1", seats[0].Id);
        }

        [Test]
        public void TableSeats_seatsFriendsAlreadyAtThisTableFirst()
        {
            var friends = Enumerable.Range(1, 6).Select(i =>
                new Friend("u" + i, "F" + i, 0, true, 0, 0, TableKey: i == 5 ? "bronze" : null)).ToArray();
            var seats = Roster.TableSeats(friends, "bronze");
            Assert.AreEqual("u5", seats[0].Id);
            Assert.AreEqual(4, seats.Count);
        }

        [Test]
        public void PresenceLabels_scaleWithTheCrowd()
        {
            Friend P(string n) => new Friend(n, n + " X", 0, true, 0, 0);
            Assert.AreEqual("", Roster.PresenceLabel(new Friend[0]));
            Assert.AreEqual("Maya is here", Roster.PresenceLabel(new[] { P("Maya") }));
            Assert.AreEqual("Maya & Sam are here", Roster.PresenceLabel(new[] { P("Maya"), P("Sam") }));
            Assert.AreEqual("Maya, Sam +1 here", Roster.PresenceLabel(new[] { P("Maya"), P("Sam"), P("Jo") }));
            Assert.AreEqual("Join Maya", Roster.PresenceCta(new[] { P("Maya") }));
            Assert.AreEqual("Join 2 friends", Roster.PresenceCta(new[] { P("Maya"), P("Sam") }));
        }
    }

    public class MiscProgressionTests
    {
        [Test]
        public void TableRecommendation_picksTheHighestTableTheStackCoversFourTimes()
        {
            Assert.AreEqual("bronze", TableRecommendation.For(50).Key);
            Assert.AreEqual("silver", TableRecommendation.For(400).Key);
            Assert.AreEqual("vip", TableRecommendation.For(2000).Key);
        }

        [Test]
        public void ReviewPrompt_waitsForTenHandsAndHonoursCooldowns()
        {
            var now = new DateTime(2026, 8, 1, 12, 0, 0);
            Assert.IsFalse(ReviewPrompt.ShouldPrompt(9, now, 0, 0, false));
            Assert.IsTrue(ReviewPrompt.ShouldPrompt(10, now, 0, 0, false));
            Assert.IsFalse(ReviewPrompt.ShouldPrompt(50, now, 0, 3, false), "request cap");

            var attempted = new DateTimeOffset(now.AddDays(-3)).ToUnixTimeMilliseconds();
            Assert.IsFalse(ReviewPrompt.ShouldPrompt(50, now, attempted, 1, false), "7-day failure cooldown");
            var old = new DateTimeOffset(now.AddDays(-8)).ToUnixTimeMilliseconds();
            Assert.IsTrue(ReviewPrompt.ShouldPrompt(50, now, old, 1, false));
            Assert.IsFalse(ReviewPrompt.ShouldPrompt(50, now, old, 1, true), "90-day success cooldown");
        }

        [Test]
        public void FlagForId_isStable()
        {
            Assert.AreEqual(Flags.ForId("abc"), Flags.ForId("abc"));
            Assert.AreEqual("🇺🇸", Flags.ForId(""));
        }

        [Test]
        public void PlayTimeTracker_countsWholeSecondsAndCarriesTheRemainder()
        {
            var t = TimeSpan.Zero;
            var tracker = new PlayTimeTracker(() => t);
            t = TimeSpan.FromSeconds(2.5);
            Assert.AreEqual(2, tracker.TakeSeconds());
            t = TimeSpan.FromSeconds(3.2);
            Assert.AreEqual(1, tracker.TakeSeconds(), "0.5 carried + 0.7 more");
            t = TimeSpan.FromSeconds(3.6);
            Assert.AreEqual(0, tracker.TakeSeconds(), "0.2 carried + 0.4 more is still under a second");
        }

        [Test]
        public void PlayTimeTracker_doesNotCountWhilePaused()
        {
            var t = TimeSpan.Zero;
            var tracker = new PlayTimeTracker(() => t);
            t = TimeSpan.FromSeconds(3);
            tracker.Pause();
            t = TimeSpan.FromSeconds(100);
            Assert.AreEqual(3, tracker.TakeSeconds());
            tracker.Resume();
            t = TimeSpan.FromSeconds(102);
            Assert.AreEqual(2, tracker.TakeSeconds());
        }
    }

    public class InviteLinkTests
    {
        [TestCase("/join/abc234", "ABC234")]
        [TestCase("/join/ABC234?utm=whatsapp", "ABC234")]
        [TestCase("/?code=ABC234", "ABC234")]
        [TestCase("https://blackjack21-v2.web.app/#/join/ABC234", "ABC234")]
        [TestCase("https://blackjack21-v2.web.app/join/ABC234", "ABC234")]
        [TestCase("https://evil.example/join/ABC234", null)]
        [TestCase("/join/ABC23", null)]
        [TestCase("/join/ABC1O0", null)]
        [TestCase("/", null)]
        [TestCase("", null)]
        public void CodeFromRoute(string route, string expected) =>
            Assert.AreEqual(expected, InviteLink.CodeFromRoute(route));

        [Test]
        public void UriFor_buildsTheSharedLink() =>
            Assert.AreEqual("https://blackjack21-v2.web.app/join/ABC234", InviteLink.UriFor("ABC234"));

        [Test]
        public void IsValidCode_rejectsWrongLengthAndLookalikes()
        {
            Assert.IsTrue(InviteLink.IsValidCode("ABC234"));
            Assert.IsFalse(InviteLink.IsValidCode("ABC23"));
            Assert.IsFalse(InviteLink.IsValidCode("ABC10L"));
        }

        [Test]
        public void CodeFromText_findsALinkInsideTextOrABareCode()
        {
            Assert.AreEqual("ABC234", InviteLink.CodeFromText("Join me! https://blackjack21-v2.web.app/join/abc234 see you"));
            Assert.AreEqual("ABC234", InviteLink.CodeFromText("  abc234 "));
            Assert.IsNull(InviteLink.CodeFromText("hello there"));
            Assert.IsNull(InviteLink.CodeFromText(""));
        }
    }
}
