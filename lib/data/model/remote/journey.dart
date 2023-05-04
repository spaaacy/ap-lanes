import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../util/location_helpers.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class Journey {
  final String userId;
  final latlong2.LatLng startLatLng;
  final latlong2.LatLng endLatLng;
  final String startDescription;
  final String endDescription;
  bool isCompleted;
  bool isPickedUp;
  bool isCancelled;
  String driverId;
  DateTime createdAt;

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
    DateTime? createdOn,
  }) : createdAt = createdOn ?? DateTime.now();

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
      if (createdAt != null) "createdAt": createdAt.millisecondsSinceEpoch,
    };
  }

  factory Journey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Journey(
      userId: data?['userId'],
      startLatLng: newGetLatLngFromString(data?['startLatLng']),
      endLatLng: newGetLatLngFromString(data?['endLatLng']),
      startDescription: data?['startDescription'],
      endDescription: data?['endDescription'],
      isCompleted: data?['isCompleted'],
      isCancelled: data?['isCancelled'],
      isPickedUp: data?['isPickedUp'],
      driverId: data?['driverId'],
      createdOn: data?['createdAt'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(
              data!['createdAt'],
            ),
    );
  }
}
