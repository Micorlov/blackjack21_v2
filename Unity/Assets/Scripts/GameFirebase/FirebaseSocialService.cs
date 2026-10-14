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
            var provider = new FederatedOAuthProvider();
            provider.SetProviderData(new FederatedOAuthProviderData
            {
                ProviderId = "google.com",
                Scopes = new List<string> { "email", "profile" },
            });

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
        });

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
