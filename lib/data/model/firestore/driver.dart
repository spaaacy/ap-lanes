import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      if (currentLatLng != null) "currentLatLng": '${currentLatLng!.latitude},${currentLatLng!.longitude}',
    };
  }

  factory Driver.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    LatLng fsLatLng;
    if (data?['currentLatLng'] != null) {
      List<double>? latLngList =
          data!['currentLatLng'].toString().split(',').map((e) => double.tryParse(e.trim()) ?? 0).toList();
      fsLatLng = LatLng(latLngList[0], latLngList[1]);
    } else {
      fsLatLng = const LatLng(0.0, 0.0);
    }

    return Driver(
      id: data?['id'],
      licensePlate: data?['licensePlate'],
      isAvailable: data?['isAvailable'],
      currentLatLng: fsLatLng,
    );
  }
}
