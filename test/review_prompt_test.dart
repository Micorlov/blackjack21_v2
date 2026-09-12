import 'package:blackjack21_v2/utils/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 12);
  bool ask({int hands = 10, int count = 0, int daysAgo = 0, bool success = false, bool attempted = false}) =>
      shouldPromptForReview(
        handsPlayed: hands,
        now: now,
        lastAttemptAtMs: attempted ? now.subtract(Duration(days: daysAgo)).millisecondsSinceEpoch : 0,
        completedRequests: count,
        lastRequestSucceeded: success,
      );
  test('requires enough experience without filtering by outcome', () {
    expect(ask(hands: 9), isFalse);
    expect(ask(), isTrue);
  });
  test('failed attempts can retry after seven days, not immediately', () {
    expect(ask(attempted: true, daysAgo: 6), isFalse);
    expect(ask(attempted: true, daysAgo: 7), isTrue);
  });
  test('completed requests wait ninety days and stop at three', () {
    expect(ask(attempted: true, count: 1, success: true, daysAgo: 89), isFalse);
    expect(ask(attempted: true, count: 1, success: true, daysAgo: 90), isTrue);
    expect(ask(attempted: true, count: 3, success: true, daysAgo: 180), isFalse);
  });
  test('a clock moved backwards cannot trigger a repeat request', () {
    expect(ask(attempted: true, daysAgo: -20), isFalse);
  });
}
