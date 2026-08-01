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

  Future<void> saveLastClaim(DateTime claimedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastClaimKey, claimedAt.millisecondsSinceEpoch);
    } on Exception catch (e) {
      debugPrint('DailyBonusStore.saveLastClaim failed: $e');
    }
  }
}
