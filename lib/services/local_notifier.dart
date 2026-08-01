import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for leaderboard
/// alerts ("Maya just passed you").
///
/// These are *local* notifications fired while the app process is alive.
/// True remote push (app fully closed) needs an APNs entitlement that a free
/// personal Apple team cannot sign, so this is the strongest mechanism this
/// signing setup allows.
class LocalNotifier {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      final ok = await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('LocalNotifier.init failed: ${e.code}');
      _ready = false;
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
}
