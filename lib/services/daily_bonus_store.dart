import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the moment of the last daily-bonus claim across app launches, so
/// restarting the app can never re-arm the claim before its 24-hour cooldown
/// has run out.
///
/// A load or save that fails (first run, corrupted store) degrades to "never
/// claimed" rather than crashing — the worst outcome is one extra bonus.
class DailyBonusStore {
  static const String _kLastClaimKey = 'dailyBonusLastClaimMs';
  static const String _kStreakDayKey = 'dailyBonusStreakDay';

  Future<DateTime?> loadLastClaim() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kLastClaimKey);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } on Exception catch (e) {
      debugPrint('DailyBonusStore.loadLastClaim failed: $e');
      return null;
    }
  }

  /// The streak day the last claim landed on (1..7); 0 when nothing stored.
  /// A store written before streaks existed simply has no key, which also
  /// reads as 0 — the next claim then starts the ladder at day 1.
  Future<int> loadStreakDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kStreakDayKey) ?? 0;
    } on Exception catch (e) {
      debugPrint('DailyBonusStore.loadStreakDay failed: $e');
      return 0;
    }
  }

  Future<void> saveClaim(DateTime claimedAt, int streakDay) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastClaimKey, claimedAt.millisecondsSinceEpoch);
      await prefs.setInt(_kStreakDayKey, streakDay);
    } on Exception catch (e) {
      debugPrint('DailyBonusStore.saveClaim failed: $e');
    }
  }
}
