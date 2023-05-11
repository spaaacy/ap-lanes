import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../util/constants.dart';

class NotificationService {

  /*
  * Used to create singleton instance
  * */
  NotificationService._internal();
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin _notificationPlugin = FlutterLocalNotificationsPlugin();
  FlutterLocalNotificationsPlugin get notificationPlugin => _notificationPlugin;

  Future<void> initialize() async {
    const androidInitialization = AndroidInitializationSettings('ic_stat_feature_graphic');
    const iOSIInitialization = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(android: androidInitialization, iOS: iOSIInitialization);
    await notificationPlugin.initialize(initializationSettings);
  }

  Future<void> notifyPassenger(String title, {String? body}) async {
    const androidDetails = AndroidNotificationDetails(
      passengerChannelId,
      passengerChannelName,
      priority: Priority.high,
      importance: Importance.max,
      styleInformation: BigTextStyleInformation(''),
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await notificationPlugin.show(passengerNotificationId, title, body, notificationDetails);
  }

  Future<void> notifyDriver(String title, {String? body}) async {
    const androidDetails = AndroidNotificationDetails(
      driverChannelId,
      driverChannelName,
      priority: Priority.high,
      importance: Importance.max,
      styleInformation: BigTextStyleInformation(''),
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await notificationPlugin.show(driverNotificationId, title, body, notificationDetails);
  }
}
