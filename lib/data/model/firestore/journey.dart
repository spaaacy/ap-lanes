import 'package:cloud_firestore/cloud_firestore.dart';

class Journey {
  final String userId;
  final String startPoint;
  final String destination;
  bool isPickedUp;
  bool isCompleted;
  String driverId;

  Journey({
    required this.userId,
    required this.startPoint,
    required this.destination,
    this.isCompleted = false,
    this.isPickedUp = false,
    this.driverId = "",
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (startPoint != null) "startPoint": startPoint,
      if (destination != null) "destination": destination,
      if (isCompleted != null) "isCompleted": isCompleted,
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
      startPoint: data?['startPoint'],
      destination: data?['destination'],
      isCompleted: data?['isCompleted'],
      isPickedUp: data?['isPickedUp'],
      driverId: data?['driverId'],
    );
  }
}
