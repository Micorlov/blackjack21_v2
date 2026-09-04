/// Pure referral-credit logic for the friends group.
///
/// A referral is a member whose `invitedBy` equals the hero's own uid — set
/// once, at join time, by `SocialService.joinGroup`/`_writeMembership` and
/// enforced write-once by `firestore.rules`. Counting from the live members
/// stream (rather than a separate counter document) means the count can
/// never drift from reality and needs no extra write path.
library;

import '../models/social_models.dart';

/// Chips granted to whoever taps a friend's invite link and joins.
const int kReferralWelcomeChips = 200;

/// Chips granted to the inviter for each friend who joins through their
/// link, paid automatically the moment the join is first observed.
const int kReferralJoinChips = 100;

/// The members of [group] that [heroUid] gets referral credit for.
List<Friend> referredBy(List<Friend> group, String heroUid) =>
    group.where((f) => f.invitedBy == heroUid).toList();

/// How many real friends [heroUid] has brought into the group so far.
int referralCount(List<Friend> group, String heroUid) => referredBy(group, heroUid).length;

/// Referred members whose join bonus has not yet been paid — i.e. not
/// already present in [rewardedIds]. The caller pays each one, then appends
/// its id to the persisted list so a later snapshot (including one seen
/// again after a relaunch) never pays twice.
List<Friend> unrewardedReferrals(List<Friend> group, String heroUid, List<String> rewardedIds) {
  final rewarded = rewardedIds.toSet();
  return referredBy(group, heroUid).where((f) => !rewarded.contains(f.id)).toList();
}
