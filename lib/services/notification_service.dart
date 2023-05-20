import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  late final BuildContext _context;

  Future<void> initialize(BuildContext context) async {
    _context = context;

    const androidInitialization = AndroidInitializationSettings('ic_stat_feature_graphic');

    final iOSInitialization = DarwinInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    final initializationSettings = InitializationSettings(android: androidInitialization, iOS: iOSInitialization);
    await notificationPlugin.initialize(initializationSettings);
    notificationPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
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

  // For iOS, when app is in foreground
  void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: _context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: (title != null) ? Text(title) : null,
        content: (body != null) ? Text(body) : null,
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
          )
        ],
      ),
    );
  }

}
