import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_support.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for leaderboard
/// alerts ("Maya just passed you") and the scheduled daily-bonus reminder.
///
/// These are *local* notifications. True remote push needs an APNs
/// entitlement that a free personal Apple team cannot sign, so this is the
/// strongest mechanism this signing setup allows. Scheduled notifications
/// still fire when the app is closed — the OS delivers them, no process
/// needed.
class LocalNotifier {
  /// Fixed id for the daily-bonus reminder so re-scheduling always replaces
  /// the previous pending one instead of stacking up.
  static const int _kDailyBonusNotifId = 210;

  /// Fixed id for the play-day-streak reminder — same idempotent-reschedule
  /// reasoning as [_kDailyBonusNotifId], on the next available id.
  static const int _kStreakNotifId = 211;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _permissionGranted = false;

  /// Whether the OS has actually granted permission.
  ///
  /// Settings used to show its three notification toggles as ON regardless,
  /// so a player who had denied the OS prompt was looking at three switches
  /// that promised alerts nothing could deliver.
  bool get hasPermission => _permissionGranted;

  /// Sets up channels. Deliberately does **not** ask for permission.
  ///
  /// This used to request it inline, and because [init] is reached from the
  /// notifier's constructor the OS dialog landed on frame 1 — on top of the
  /// onboarding screen, over a blank grey window, before the player knew what
  /// the app was. That is the worst possible moment to ask: the player has no
  /// reason to say yes yet, and on Android a denial is effectively permanent.
  /// Ask later, from [requestPermission], once there is something to be
  /// notified *about*.
  Future<void> init() async {
    if (!notificationsSupported) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      final ok = await _plugin.initialize(settings: settings);
      _ready = ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.init failed: ${e.code}');
      _ready = false;
    }
  }

  /// Asks the OS for permission, returning whether it was granted.
  ///
  /// Call this only after the player has been told what they are agreeing to
  /// — turning on a notification setting, or accepting an in-app primer.
  Future<bool> requestPermission() async {
    if (!notificationsSupported || !_ready) return false;
    try {
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      // Whichever platform answered is the answer; the other returns null.
      _permissionGranted = ios ?? android ?? false;
      return _permissionGranted;
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.requestPermission failed: ${e.code}');
      _permissionGranted = false;
      return false;
    }
  }

  Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'leaderboard',
            'Leaderboard',
            channelDescription: 'Alerts when a friend passes your score',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.show failed: ${e.code}');
    }
  }

  /// Schedules the "daily chips are ready" reminder [after] from now,
  /// replacing any reminder already pending.
  ///
  /// The date is built in UTC on purpose: iOS receives the full ISO-8601
  /// instant and converts it to device-local calendar components itself, and
  /// Android receives the UTC wall clock labelled as UTC — so the reminder
  /// fires at the right moment without needing the device's IANA zone name.
  Future<void> scheduleDailyBonusReminder({required Duration after, required int chips}) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: _kDailyBonusNotifId,
        title: 'Your daily chips are ready!',
        body: 'Claim your free $chips chips and grab a seat at the table.',
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_bonus',
            'Daily bonus',
            channelDescription: 'Reminder when the free daily chips are ready to claim',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
        ),
        // Inexact keeps Android off the SCHEDULE_EXACT_ALARM permission; a
        // few minutes of drift is meaningless for a 24-hour bonus.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.scheduleDailyBonusReminder failed: ${e.code}');
    }
  }

  /// Cancels a pending daily-bonus reminder (bonus claimable again, or the
  /// user switched the daily reminder off in Settings).
  Future<void> cancelDailyBonusReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _kDailyBonusNotifId);
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.cancelDailyBonusReminder failed: ${e.code}');
    }
  }

  /// Schedules the "your streak ends tonight" reminder [after] from now,
  /// replacing any one already pending — mirrors
  /// [scheduleDailyBonusReminder] exactly, including the UTC scheduling
  /// rationale in its doc comment.
  Future<void> scheduleStreakReminder({required Duration after, required int streak}) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: _kStreakNotifId,
        title: 'Your $streak-day streak ends tonight',
        body: 'Play one hand to keep it going.',
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak',
            'Play streak',
            channelDescription: 'Reminder when today\'s play-day streak is about to lapse',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.scheduleStreakReminder failed: ${e.code}');
    }
  }

  /// Cancels a pending streak reminder (a hand was played today, the streak
  /// lapsed, or the user switched the daily reminder off in Settings).
  Future<void> cancelStreakReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _kStreakNotifId);
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.cancelStreakReminder failed: ${e.code}');
    }
  }
}
