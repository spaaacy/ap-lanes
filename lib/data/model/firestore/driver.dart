import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String licensePlate;
  final bool isAvailable;

  const Driver(
      {required this.id,
      required this.licensePlate,
      required this.isAvailable});

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
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
        id: data?['id'],
        licensePlate: data?['licensePlate'],
        isAvailable: data?['isAvailable']);
  }
}
