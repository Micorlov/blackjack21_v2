using System.Linq;
using Blackjack.Game;
using Blackjack.Game.Services;
using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    /// <summary>"Delete account and data": order of operations, what is stopped first, truthful unknown outcomes, and retry.</summary>
    public class DeletionTests
    {
        private Rig _rig;

        [TearDown] public void TearDown() => _rig?.Dispose();

        private Rig Booted()
        {
            _rig = new Rig(boot: true);
            Assert.IsTrue(_rig.C.State.SocialReady, "the fake signs in at boot");
            _rig.Social.Calls.Clear();
            return _rig;
        }

        private static DeleteOutcome? Run(Rig rig)
        {
            DeleteOutcome? outcome = null;
            rig.C.DeleteAccountAndData(o => outcome = o);
            return outcome;
        }

        // ---------------------------------------------------------------- the normal path

        [Test]
        public void Guest_removesCloudRecordsThenTheAccount_andKeepsTheLocalSave()
        {
            var rig = Booted();
            var chips = rig.Round.Chips;

            Assert.AreEqual(DeleteOutcome.Deleted, Run(rig));

            CollectionAssert.AreEqual(new[] { "cloud:ABC234", "auth" }, rig.Social.Calls);
            var s = rig.C.State;
            Assert.IsFalse(s.SocialReady, "no more online writes this session");
            Assert.IsNull(s.GroupCode);
            Assert.IsNull(s.HeroUid);
            Assert.IsFalse(s.SignedIn);
            Assert.AreEqual(0, s.HeroDailyPoints);
            Assert.AreEqual(chips, rig.Round.Chips, "chips on this device are not reset");
        }

        [Test]
        public void GoogleUser_signsInAgainBeforeAnythingIsDeleted()
        {
            var rig = Booted();
            rig.Social.GoogleLinked = true;
            Assert.AreEqual(DeleteOutcome.Deleted, Run(rig));
            CollectionAssert.AreEqual(new[] { "reauth", "cloud:ABC234", "auth" }, rig.Social.Calls);
        }

        [Test]
        public void FailedReauthentication_deletesNothing_andSyncingResumes()
        {
            var rig = Booted();
            rig.Social.GoogleLinked = true;
            rig.Social.ReauthOk = false;

            Assert.AreEqual(DeleteOutcome.SignInFailed, Run(rig));

            CollectionAssert.AreEqual(new[] { "reauth" }, rig.Social.Calls);
            Assert.IsTrue(rig.C.State.SocialReady);
            var before = rig.Social.Reports.Count;
            rig.Advance(61);
            Assert.Greater(rig.Social.Reports.Count, before, "the heartbeat is running again");
        }

        [Test]
        public void NothingDeleted_keepsTheAccount_andSyncingResumes()
        {
            var rig = Booted();
            rig.Social.CloudResult = CloudDeleteResult.NothingDeleted;

            Assert.AreEqual(DeleteOutcome.CloudFailed, Run(rig));

            CollectionAssert.AreEqual(new[] { "cloud:ABC234" }, rig.Social.Calls, "the account is not deleted after a failed cloud delete");
            Assert.IsTrue(rig.C.State.SocialReady);
            Assert.AreEqual("ABC234", rig.C.State.GroupCode);
        }

        // ---------------------------------------------------------------- unknown outcomes and retry

        [Test]
        public void MaybeDeleted_isReportedAsUnknown_keepsSyncingPaused_andARetrySettlesIt()
        {
            var rig = Booted();
            rig.Social.CloudResult = CloudDeleteResult.MaybeDeleted;

            Assert.AreEqual(DeleteOutcome.Unknown, Run(rig));

            Assert.IsFalse(rig.C.State.SocialReady, "resuming could write the rows back");
            Assert.IsFalse(rig.Social.Calls.Contains("auth"));
            var reports = rig.Social.Reports.Count;
            rig.Advance(180);
            rig.C.OnAppResumed();
            Assert.AreEqual(reports, rig.Social.Reports.Count, "no heartbeat while the outcome is unknown");

            rig.Social.CloudResult = CloudDeleteResult.Done;      // the retry finds nothing left to delete and finishes
            rig.Social.Calls.Clear();
            Assert.AreEqual(DeleteOutcome.Deleted, Run(rig));
            CollectionAssert.AreEqual(new[] { "cloud:ABC234", "auth" }, rig.Social.Calls);
            Assert.IsFalse(rig.C.State.SocialReady);
        }

        [Test]
        public void SilenceBeforeAnyChange_meansNothingWasDeleted_resumesSyncing_andALateAnswerIsIgnored()
        {
            var rig = Booted();
            rig.Social.StartCommit = false;      // e.g. offline: the queued writes never drain
            rig.Social.DeferCloud = true;
            DeleteOutcome? outcome = null;
            rig.C.DeleteAccountAndData(o => outcome = o);
            Assert.IsNull(outcome, "still waiting");

            rig.Advance(26);

            Assert.AreEqual(DeleteOutcome.CloudFailed, outcome);
            Assert.IsTrue(rig.C.State.SocialReady);
            var calls = rig.Social.Calls.Count;
            rig.Social.PendingCloud(CloudDeleteResult.Done);
            Assert.AreEqual(calls, rig.Social.Calls.Count, "an abandoned attempt must not go on to delete the account");
            Assert.IsTrue(rig.C.State.SocialReady);
        }

        [Test]
        public void SilenceAfterTheFirstChange_isUnknown_keepsSyncingPaused_andALateAnswerIsIgnored()
        {
            var rig = Booted();
            rig.Social.DeferCloud = true;        // commit started, then nothing
            DeleteOutcome? outcome = null;
            rig.C.DeleteAccountAndData(o => outcome = o);

            rig.Advance(61);

            Assert.AreEqual(DeleteOutcome.Unknown, outcome, "not 'nothing was deleted': the commit may still land");
            Assert.IsFalse(rig.C.State.SocialReady);
            var calls = rig.Social.Calls.Count;
            rig.Social.PendingCloud(CloudDeleteResult.Done);
            Assert.AreEqual(calls, rig.Social.Calls.Count, "a late answer does not silently carry on");
            var reports = rig.Social.Reports.Count;
            rig.Advance(120);
            Assert.AreEqual(reports, rig.Social.Reports.Count, "no heartbeat after an unknown outcome");
        }

        [Test]
        public void AnAccountDeleteThatNeverAnswers_isUnknown_andARetryNoticesTheAccountIsGone()
        {
            var rig = Booted();
            rig.Social.DeferAuth = true;
            DeleteOutcome? outcome = null;
            rig.C.DeleteAccountAndData(o => outcome = o);
            rig.Advance(31);

            Assert.AreEqual(DeleteOutcome.Unknown, outcome);
            Assert.IsFalse(rig.C.State.SocialReady);

            // The SDK finished after all: the account no longer exists. The abandoned callback changes nothing by itself...
            rig.Social.Uid = null;
            rig.Social.PendingAuth(DeleteStep.Done);
            Assert.IsFalse(rig.C.State.SignedIn == false && rig.C.State.HeroUid == null && outcome == DeleteOutcome.Deleted);

            // ...and running the deletion again settles it without touching the server.
            rig.Social.Calls.Clear();
            Assert.AreEqual(DeleteOutcome.Deleted, Run(rig));
            Assert.IsEmpty(rig.Social.Calls);
            Assert.IsNull(rig.C.State.HeroUid);
        }

        [Test]
        public void AnAccountDeleteThatNeverAnswers_andIsStillThere_isRetriedFromTheStartAndFinishes()
        {
            var rig = Booted();
            rig.Social.DeferAuth = true;
            rig.C.DeleteAccountAndData();
            rig.Advance(31);
            rig.Social.DeferAuth = false;
            rig.Social.Calls.Clear();

            Assert.AreEqual(DeleteOutcome.Deleted, Run(rig));

            CollectionAssert.AreEqual(new[] { "cloud:ABC234", "auth" }, rig.Social.Calls, "idempotent: the cloud step is simply run again");
        }

        [Test]
        public void ARetryThatFindsNothingToDo_doesNotResumeSyncingWhileAnEarlierAttemptMayStillLand()
        {
            var rig = Booted();
            rig.Social.CloudResult = CloudDeleteResult.MaybeDeleted;
            Run(rig);
            rig.Social.CloudResult = CloudDeleteResult.NothingDeleted;       // the retry fails early

            Assert.AreEqual(DeleteOutcome.CloudFailed, Run(rig));

            Assert.IsFalse(rig.C.State.SocialReady, "the first attempt's outcome is still unknown");
        }

        // ---------------------------------------------------------------- the account step

        [Test]
        public void GuestWhoNeedsARecentLogin_endsTheSession_withoutRecreatingRows()
        {
            var rig = Booted();
            rig.Social.AuthResult = DeleteStep.RecentLoginNeeded;

            Assert.AreEqual(DeleteOutcome.RecordsDeletedAccountKept, Run(rig));

            CollectionAssert.AreEqual(new[] { "cloud:ABC234", "auth", "signout" }, rig.Social.Calls);
            Assert.IsFalse(rig.C.State.SocialReady);
            var before = rig.Social.Reports.Count;
            rig.Advance(180);
            rig.C.OnAppResumed();
            Assert.AreEqual(before, rig.Social.Reports.Count, "nothing is written back after the delete");
        }

        [Test]
        public void GoogleUserWhoseAccountDeleteFails_keepsSyncingOff_andTheSession()
        {
            var rig = Booted();
            rig.Social.GoogleLinked = true;
            rig.Social.AuthResult = DeleteStep.Failed;

            Assert.AreEqual(DeleteOutcome.RecordsDeletedAccountKept, Run(rig));

            CollectionAssert.AreEqual(new[] { "reauth", "cloud:ABC234", "auth" }, rig.Social.Calls);
            Assert.IsFalse(rig.C.State.SocialReady, "resuming would write the deleted rows back");
            Assert.IsFalse(rig.Social.Calls.Contains("signout"));
        }

        // ---------------------------------------------------------------- guards

        [Test]
        public void WhileDeleting_nothingIsWritten_andASecondRequestIsIgnored()
        {
            var rig = Booted();
            rig.Social.DeferCloud = true;
            rig.Advance(50);                       // 10 s before the 60 s heartbeat
            var before = rig.Social.Reports.Count;

            rig.C.DeleteAccountAndData();
            rig.C.DeleteAccountAndData();

            Assert.AreEqual(1, rig.Social.Calls.Count(c => c.StartsWith("cloud:")), "one deletion at a time");
            rig.Advance(25);                       // crosses the heartbeat, stays inside the watchdog
            rig.C.OnAppResumed();
            Assert.AreEqual(before, rig.Social.Reports.Count, "the heartbeat is stopped before the delete starts");
        }

        [Test]
        public void WithoutAConnection_nothingHappens()
        {
            var rig = Booted();
            rig.Social.Available = false;

            Assert.AreEqual(DeleteOutcome.Unavailable, Run(rig));

            Assert.IsEmpty(rig.Social.Calls);
            Assert.IsTrue(rig.C.State.SocialReady);
        }
    }
}
