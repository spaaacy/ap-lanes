import 'package:cloud_firestore/cloud_firestore.dart';

class Journey {
  final String userId;
  final String startLatLng;
  final String endLatLng;
  final String startDescription;
  final String endDescription;
  bool isCompleted;
  bool hasDriver;
  String driverId;

  Journey({
    required this.userId,
    required this.startLatLng,
    required this.endLatLng,
    required this.startDescription,
    required this.endDescription,
    this.isCompleted = false,
    this.hasDriver = false,
    this.driverId = "",
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (startLatLng != null) "startLatLng": startLatLng,
      if (endLatLng != null) "endLatLng": endLatLng,
      if (startDescription != null) "startDescription": startDescription,
      if (endDescription != null) "endDescription": endDescription,
      if (isCompleted != null) "isCompleted": isCompleted,
      if (hasDriver != null) "hasDriver": hasDriver,
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
      startLatLng: data?['startLatLng'],
      endLatLng: data?['endLatLng'],
      startDescription: data?['startDescription'],
      endDescription: data?['endDescription'],
      isCompleted: data?['isCompleted'],
      hasDriver: data?['hasDriver'],
      driverId: data?['driverId'],
    );
  }
}
