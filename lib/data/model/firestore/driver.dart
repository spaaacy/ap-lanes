import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String userId;
  final String licensePlate;
  final bool isAvailable;

  const Driver(
      {required this.userId,
      required this.licensePlate,
      required this.isAvailable});

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (licensePlate != null) "licensePlate": licensePlate,
      if (isAvailable != null) "isAvailable": isAvailable,
    };
  }

  factory Driver.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Driver(
        userId: data?['userId'],
        licensePlate: data?['licensePlate'],
        isAvailable: data?['isAvailable']);
  }
}
