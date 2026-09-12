/// Review requests are bounded by local cooldowns as well as Google's quota.
/// The API cannot tell us whether its sheet appeared or a rating was left.
const int kReviewMinHands = 10;
const int kReviewMaxRequests = 3;
const Duration kReviewFailureCooldown = Duration(days: 7);
const Duration kReviewSuccessCooldown = Duration(days: 90);

bool shouldPromptForReview({
  required int handsPlayed,
  required DateTime now,
  required int lastAttemptAtMs,
  required int completedRequests,
  required bool lastRequestSucceeded,
}) {
  if (handsPlayed < kReviewMinHands || completedRequests >= kReviewMaxRequests) return false;
  if (lastAttemptAtMs <= 0) return true;
  final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(lastAttemptAtMs));
  return elapsed >= (lastRequestSucceeded ? kReviewSuccessCooldown : kReviewFailureCooldown);
}
