import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../../util/location_helpers.dart';

class Driver {
  final String id;
  final String licensePlate;
  final bool isAvailable;
  final LatLng? currentLatLng;

  const Driver({
    required this.id,
    required this.licensePlate,
    required this.isAvailable,
    this.currentLatLng,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (licensePlate != null) "licensePlate": licensePlate,
      if (isAvailable != null) "isAvailable": isAvailable,
      if (currentLatLng != null) "currentLatLng": '${currentLatLng!.latitude}, ${currentLatLng!.longitude}',
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
      currentLatLng: getLatLngFromString(data?['currentLatLng']),
    );
  }
}
