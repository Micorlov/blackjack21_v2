import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Opens Google Play's in-app review sheet.
///
/// A thin wrapper so the decision to ask ([shouldPromptForReview] in
/// `utils/review_prompt.dart`) stays testable and this stays the only place
/// that touches the plugin. Failures are swallowed: a review sheet that will
/// not open is not worth interrupting a hand for, and the platform declines
/// silently anyway once its own quota is spent.
class ReviewPrompter {
  /// Injected in tests so nothing reaches a platform channel there.
  ReviewPrompter({InAppReview? review}) : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  /// Asks the platform to show its rating sheet. Returns whether the request
  /// was made — not whether the player rated, which Google never reports.
  ///
  /// Callers set their "already asked" flag on `true` here regardless of what
  /// the player does next; see [GameState.reviewPromptShown].
  Future<bool> request() async {
    try {
      if (!await _review.isAvailable()) return false;
      await _review.requestReview();
      return true;
    } on Object catch (e) {
      debugPrint('ReviewPrompter.request failed: $e');
      return false;
    }
  }
}
