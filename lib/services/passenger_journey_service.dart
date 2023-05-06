import 'dart:ui';

import 'package:ap_lanes/services/notification_service.dart';
import 'package:ap_lanes/util/constants.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerJourneyService {
  static final PassengerJourneyService _passengerJourneyService = PassengerJourneyService._internal();

  factory PassengerJourneyService() {
    return _passengerJourneyService;
  }

  PassengerJourneyService._internal();

  final notificationService = NotificationService();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: false,
          notificationChannelId: passengerChannelId,
          initialNotificationTitle: 'APLanes',
          initialNotificationContent: 'Loading your journey',
          foregroundServiceNotificationId: passengerNotificationId
        ),
        iosConfiguration: IosConfiguration());
  }

  @pragma('vm:entry_point')
  void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    // await here

    final notificationsPlugin = notificationService.notificationPlugin;

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    notificationService.notifyPassenger("Service started!");
  }
}
