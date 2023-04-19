import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Driver {
  final String id;
  final String licensePlate;
  final bool isAvailable;
  final String? currentLatLng;

  const Driver(
      {required this.id,
      required this.licensePlate,
      required this.isAvailable,
      this.currentLatLng
      });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (licensePlate != null) "licensePlate": licensePlate,
      if (isAvailable != null) "isAvailable": isAvailable,
      if (currentLatLng != null) "currentLatLng": currentLatLng,
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
        isAvailable: data?['isAvailable'],
        currentLatLng: data?['currentLatLng']
        );
  }
}
