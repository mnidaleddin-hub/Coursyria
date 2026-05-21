import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin? _notificationsPlugin =
      kIsWeb ? null : FlutterLocalNotificationsPlugin();

  static void initialize() {
    if (kIsWeb) return;

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    );

    _notificationsPlugin?.initialize(initializationSettings);
  }

  static void showNotification(String title, String body) {
    if (kIsWeb) return;

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        "coursyria_channel",
        "Coursyria Notifications",
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    _notificationsPlugin?.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }
}
