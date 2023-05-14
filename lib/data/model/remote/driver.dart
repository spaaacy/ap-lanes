import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../../util/location_helpers.dart';

class Driver {
  final String id;
  final String licensePlate;
  final String vehicleManufacturer;
  final String vehicleModel;
  final String vehicleColor;
  final bool isAvailable;
  final bool isVerified;
  final LatLng? currentLatLng;

  const Driver({
    required this.id,
    required this.licensePlate,
    required this.vehicleManufacturer,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.isAvailable,
    required this.isVerified,
    this.currentLatLng,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (licensePlate != null) "licensePlate": licensePlate,
      if (vehicleManufacturer != null) "vehicleManufacturer": vehicleManufacturer,
      if (vehicleModel != null) "vehicleModel": vehicleModel,
      if (vehicleColor != null) "vehicleColor": vehicleColor,
      if (isAvailable != null) "isAvailable": isAvailable,
      if (isVerified != null) "isVerified": isVerified,
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
      vehicleManufacturer: data?['vehicleManufacturer'],
      vehicleModel: data?['vehicleModel'],
      vehicleColor: data?['vehicleColor'],
      isAvailable: data?['isAvailable'],
      isVerified: data?['isVerified'],
      currentLatLng: getLatLngFromString(data?['currentLatLng']),
    );
  }
}
