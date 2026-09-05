import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// The app's one way of reporting what happens, and what breaks.
///
/// Until this existed the app had neither: no analytics, and no error handler
/// at all — `SocialService`, `GameStore` and `LocalNotifier` each caught their
/// failures and `debugPrint`ed them into a console nobody would ever see. A
/// player whose sign-in failed, whose save was corrupt, or whose app crashed
/// produced no signal whatsoever, so there was no way to tell a bad build from
/// a quiet week.
///
/// Two deliberate limits:
///
/// * **Nothing identifying.** Every event below carries counts, outcomes and
///   settings — never display names, group codes, uids or chat text.
/// * **The player can turn it off**, and that switch is honoured here rather
///   than remembered at each call site.
///
/// Every method swallows its own failures: reporting is never worth taking the
/// game down for.
class Analytics {
  /// Both are nullable so tests, and any build where Firebase failed to come
  /// up, can hold an instance that reports nowhere rather than making every
  /// call site guard.
  Analytics({this.analytics, this.crashlytics});

  final FirebaseAnalytics? analytics;
  final FirebaseCrashlytics? crashlytics;

  bool _enabled = true;

  /// Mirrors the Settings toggle. Turning it off also tells the SDKs to stop
  /// collecting, so nothing is queued while it is off.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      await analytics?.setAnalyticsCollectionEnabled(enabled);
      await crashlytics?.setCrashlyticsCollectionEnabled(enabled);
    } on Object catch (e) {
      debugPrint('Analytics.setEnabled failed: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_enabled) return;
    try {
      await analytics?.logEvent(name: name, parameters: params);
    } on Object catch (e) {
      debugPrint('Analytics.logEvent($name) failed: $e');
    }
  }

  /// A screen the player moved to. Named from the [AppScreen] enum, so the
  /// funnel matches the app's own navigation rather than a parallel list of
  /// strings.
  Future<void> logScreen(String screen) async {
    if (!_enabled) return;
    try {
      await analytics?.logScreenView(screenName: screen);
    } on Object catch (e) {
      debugPrint('Analytics.logScreen($screen) failed: $e');
    }
  }

  /// A caught failure that did not stop the app — a failed Firestore write, a
  /// save that could not be read. These are exactly the cases that used to
  /// vanish into `debugPrint`.
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) async {
    if (!_enabled) return;
    try {
      await crashlytics?.recordError(error, stack, reason: reason, fatal: false);
    } on Object catch (e) {
      debugPrint('Analytics.recordError failed: $e');
    }
  }
}

/// Event names, in one place so a typo cannot quietly create a second funnel.
class AnalyticsEvent {
  AnalyticsEvent._();

  static const String handPlayed = 'hand_played';
  static const String dailyBonusClaimed = 'daily_bonus_claimed';
  static const String missionClaimed = 'mission_claimed';
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String levelUp = 'level_up';
  static const String tableEntered = 'table_entered';
  static const String rebuy = 'rebuy';
  static const String inviteShared = 'invite_shared';
  static const String outOfChips = 'out_of_chips';
}
