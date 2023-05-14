// this will be used as notification channel id
import 'dart:async';
import 'dart:ui';

import 'package:ap_lanes/data/model/remote/driver.dart';
import 'package:ap_lanes/util/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class DriverLocationService {
  static bool isRegistered = false;

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await Firebase.initializeApp();
    Timer.periodic(const Duration(seconds: 15), (Timer t) async {
      final String? driverDocPath = preferences.getString("driverPath");
      if (driverDocPath == null) return;

      var driverDoc = FirebaseFirestore.instance.doc(driverDocPath);
      var pos = await Geolocator.getCurrentPosition();
      driverDoc.update({'currentLatLng': '${pos.latitude}, ${pos.longitude}'});
    });
  }

  static void unregisterDriverLocationBackgroundService() async {
    isRegistered = false;
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
  }

  static void registerDriverLocationBackgroundService(
    QueryDocumentSnapshot<Driver>? driver
  ) async {
    isRegistered = true;
    final service = FlutterBackgroundService();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString("driverPath", driver!.reference.path);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      locationChannelId,
      locationChannelName,
      description: 'Driver location is being updated periodically.', // description
      importance: Importance.low, // importance must be at low or higher level
    );


    final notificationsPlugin = NotificationService().notificationPlugin;
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: locationChannelId,
        initialNotificationTitle: 'APLanes',
        initialNotificationContent: 'Driver location is periodically being updated.',
        foregroundServiceNotificationId: locationNotificationId,
        autoStartOnBoot: false
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
      ),
    );
  }
}
