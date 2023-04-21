import 'package:apu_rideshare/util/location_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Journey {
  final String userId;
  final LatLng startLatLng;
  final LatLng endLatLng;
  final String startDescription;
  final String endDescription;
  bool isCompleted;
  bool isPickedUp;
  bool isCancelled;
  String driverId;

  Journey({
    required this.userId,
    required this.startLatLng,
    required this.endLatLng,
    required this.startDescription,
    required this.endDescription,
    this.isCompleted = false,
    this.isCancelled = false,
    this.isPickedUp = false,
    this.driverId = "",
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (startLatLng != null) "startLatLng": '${startLatLng.latitude}, ${startLatLng.longitude}',
      if (endLatLng != null) "endLatLng": '${endLatLng.latitude}, ${endLatLng.longitude}',
      if (startDescription != null) "startDescription": startDescription,
      if (endDescription != null) "endDescription": endDescription,
      if (isCompleted != null) "isCompleted": isCompleted,
      if (isCancelled != null) "isCancelled": isCancelled,
      if (isPickedUp != null) "isPickedUp": isPickedUp,
      if (driverId != null) "driverId": driverId,
    };
  }

  factory Journey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Journey(
      userId: data?['userId'],
      startLatLng: getLatLngFromString(data?['startLatLng']),
      endLatLng: getLatLngFromString(data?['endLatLng']),
      startDescription: data?['startDescription'],
      endDescription: data?['endDescription'],
      isCompleted: data?['isCompleted'],
      isCancelled: data?['isCancelled'],
      isPickedUp: data?['isPickedUp'] ?? false,
      driverId: data?['driverId'],
    );
  }
}
