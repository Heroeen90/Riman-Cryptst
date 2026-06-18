import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: androidSettings));
  }

  static Future<void> updateProgress(int id, int progress) async {
    await _notifications.show(
      id,
      'Encryption in Progress',
      '$progress% complete',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'encryption_channel',
          'Encryption Channel',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: 50, // Updated dynamically
        ),
      ),
    );
  }
}
