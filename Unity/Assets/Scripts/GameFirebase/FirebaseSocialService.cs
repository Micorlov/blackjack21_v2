using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game.Services;
using Firebase;
using Firebase.Auth;
using Firebase.Extensions;
using Firebase.Firestore;
using UnityEngine;

namespace Blackjack.Game.Firebase
{
    /// <summary>
    /// The live friends group over Firebase Auth and Firestore — the same collections, fields and rules as the Flutter
    /// app (<c>players</c>, <c>groups/{code}/players</c>, <c>leaderboard</c>, <c>config/features</c>), so both
    /// builds can share a group. Every callback runs on the main thread.
    /// </summary>
    public sealed class FirebaseSocialService : ISocialService
    {
        private static readonly TimeSpan OnlineWindow = TimeSpan.FromMinutes(5);
        private const int CodeAttempts = 5;

        private FirebaseAuth _auth;
        private FirebaseFirestore _db;
        private bool _ready;
        private bool _initialising;
        private readonly List<Action<bool>> _waiting = new List<Action<bool>>();

        public bool Available => _ready;
        public string Uid => _ready ? _auth.CurrentUser?.UserId : null;

        // ---- startup ----------------------------------------------------------------------------------

        /// <summary>Brings Firebase up once (Play services check included) and calls back with whether it is usable.</summary>
        private void WhenReady(Action<bool> done)
        {
            if (_ready) { done(true); return; }
            _waiting.Add(done);
            if (_initialising) return;
            _initialising = true;
            FirebaseApp.CheckAndFixDependenciesAsync().ContinueWithOnMainThread(task =>
            {
                var ok = task.IsCompletedSuccessfully && task.Result == DependencyStatus.Available;
#if BJ_FIREBASE_EMULATOR
                // QA builds only (BuildTools.BuildAndroidEmulatorQA): synthetic users on this Mac's emulators. If the switch does
                // not take, stay offline rather than touch the live project.
                if (ok) ok = UseLocalEmulators();
#endif
                if (ok)
                {
                    _auth = FirebaseAuth.DefaultInstance;
                    _db = FirebaseFirestore.DefaultInstance;
                    _ready = true;
                }
                else Debug.LogWarning("Firebase unavailable: " + (task.Exception?.Message ?? task.Result.ToString()));
                _initialising = false;
                var callbacks = _waiting.ToArray();
                _waiting.Clear();
                foreach (var cb in callbacks) cb(ok);
            });
        }

#if BJ_FIREBASE_EMULATOR
        // The Android emulator reaches this Mac at 10.0.2.2. A physical phone (BJ_QA_PHYSICAL) must never use that address: it
        // reaches the Mac's emulators through `adb reverse`, i.e. its own localhost.
#if BJ_QA_PHYSICAL
        private const string QaHost = "127.0.0.1";
#else
        private const string QaHost = "10.0.2.2";
#endif
        private static bool UseLocalEmulators()
        {
            try
            {
                using (var auth = new AndroidJavaClass("com.google.firebase.auth.FirebaseAuth"))
                using (var instance = auth.CallStatic<AndroidJavaObject>("getInstance"))
                    instance.Call("useEmulator", QaHost, 9095);
                var settings = FirebaseFirestore.DefaultInstance.Settings;
                settings.Host = QaHost + ":8095";
                settings.SslEnabled = false;
                settings.PersistenceEnabled = false;
                Debug.Log("BJ_EMULATOR: Auth " + QaHost + ":9095, Firestore " + QaHost + ":8095");
                return true;
            }
            catch (Exception e)
            {
                Debug.LogWarning("BJ_EMULATOR: could not switch to the emulators, staying offline: " + e.Message);
                return false;
            }
        }
#endif

        public void EnsureSignedIn(Action<bool> done) => WhenReady(ok =>
        {
            if (!ok) { done(false); return; }
            if (_auth.CurrentUser != null) { FirebaseRegistration.ReportInstallOnce(); done(true); return; }
            _auth.SignInAnonymouslyAsync().ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully) Debug.LogWarning("Anonymous sign-in failed: " + task.Exception?.Message);
                var signedIn = task.IsCompletedSuccessfully && _auth.CurrentUser != null;
                if (signedIn) FirebaseRegistration.ReportInstallOnce();
                done(signedIn);
            });
        });

        public GoogleProfile RestoredProfile()
        {
            var user = _ready ? _auth.CurrentUser : null;
            if (user == null || user.IsAnonymous) return null;
            return new GoogleProfile(user.DisplayName, user.PhotoUrl?.ToString());
        }

        // ---- groups ----------------------------------------------------------------------------------

        public void FetchMyGroupCode(Action<string> done)
        {
            var uid = Uid;
            if (uid == null) { done(null); return; }
            _db.Collection("players").Document(uid).GetSnapshotAsync().ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully) { Log("fetchMyGroupCode", task); done(null); return; }
                done(task.Result.TryGetValue("groupCode", out string code) && !string.IsNullOrEmpty(code) ? code : null);
            });
        }

        public void IsGroupCreator(string code, Action<bool> done)
        {
            var uid = Uid;
            if (uid == null) { done(false); return; }
            _db.Collection("groups").Document(code).GetSnapshotAsync().ContinueWithOnMainThread(task =>
            {
                done(task.IsCompletedSuccessfully && task.Result.TryGetValue("createdBy", out string by) && by == uid);
            });
        }

        public void CreateGroup(string displayName, System.Random rng, Action<string> done) =>
            TryCreate(displayName, rng, CodeAttempts, done);

        private void TryCreate(string displayName, System.Random rng, int attemptsLeft, Action<string> done)
        {
            var uid = Uid;
            if (uid == null || attemptsLeft <= 0) { done(null); return; }
            var code = new string(Enumerable.Range(0, InviteLink.CodeLength)
                .Select(_ => InviteLink.CodeAlphabet[rng.Next(InviteLink.CodeAlphabet.Length)]).ToArray());
            var group = _db.Collection("groups").Document(code);
            group.GetSnapshotAsync().ContinueWithOnMainThread(read =>
            {
                if (!read.IsCompletedSuccessfully) { Log("createGroup", read); done(null); return; }
                if (read.Result.Exists) { TryCreate(displayName, rng, attemptsLeft - 1, done); return; }
                var data = new Dictionary<string, object> { ["createdBy"] = uid, ["createdAt"] = FieldValue.ServerTimestamp };
                group.SetAsync(data).ContinueWithOnMainThread(write =>
                {
                    if (!write.IsCompletedSuccessfully) { Log("createGroup", write); done(null); return; }
                    WriteMembership(code, displayName, null, ok => done(ok ? code : null));
                });
            });
        }

        public void JoinGroup(string code, string displayName, Action<JoinResult> done)
        {
            var uid = Uid;
            if (uid == null) { done(JoinResult.Failed); return; }
            var group = _db.Collection("groups").Document(code);
            group.GetSnapshotAsync().ContinueWithOnMainThread(read =>
            {
                if (!read.IsCompletedSuccessfully) { Log("joinGroup", read); done(JoinResult.Failed); return; }
                if (!read.Result.Exists) { done(JoinResult.NotFound); return; }
                var creator = read.Result.TryGetValue("createdBy", out string by) ? by : null;
                group.Collection("players").Document(uid).GetSnapshotAsync().ContinueWithOnMainThread(member =>
                {
                    if (!member.IsCompletedSuccessfully) { Log("joinGroup", member); done(JoinResult.Failed); return; }
                    if (member.Result.Exists)
                    {
                        WriteMembership(code, displayName, null, ok => done(ok ? JoinResult.AlreadyMember : JoinResult.Failed));
                        return;
                    }
                    var invitedBy = !string.IsNullOrEmpty(creator) && creator != uid ? creator : null;
                    WriteMembership(code, displayName, invitedBy, ok => done(ok ? JoinResult.Joined : JoinResult.Failed));
                });
            });
        }

        private void WriteMembership(string code, string displayName, string invitedBy, Action<bool> done)
        {
            var uid = Uid;
            if (uid == null) { done(false); return; }
            var player = new Dictionary<string, object> { ["groupCode"] = code, ["name"] = displayName };
            _db.Collection("players").Document(uid).SetAsync(player, SetOptions.MergeAll).ContinueWithOnMainThread(first =>
            {
                if (!first.IsCompletedSuccessfully) { Log("membership", first); done(false); return; }
                var row = new Dictionary<string, object>
                {
                    ["name"] = displayName, ["updatedAt"] = FieldValue.ServerTimestamp, ["tableKey"] = "",
                };
                if (invitedBy != null) row["invitedBy"] = invitedBy;
                _db.Collection("groups").Document(code).Collection("players").Document(uid)
                    .SetAsync(row, SetOptions.MergeAll).ContinueWithOnMainThread(second =>
                    {
                        if (!second.IsCompletedSuccessfully) Log("membership", second);
                        done(second.IsCompletedSuccessfully);
                    });
            });
        }

        // ---- scores ----------------------------------------------------------------------------------

        public void ReportScore(string code, string name, int chips, int hourly, int daily, string hourKey, string dayKey,
            string tableKey, string appVersion, string platform, string country, int playSeconds)
        {
            var uid = Uid;
            if (uid == null) return;
            Dictionary<string, object> Row() => new Dictionary<string, object>
            {
                ["name"] = name, ["chips"] = chips, ["hourly"] = hourly, ["daily"] = daily, ["hourKey"] = hourKey,
                ["dayKey"] = dayKey, ["updatedAt"] = FieldValue.ServerTimestamp, ["appVersion"] = appVersion,
                ["platform"] = platform, ["country"] = country,
            };

            var board = Row();
            if (playSeconds > 0) board["playSeconds"] = FieldValue.Increment(playSeconds);
            _db.Collection("leaderboard").Document(uid).SetAsync(board, SetOptions.MergeAll).ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully) Log("reportScore", task);
            });

            if (code == null) return;
            var member = Row();
            member["tableKey"] = tableKey;
            _db.Collection("groups").Document(code).Collection("players").Document(uid)
                .SetAsync(member, SetOptions.MergeAll).ContinueWithOnMainThread(task =>
                {
                    if (!task.IsCompletedSuccessfully) Log("reportScore (group)", task);
                });
        }

        public void AddPlayTime(int seconds)
        {
            var uid = Uid;
            if (uid == null || seconds <= 0) return;
            var data = new Dictionary<string, object> { ["playSeconds"] = FieldValue.Increment(seconds) };
            _db.Collection("leaderboard").Document(uid).SetAsync(data, SetOptions.MergeAll);
        }

        public void EnsureCreatedAtStamped()
        {
            var uid = Uid;
            if (uid == null) return;
            var doc = _db.Collection("leaderboard").Document(uid);
            doc.GetSnapshotAsync().ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully || (task.Result.Exists && task.Result.ContainsField("createdAt"))) return;
                doc.SetAsync(new Dictionary<string, object> { ["createdAt"] = FieldValue.ServerTimestamp }, SetOptions.MergeAll);
            });
        }

        // ---- watching --------------------------------------------------------------------------------

        public IDisposable WatchMembers(string code, Action<IReadOnlyList<Friend>> onUpdate)
        {
            return _db.Collection("groups").Document(code).Collection("players").Listen(snapshot =>
            {
                var now = DateTime.Now;
                var hourKey = Points.HourKeyOf(now);
                var dayKey = Points.DayKeyOf(now);
                var me = Uid;
                var members = snapshot.Documents.Where(d => d.Id != me)
                    .Select(d => FriendFrom(d, now, hourKey, dayKey)).ToList();
                onUpdate(members);
            });
        }

        private static Friend FriendFrom(DocumentSnapshot doc, DateTime now, string hourKey, string dayKey)
        {
            var d = doc.ToDictionary();
            string Str(string key, string fallback) => d.TryGetValue(key, out var v) && v is string s ? s : fallback;
            int Int(string key) => d.TryGetValue(key, out var v) && v != null ? Convert.ToInt32(v) : 0;

            var online = d.TryGetValue("updatedAt", out var stamp) && stamp is Timestamp ts
                         && now - ts.ToDateTime().ToLocalTime() < OnlineWindow;
            // A stale or empty tableKey never counts as "here": freshness is folded into the value.
            var rawTable = Str("tableKey", "");
            return new Friend(
                doc.Id, Str("name", "Player"), Int("chips"), online,
                DailyScore: Points.Rolled(Int("daily"), Str("dayKey", ""), dayKey),
                HourlyScore: Points.Rolled(Int("hourly"), Str("hourKey", ""), hourKey),
                InvitedBy: d.TryGetValue("invitedBy", out var by) ? by as string : null,
                TableKey: online && rawTable.Length > 0 ? rawTable : null);
        }

        // ---- Google sign-in ----------------------------------------------------------------------------

        /// <summary>
        /// Sign in with Google through Firebase's own OAuth flow. A guest keeps their identity: the Google account is
        /// linked onto the anonymous user, or — if that account already exists elsewhere — signed into directly.
        /// </summary>
        public void SignInWithGoogle(Action<GoogleProfile, string> done) => WhenReady(ok =>
        {
            if (!ok) { done(null, "unavailable"); return; }
#if BJ_FIREBASE_EMULATOR
            // QA builds only: the Auth emulator accepts a JSON "id token" for google.com, so the linked-account paths can be run
            // without a real Google account. The release build has no such branch.
            var qaCurrent = _auth.CurrentUser;
            var qa = GoogleAuthProvider.GetCredential(QaGoogleToken, null);
            if (qaCurrent != null && qaCurrent.IsAnonymous)
                qaCurrent.LinkWithCredentialAsync(qa).ContinueWithOnMainThread(link =>
                    { if (link.IsCompletedSuccessfully) Finish(link.Result.User, done); else done(null, "failed"); });
            else
                _auth.SignInWithCredentialAsync(qa).ContinueWithOnMainThread(signIn =>
                    { if (signIn.IsCompletedSuccessfully) Finish(signIn.Result, done); else done(null, "failed"); });
            return;
#else
            var provider = GoogleProvider();

            var current = _auth.CurrentUser;
            if (current != null && current.IsAnonymous)
            {
                current.LinkWithProviderAsync(provider).ContinueWithOnMainThread(link =>
                {
                    if (link.IsCompletedSuccessfully) { Finish(link.Result.User, done); return; }
                    // This Google account already has its own uid: sign into it, then the controller re-adopts its group.
                    if (IsError(link, AuthError.CredentialAlreadyInUse) || IsError(link, AuthError.EmailAlreadyInUse))
                    {
                        _auth.SignInWithProviderAsync(provider).ContinueWithOnMainThread(signIn => Complete(signIn, done));
                        return;
                    }
                    done(null, IsCancelled(link) ? "canceled" : "failed");
                });
                return;
            }
            _auth.SignInWithProviderAsync(provider).ContinueWithOnMainThread(signIn => Complete(signIn, done));
#endif
        });

#if BJ_FIREBASE_EMULATOR
        private const string QaGoogleToken =
            "{\"sub\": \"qa-google-teen-1\", \"email\": \"qa.teen@example.com\", \"email_verified\": true, \"name\": \"QA Teen\"}";
#endif

        private static FederatedOAuthProvider GoogleProvider()
        {
            var provider = new FederatedOAuthProvider();
            provider.SetProviderData(new FederatedOAuthProviderData
            {
                ProviderId = "google.com",
                Scopes = new List<string> { "email", "profile" },
            });
            return provider;
        }

        private static void Complete(System.Threading.Tasks.Task<AuthResult> task, Action<GoogleProfile, string> done)
        {
            if (task.IsCompletedSuccessfully) Finish(task.Result.User, done);
            else done(null, IsCancelled(task) ? "canceled" : "failed");
        }

        private static void Finish(FirebaseUser user, Action<GoogleProfile, string> done) =>
            done(new GoogleProfile(user?.DisplayName, user?.PhotoUrl?.ToString()), null);

        private static bool IsError(System.Threading.Tasks.Task task, AuthError error) =>
            task.Exception?.Flatten().InnerExceptions.OfType<FirebaseException>().Any(e => e.ErrorCode == (int)error) == true;

        private static bool IsCancelled(System.Threading.Tasks.Task task) =>
            task.IsCanceled || task.Exception?.Flatten().InnerExceptions.OfType<FirebaseException>()
                .Any(e => e.ErrorCode == (int)AuthError.WebContextCancelled) == true;

        public void SignOut(Action done)
        {
            if (_ready) _auth.SignOut();
            done();
        }

        // ---- account and data deletion ----------------------------------------------------------------

        public bool IsGoogleLinked
        {
            get
            {
                var user = _ready ? _auth.CurrentUser : null;
                return user != null && !user.IsAnonymous;
            }
        }

        /// <summary>Firebase refuses to delete an account that signed in long ago; a Google user signs in again to prove it is them.</summary>
        public void Reauthenticate(Action<bool> done)
        {
            var user = _ready ? _auth.CurrentUser : null;
            if (user == null) { done(false); return; }
#if BJ_FIREBASE_EMULATOR
            // QA builds only: the same re-authentication step with the emulator credential.
            user.ReauthenticateAsync(GoogleAuthProvider.GetCredential(QaGoogleToken, null)).ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully) Log("reauthenticate(qa)", task);
                done(task.IsCompletedSuccessfully);
            });
            return;
#endif
            user.ReauthenticateWithProviderAsync(GoogleProvider()).ContinueWithOnMainThread(task =>
            {
                if (!task.IsCompletedSuccessfully) Log("reauthenticate", task);
                done(task.IsCompletedSuccessfully);
            });
        }

        private const int TransactionChunk = 100;
        private const string Tombstone = "deleted";

        public void DeleteCloudRecords(string groupCode, Action commitStarted, Action<CloudDeleteResult> done)
        {
            var uid = Uid;
            if (uid == null) { done(CloudDeleteResult.NothingDeleted); return; }
            // Nothing queued earlier (a heartbeat written while offline, say) may land after the deletion, so drain first. While
            // the phone is offline this never answers and the controller's watchdog reports "nothing was deleted".
            _db.WaitForPendingWritesAsync().ContinueWithOnMainThread(drain =>
            {
                if (!drain.IsCompletedSuccessfully) { Log("waitForPendingWrites", drain); done(CloudDeleteResult.NothingDeleted); return; }
                var player = _db.Collection("players").Document(uid);
                // The server's own record of the group is authoritative: this device's copy may be stale or missing.
                player.GetSnapshotAsync(Source.Server).ContinueWithOnMainThread(read =>
                {
                    if (!read.IsCompletedSuccessfully) { Log("deleteCloudRecords/player", read); done(CloudDeleteResult.NothingDeleted); return; }
                    var codes = new List<string>();
                    AddCode(codes, groupCode);
                    if (read.Result.TryGetValue("groupCode", out string stored)) AddCode(codes, stored);
                    _db.Collection("groups").WhereEqualTo("createdBy", uid).GetSnapshotAsync(Source.Server).ContinueWithOnMainThread(created =>
                    {
                        if (!created.IsCompletedSuccessfully) { Log("deleteCloudRecords/created", created); done(CloudDeleteResult.NothingDeleted); return; }
                        var createdGroups = created.Result.Documents.Select(d => d.Reference).ToList();
                        foreach (var g in createdGroups) AddCode(codes, g.Id);
                        FindReferences(codes, uid, references =>
                        {
                            if (references == null) { done(CloudDeleteResult.NothingDeleted); return; }
                            Debug.Log($"Delete: commit started (references to clear: {references.Count}, groups created: {createdGroups.Count})");
                            commitStarted();
                            // Clearing a reference only touches someone else's invitedBy where it names this user, and is harmless
                            // if the rest then fails: a retry simply finds fewer. Own records are still intact at this point.
                            ClearReferences(references, 0, cleared =>
                            {
                                if (!cleared) { done(CloudDeleteResult.NothingDeleted); return; }
                                RemoveOwnRecords(uid, codes, createdGroups, player, done);
                            });
                        });
                    });
                });
            });
        }

        private static void AddCode(List<string> codes, string code)
        {
            if (!string.IsNullOrEmpty(code) && !codes.Contains(code)) codes.Add(code);
        }

        /// <summary>Member rows, in the given groups, whose invitedBy names the user. Null means a query failed.</summary>
        private void FindReferences(List<string> codes, string uid, Action<List<DocumentReference>> done)
        {
            var found = new List<DocumentReference>();
            void Next(int i)
            {
                if (i >= codes.Count) { done(found); return; }
                _db.Collection("groups").Document(codes[i]).Collection("players").WhereEqualTo("invitedBy", uid)
                    .GetSnapshotAsync(Source.Server).ContinueWithOnMainThread(q =>
                    {
                        if (!q.IsCompletedSuccessfully) { Log("findReferences", q); done(null); return; }
                        found.AddRange(q.Result.Documents.Select(d => d.Reference));
                        Next(i + 1);
                    });
            }
            Next(0);
        }

        private void ClearReferences(List<DocumentReference> rows, int start, Action<bool> done)
        {
            if (start >= rows.Count) { done(true); return; }
            var chunk = rows.Skip(start).Take(TransactionChunk).ToList();
            _db.RunTransactionAsync(tx =>
            {
                foreach (var row in chunk) tx.Update(row, new Dictionary<string, object> { ["invitedBy"] = Tombstone });
                return System.Threading.Tasks.Task.CompletedTask;
            }).ContinueWithOnMainThread(t =>
            {
                if (!t.IsCompletedSuccessfully) { Log("clearReferences", t); done(false); return; }
                ClearReferences(rows, start + chunk.Count, done);
            });
        }

        // One atomic transaction: a failed transaction writes nothing, and a transaction never queues while offline.
        private void RemoveOwnRecords(string uid, List<string> codes, List<DocumentReference> createdGroups,
            DocumentReference player, Action<CloudDeleteResult> done)
        {
            var board = _db.Collection("leaderboard").Document(uid);
            Debug.Log("Delete: final transaction started");
            _db.RunTransactionAsync(tx =>
            {
                foreach (var g in createdGroups) tx.Update(g, new Dictionary<string, object> { ["createdBy"] = Tombstone });
                foreach (var c in codes) tx.Delete(_db.Collection("groups").Document(c).Collection("players").Document(uid));
                tx.Delete(player);
                tx.Delete(board);
                return System.Threading.Tasks.Task.CompletedTask;
            }).ContinueWithOnMainThread(t =>
            {
                if (!t.IsCompletedSuccessfully)
                {
                    Log("removeOwnRecords", t);
                    // Only a network-class failure can hide a commit that did happen; anything else wrote nothing.
                    done(IsAmbiguous(t) ? CloudDeleteResult.MaybeDeleted : CloudDeleteResult.NothingDeleted);
                    return;
                }
                Debug.Log("Delete: final transaction committed");
                // Verify against the server, then sweep for a reference that appeared while this ran.
                player.GetSnapshotAsync(Source.Server).ContinueWithOnMainThread(p =>
                    board.GetSnapshotAsync(Source.Server).ContinueWithOnMainThread(b =>
                    {
                        if (!p.IsCompletedSuccessfully || !b.IsCompletedSuccessfully || p.Result.Exists || b.Result.Exists)
                        { done(CloudDeleteResult.MaybeDeleted); return; }
                        FindReferences(codes, uid, late =>
                        {
                            if (late == null) { done(CloudDeleteResult.MaybeDeleted); return; }
                            if (late.Count == 0) { done(CloudDeleteResult.Done); return; }
                            ClearReferences(late, 0, ok => done(ok ? CloudDeleteResult.Done : CloudDeleteResult.MaybeDeleted));
                        });
                    }));
            });
        }

        private static bool IsAmbiguous(System.Threading.Tasks.Task task) =>
            task.Exception?.Flatten().InnerExceptions.OfType<FirestoreException>().Any(e =>
                e.ErrorCode == FirestoreError.Unavailable || e.ErrorCode == FirestoreError.DeadlineExceeded
                || e.ErrorCode == FirestoreError.Unknown || e.ErrorCode == FirestoreError.Internal) == true
            || (task.Exception != null && !task.Exception.Flatten().InnerExceptions.OfType<FirestoreException>().Any());

        public void DeleteAuthUser(Action<DeleteStep> done)
        {
            var user = _ready ? _auth.CurrentUser : null;
            if (user == null) { done(DeleteStep.Done); return; }
            user.DeleteAsync().ContinueWithOnMainThread(task =>
            {
                if (task.IsCompletedSuccessfully) { done(DeleteStep.Done); return; }
                Log("deleteUser", task);
                done(IsError(task, AuthError.RequiresRecentLogin) ? DeleteStep.RecentLoginNeeded : DeleteStep.Failed);
            });
        }

        // ---- feature flags ---------------------------------------------------------------------------

        /// <summary>Remote switches from <c>config/features</c>. Only a signed-in user may read it, so this follows sign-in.</summary>
        public void LoadFeatureFlags(Action<IReadOnlyDictionary<string, bool>> done)
        {
            if (!_ready) { done(new Dictionary<string, bool>()); return; }
            _db.Collection("config").Document("features").GetSnapshotAsync().ContinueWithOnMainThread(task =>
            {
                var flags = new Dictionary<string, bool>();
                if (task.IsCompletedSuccessfully && task.Result.Exists)
                    foreach (var pair in task.Result.ToDictionary()) flags[pair.Key] = pair.Value is bool b && b;
                done(flags);
            });
        }

        private static void Log(string what, System.Threading.Tasks.Task task) =>
            Debug.LogWarning($"Firebase {what} failed: {task.Exception?.GetBaseException().Message}");
    }
}
