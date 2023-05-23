import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../../util/location_helpers.dart';

class Driver {
  final String id;
  final bool isAvailable;
  final bool isVerified;
  final LatLng? currentLatLng;

  const Driver({
    required this.id,
    required this.isAvailable,
    required this.isVerified,
    this.currentLatLng,
  });

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "isAvailable": isAvailable,
      "isVerified": isVerified,
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
      isAvailable: data?['isAvailable'],
      isVerified: data?['isVerified'],
      currentLatLng: getLatLngFromString(data?['currentLatLng']),
    );
  }
}
