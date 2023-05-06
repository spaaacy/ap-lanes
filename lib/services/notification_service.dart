import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../util/constants.dart';

class NotificationService {

  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInitialization = AndroidInitializationSettings('mipmap/ic_launcher');
    const iOSIInitialization = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(android: androidInitialization, iOS: iOSIInitialization);
    await notificationPlugin.initialize(initializationSettings);
    notifyPassenger("test", "test");
  }

  Future<void> notifyPassenger(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      '$passengerNotificationId',
      passengerNotificationChannel,
      priority: Priority.high,
      importance: Importance.max,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await notificationPlugin.show(passengerNotificationId, title, body, notificationDetails);
  }
}
