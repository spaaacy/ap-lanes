import 'package:cloud_firestore/cloud_firestore.dart';

class Journey {
  final String userId;
  final String startPoint;
  final String destination;
  bool isCompleted;
  bool hasDriver;
  String driverId;

  Journey({
    required this.userId,
    required this.startPoint,
    required this.destination,
    this.isCompleted = false,
    this.hasDriver = false,
    this.driverId = "",

  });

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (startPoint != null) "id": startPoint,
      if (destination != null) "destination": destination,
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
        startPoint: data?['startPoint'],
        destination: data?['destination'],
        isCompleted: data?['isCompleted'],
        hasDriver: data?['hasDriver'],
        driverId: data?['driverId'],
    );
  }

}