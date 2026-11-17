using System;
using System.Collections.Generic;
using System.Linq;
using Blackjack.Core;
using Blackjack.Game.Services;

namespace Blackjack.Game
{
    /// <summary>The live friends group: sign-in, invites, score sync, overtake alerts and referral rewards.</summary>
    public sealed partial class GameController
    {
        private const float HeartbeatSeconds = 60f;

        private IDisposable _groupSub;
        private TimerHandle _heartbeatTimer;
        private bool _groupLive;
        private bool _clipboardChecked;

        // ---- boot -----------------------------------------------------------------------------------

        private void InitSocial()
        {
            _svc.Social.EnsureSignedIn(ok =>
            {
                if (!ok) return;
                _svc.Social.LoadFeatureFlags(flags => _flags = flags ?? _flags);

                var restored = _svc.Social.RestoredProfile();
                if (restored != null && !State.SignedIn)
                    Set(s => s with { SignedIn = true, DisplayName = restored.DisplayName ?? "Player", PhotoUrl = restored.PhotoUrl });

                Set(s => s with { SocialReady = true, HeroUid = _svc.Social.Uid });
                // Publish at once so this player exists in the group from the first launch.
                ReportScore();
                _svc.Social.EnsureCreatedAtStamped();
                _svc.Social.FetchMyGroupCode(code =>
                {
                    if (code != null) SubscribeGroup(code);
                    else if (State.PendingJoinCode != null) JoinCode(State.PendingJoinCode, viaLink: true);
                });
                _heartbeatTimer?.Cancel();
                ScheduleHeartbeat();
            });
        }

        private void ScheduleHeartbeat() => _heartbeatTimer = After(HeartbeatSeconds, () => { Heartbeat(); ScheduleHeartbeat(); });

        /// <summary>The leaderboard name: the Google name when signed in, else a stable guest tag from the anonymous uid.</summary>
        private string PlayerName
        {
            get
            {
                if (State.SignedIn) return State.DisplayName;
                var uid = _svc.Social.Uid;
                return string.IsNullOrEmpty(uid) || uid.Length < 4 ? "Guest" : "Guest " + uid.Substring(0, 4).ToUpperInvariant();
            }
        }

        // ---- group ----------------------------------------------------------------------------------

        private void SubscribeGroup(string code)
        {
            _groupSub?.Dispose();
            _groupLive = false;
            Set(s => s with { GroupCode = code });
            _groupSub = _svc.Social.WatchMembers(code, OnGroupUpdate);
        }

        private void OnGroupUpdate(IReadOnlyList<Friend> members)
        {
            var now = _now();
            var heroId = _svc.Social.Uid ?? "hero";
            var heroHourly = Points.Rolled(State.HeroHourlyPoints, State.HeroHourKey, Points.HourKeyOf(now));
            var heroDaily = Points.Rolled(State.HeroDailyPoints, State.HeroDayKey, Points.DayKeyOf(now));

            List<RankedPlayer> Ranked(IReadOnlyList<Friend> friends, int heroPoints, bool hourly)
            {
                var list = friends.Select(f => new RankedPlayer(f.Id, f.FirstName, hourly ? f.HourlyScore : f.DailyScore)).ToList();
                list.Add(new RankedPlayer(heroId, "You", heroPoints));
                return list;
            }

            if (_groupLive && State.NotifLeaderboard)
            {
                var overHourly = Ranking.Overtakers(Ranked(State.Friends, heroHourly, true), Ranked(members, heroHourly, true), heroId);
                var overDaily = Ranking.Overtakers(Ranked(State.Friends, heroDaily, false), Ranked(members, heroDaily, false), heroId);
                NotifyOvertaken(overHourly, overDaily);
            }

            var wasLive = _groupLive;
            _groupLive = members.Count > 0;
            // Alone in the group: practice bots keep the table lively, but FriendsAreLive stays false.
            Set(s => s with
            {
                Friends = members.Count == 0 ? Roster.InitialFriends : members,
                FriendsAreLive = members.Count > 0,
            });
            PayOutstandingReferrals(members, wasLive);
        }

        /// <summary>
        /// Pays the inviter for every referred friend not yet rewarded, on every snapshot so a friend who joined
        /// while this device was offline is still credited when the stream reconnects.
        /// </summary>
        private void PayOutstandingReferrals(IReadOnlyList<Friend> members, bool wasWatchingBefore)
        {
            if (!FlagEnabled(FeatureFlag.ReferralRewards)) return;
            var me = _svc.Social.Uid;
            if (me == null) return;
            var unpaid = Referrals.Unrewarded(members, me, State.RewardedReferralIds);
            if (unpaid.Count > 0)
            {
                var chips = unpaid.Count * Referrals.JoinChips;
                Set(s => s with
                {
                    Round = s.Round with { Chips = s.Round.Chips + chips },
                    RewardedReferralIds = s.RewardedReferralIds.Concat(unpaid.Select(f => f.Id)).ToList(),
                });
                ScheduleSave();
                var body = unpaid.Count == 1
                    ? $"{unpaid[0].FirstName} joined your table! +{Referrals.JoinChips} chips"
                    : $"{unpaid.Count} friends joined your table! +{chips} chips";
                ShowToast(body);
                // A notification only makes sense for a live update, never the first snapshot after (re)subscribing.
                if (wasWatchingBefore && State.NotifSocial)
                {
                    _svc.Notifier.Show("New friend at your table", body);
                    PlaySfx(GameSfx.Win);
                }
            }
            Set(s => s with { ReferralsCount = Referrals.Count(members, me) });
        }

        private void NotifyOvertaken(IReadOnlyList<RankedPlayer> hourly, IReadOnlyList<RankedPlayer> daily)
        {
            if (hourly.Count == 0 && daily.Count == 0) return;
            var lead = (hourly.Count > 0 ? hourly : daily)[0].Name;
            var period = hourly.Count > 0 ? "hourly" : "daily";
            var count = hourly.Concat(daily).Select(p => p.Id).Distinct().Count();
            var body = count == 1
                ? $"{lead} just passed you on the {period} leaderboard. Win your spot back!"
                : $"{count} friends just passed you on the leaderboard. Win your spot back!";
            ShowToast(body);
            _svc.Notifier.Show("You lost your spot!", body);
        }

        /// <summary>Once a minute: roll stale point buckets and refresh the player's row (which also keeps the "online" dot alive).</summary>
        private void Heartbeat()
        {
            var now = _now();
            var hourKey = Points.HourKeyOf(now);
            var dayKey = Points.DayKeyOf(now);
            if (hourKey != State.HeroHourKey || dayKey != State.HeroDayKey)
            {
                Set(s => s with
                {
                    HeroHourlyPoints = Points.Rolled(s.HeroHourlyPoints, s.HeroHourKey, hourKey),
                    HeroDailyPoints = Points.Rolled(s.HeroDailyPoints, s.HeroDayKey, dayKey),
                    HeroHourKey = hourKey,
                    HeroDayKey = dayKey,
                });
            }
            ReportScore();
        }

        private void ReportScore()
        {
            if (!State.SocialReady) return;
            _svc.Social.ReportScore(State.GroupCode, PlayerName, State.Round.Chips, State.HeroHourlyPoints, State.HeroDailyPoints,
                State.HeroHourKey, State.HeroDayKey,
                // Only the classic rooms are reported as presence: the deployed Firestore rules accept just those keys until the
                // trio / heads-up keys (already in firestore.rules) are published, and a refused write would drop the score too.
                State.Screen == AppScreen.Table && Round.Stake != null && TableCatalog.IsClassic(Round.Stake) ? Round.Stake.Key : "",
                _svc.Platform.AppVersion, _svc.Platform.PlatformName, _svc.Platform.CountryCode,
                _playTime.TakeSeconds());
        }

        // ---- invites --------------------------------------------------------------------------------

        private string InviteText(string code) => Loc.T("inviteMessage", ("url", InviteLink.UriFor(code)));

        /// <summary>Creates the group on first use (idempotent after) so every invite channel shares one code.</summary>
        private void EnsureGroupCode(Action<string> done)
        {
            if (!State.SocialReady)
            {
                ShowToast(Loc.Or("toastNoConnection", "No connection — try again in a moment"));
                return;
            }
            if (State.GroupCode != null) { ReportScore(); done(State.GroupCode); return; }
            _svc.Social.CreateGroup(PlayerName, _rng, code =>
            {
                if (code == null)
                {
                    ShowToast(Loc.Or("toastGroupFailed", "Could not create your group — try again"));
                    return;
                }
                if (State.GroupCode == null) SubscribeGroup(code);
                ReportScore();
                done(code);
            });
        }

        public void ShareInviteWhatsApp() => EnsureGroupCode(code =>
        {
            var url = "https://wa.me/?text=" + Uri.EscapeDataString(InviteText(code));
            var opened = _svc.Platform.OpenUrl(url);
            if (!opened) ShowToast(Loc.Or("toastWhatsAppFailed", "Could not open WhatsApp"));
            _svc.Analytics.LogEvent(AnalyticsEvent.InviteShared,
                new Dictionary<string, object> { ["channel"] = "whatsapp", ["opened"] = opened ? 1 : 0 });
        });

        public void ShareInviteSheet() => EnsureGroupCode(code => _svc.Platform.Share(InviteText(code)));

        public void CopyInviteLink() => EnsureGroupCode(code =>
        {
            _svc.Platform.SetClipboard(InviteLink.UriFor(code));
            ShowToast(Loc.Or("toastLinkCopied", "Link copied"));
        });

        // ---- joining --------------------------------------------------------------------------------

        public void JoinGroupByCode()
        {
            var code = State.FriendCodeInput.Trim().ToUpperInvariant();
            if (!InviteLink.IsValidCode(code))
            {
                ShowToast(Loc.Or("toastEnterCode", "Enter the {n}-character group code", ("n", InviteLink.CodeLength)));
                return;
            }
            JoinCode(code, viaLink: false);
        }

        /// <summary>Joins immediately if the social layer is up, otherwise queues the code for when it is.</summary>
        public void HandleIncomingLink(string route)
        {
            var code = InviteLink.CodeFromRoute(route);
            if (code == null) return;
            if (State.SocialReady) JoinCode(code, viaLink: true);
            else Set(s => s with { PendingJoinCode = code });
        }

        /// <summary>Pre-fills the join field from whatever is on the clipboard, once per launch.</summary>
        public void PrefillJoinFromClipboard()
        {
            if (_clipboardChecked) return;
            _clipboardChecked = true;
            if (State.GroupCode != null || State.FriendCodeInput.Length > 0) return;
            var code = InviteLink.CodeFromText(_svc.Platform.GetClipboard());
            if (code != null) Set(s => s with { FriendCodeInput = code });
        }

        private void JoinCode(string code, bool viaLink)
        {
            if (!State.SocialReady)
            {
                Set(s => s with { PendingJoinCode = code });
                return;
            }
            _svc.Social.JoinGroup(code, PlayerName, result =>
            {
                switch (result)
                {
                    case JoinResult.NotFound:
                        ShowToast(Loc.Or("toastGroupNotFound", "Group {code} not found", ("code", code)));
                        break;
                    case JoinResult.Failed:
                        ShowToast(Loc.Or("toastNoConnection", "No connection — try again in a moment"));
                        break;
                    case JoinResult.AlreadyMember:
                        _svc.Social.IsGroupCreator(code, own =>
                        {
                            Set(s => s with { FriendCodeInput = "", PendingJoinCode = null });
                            SubscribeGroup(code);
                            ReportScore();
                            ShowToast(Loc.T(own ? "joinOwnTableToast" : "joinAlreadyMemberToast"));
                        });
                        break;
                    case JoinResult.Joined:
                        // Referral credit for the inviter flows through OnGroupUpdate once the stream delivers this row.
                        Set(s => s with
                        {
                            FriendCodeInput = "",
                            PendingJoinCode = null,
                            JoinedViaLink = viaLink || s.JoinedViaLink,
                            Round = s.Round with { Chips = s.Round.Chips + Referrals.WelcomeChips },
                        });
                        SubscribeGroup(code);
                        ReportScore();
                        ScheduleSave();
                        ShowToast(Loc.T("joinedTableToast", ("chips", Referrals.WelcomeChips)));
                        PlaySfx(GameSfx.Win);
                        HapticMedium();
                        break;
                }
            });
        }

        // ---- sign-in --------------------------------------------------------------------------------

        public void SignInGoogle()
        {
            if (State.Screen == AppScreen.Onboarding)
                _svc.Analytics.LogEvent(AnalyticsEvent.EntrySelected, new Dictionary<string, object> { ["method"] = "google" });

            _svc.Social.SignInWithGoogle((profile, error) =>
            {
                if (profile == null)
                {
                    if (error != "canceled") ShowToast(Loc.Or("toastSignInFailed", "Google sign-in failed. Please try again."));
                    return;
                }
                var completingOnboarding = State.Screen == AppScreen.Onboarding;
                Set(s => s with
                {
                    SignedIn = true,
                    DisplayName = profile.DisplayName ?? "Player",
                    PhotoUrl = profile.PhotoUrl,
                    Screen = AppScreen.Lobby,
                    HeroUid = _svc.Social.Uid,
                });
                if (completingOnboarding)
                    _svc.Analytics.LogEvent(AnalyticsEvent.OnboardingComplete, new Dictionary<string, object> { ["method"] = "google" });
                RebindSocialIdentity();
                ScheduleSave();
                ReportScore();
            });
        }

        /// <summary>
        /// After the Firebase uid may have changed underneath the running session, re-read membership: adopt the
        /// new uid's group, or rejoin the one this device was already in.
        /// </summary>
        private void RebindSocialIdentity()
        {
            Set(s => s with { HeroUid = _svc.Social.Uid });
            _svc.Social.FetchMyGroupCode(code =>
            {
                if (code != null) SubscribeGroup(code);
                else if (State.GroupCode != null)
                {
                    var existing = State.GroupCode;
                    _svc.Social.JoinGroup(existing, PlayerName, _ => SubscribeGroup(existing));
                }
                ReportScore();
            });
        }

        public void PlayGuest() =>
            Set(s => s with { SignedIn = false, DisplayName = "Guest", PhotoUrl = null, Screen = AppScreen.Lobby });

        /// <summary>Starts a coached hand at the lowest-stakes table without signing in. Betting and dealing stay the player's actions.</summary>
        public void PlayNow()
        {
            _svc.Analytics.LogEvent(AnalyticsEvent.EntrySelected, new Dictionary<string, object> { ["method"] = "guest" });
            PlayGuest();
            EnterTable(TableCatalog.Tables[0]);
            ScheduleSave();
            _svc.Analytics.LogEvent(AnalyticsEvent.OnboardingComplete, new Dictionary<string, object> { ["method"] = "guest" });
        }

        public void SignOutUser() => _svc.Social.SignOut(() =>
        {
            Set(s => s with { SignedIn = false, DisplayName = "Guest", PhotoUrl = null });
            ShowToast(Loc.Or("toastSignedOut", "Signed out"));
        });

        // ---- account and data deletion ----------------------------------------------------------------

        private bool _deleting;
        private int _deleteGeneration;
        private bool _deleteMayHaveStarted;
        private bool _syncWasOn;

        // How long each phase may stay silent. Before the first change a silence means "offline, nothing deleted"; after it, the
        // outcome is unknown. Firestore transactions fail instead of queueing when offline, and the Auth call may still land late.
        private const float DeletePrepSeconds = 25f;
        private const float DeleteCommitSeconds = 60f;
        private const float DeleteAccountSeconds = 30f;

        /// <summary>
        /// Deletes the player's own online records, every reference to their uid, and their Firebase account, after the Settings
        /// dialog has confirmed. Order and safety:
        /// 1. everything that writes under the uid is stopped (heartbeat, group listener, SocialReady off) and queued writes drain;
        /// 2. a Google user signs in again first (Firebase insists on a recent sign-in);
        /// 3. the service clears the uid from other members' invitedBy and, in one atomic transaction, tombstones groups the player
        ///    created and deletes their own rows (see <see cref="ISocialService.DeleteCloudRecords"/>);
        /// 4. the Auth user is deleted.
        /// A step that never answers is NOT treated as cancelled: before the first change it means nothing was deleted and syncing
        /// resumes; afterwards the outcome is reported as unknown, syncing stays paused (resuming could write the rows back) and a
        /// retry, which is idempotent, settles it. Callbacks from an abandoned attempt are ignored. The save on this device (chips,
        /// stats, settings) is kept; only the online identity is reset.
        /// </summary>
        public void DeleteAccountAndData(Action<DeleteOutcome> done = null)
        {
            if (_deleting) return;
            var social = _svc.Social;

            void Report(DeleteOutcome outcome)
            {
                ShowToast(DeleteMessage(outcome));
                done?.Invoke(outcome);
            }

            if (!social.Available) { Report(DeleteOutcome.Unavailable); return; }
            if (string.IsNullOrEmpty(social.Uid))
            {
                // An earlier attempt that never reported back may have removed the account after all.
                if (_deleteMayHaveStarted) { FinishLocalDeletion(); Report(DeleteOutcome.Deleted); return; }
                Report(DeleteOutcome.Unavailable);
                return;
            }

            _deleting = true;
            var generation = ++_deleteGeneration;
            var code = State.GroupCode;
            if (!_deleteMayHaveStarted) _syncWasOn = State.SocialReady;
            _heartbeatTimer?.Cancel();
            _groupSub?.Dispose();
            _groupSub = null;
            Set(s => s with { SocialReady = false });

            TimerHandle watchdog = null;
            bool Current() => _deleting && generation == _deleteGeneration;
            void Arm(float seconds, Action onSilence) { watchdog?.Cancel(); watchdog = After(seconds, () => { if (Current()) onSilence(); }); }
            void Disarm() => watchdog?.Cancel();

            // Nothing of the player's own was deleted: normal syncing resumes, unless an earlier attempt may still land.
            void Resume(DeleteOutcome outcome)
            {
                _deleting = false;
                if (_syncWasOn && !_deleteMayHaveStarted)
                {
                    Set(s => s with { SocialReady = true });
                    if (code != null) SubscribeGroup(code);
                    ScheduleHeartbeat();
                }
                Report(outcome);
            }

            // The outcome is not known: stay paused; running the deletion again settles it.
            void GiveUp()
            {
                _deleteMayHaveStarted = true;
                _deleting = false;
                Report(DeleteOutcome.Unknown);
            }

            void RemoveAccount()
            {
                _deleteMayHaveStarted = true;   // from here the account may disappear at any moment
                Arm(DeleteAccountSeconds, GiveUp);
                social.DeleteAuthUser(step =>
                {
                    if (!Current()) return;
                    Disarm();
                    _deleting = false;
                    if (step == DeleteStep.Done) { FinishLocalDeletion(); Report(DeleteOutcome.Deleted); return; }
                    // The cloud rows are already gone. Do not resume syncing: it would write them back.
                    if (step == DeleteStep.RecentLoginNeeded && !social.IsGoogleLinked)
                    {
                        // A guest has nothing to sign in with again. Drop the session so the next launch starts a fresh guest.
                        _deleteMayHaveStarted = false;
                        social.SignOut(() =>
                        {
                            Set(s => s with { HeroUid = null, GroupCode = null, FriendsAreLive = false, Friends = Roster.InitialFriends });
                            ScheduleSave();
                            Report(DeleteOutcome.RecordsDeletedAccountKept);
                        });
                        return;
                    }
                    Report(DeleteOutcome.RecordsDeletedAccountKept);
                });
            }

            void RemoveCloud()
            {
                Arm(DeletePrepSeconds, () => Resume(DeleteOutcome.CloudFailed));
                social.DeleteCloudRecords(code,
                    () => { if (Current()) Arm(DeleteCommitSeconds, GiveUp); },
                    result =>
                    {
                        if (!Current()) return;
                        Disarm();
                        if (result == CloudDeleteResult.Done) RemoveAccount();
                        else if (result == CloudDeleteResult.NothingDeleted) Resume(DeleteOutcome.CloudFailed);
                        else GiveUp();
                    });
            }

            if (social.IsGoogleLinked)
                social.Reauthenticate(ok =>
                {
                    if (!Current()) return;
                    if (!ok) { Resume(DeleteOutcome.SignInFailed); return; }
                    RemoveCloud();
                });
            else
                RemoveCloud();
        }

        private void FinishLocalDeletion()
        {
            _deleting = false;
            _deleteMayHaveStarted = false;
            // SocialReady stays off: no heartbeat or score write may recreate a row this session. The next launch signs in as a
            // brand new anonymous guest, as on a first install.
            Set(s => s with
            {
                SignedIn = false, DisplayName = "Guest", PhotoUrl = null, GroupCode = null, HeroUid = null,
                HeroHourlyPoints = 0, HeroDailyPoints = 0, FriendsAreLive = false, Friends = Roster.InitialFriends,
            });
            ScheduleSave();
        }

        private static string DeleteMessage(DeleteOutcome outcome) => outcome switch
        {
            DeleteOutcome.Deleted => "Your online account and data were deleted.",
            DeleteOutcome.Unavailable => "Can't reach the server. Connect to the internet and try again.",
            DeleteOutcome.SignInFailed => "Sign in again with Google to confirm. Nothing was deleted.",
            DeleteOutcome.CloudFailed => "Couldn't delete your online data. Nothing was deleted. Check your connection and try again.",
            DeleteOutcome.Unknown => "We couldn't confirm the deletion finished. Online sync is paused. Choose Delete account and data again to check: trying again is safe.",
            _ => "Your online data was deleted, but the sign-in record couldn't be removed. Try again, or email us your account ID.",
        };
    }
}
