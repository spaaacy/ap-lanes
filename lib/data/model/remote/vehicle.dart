import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String licensePlate;
  final String manufacturer;
  final String model;
  final String color;
  final String? driverId;
  final bool isManagedByAPU;

  Vehicle({
    required this.licensePlate,
    required this.manufacturer,
    required this.model,
    required this.color,
    this.driverId,
    this.isManagedByAPU = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      "licensePlate": licensePlate,
      "manufacturer": manufacturer,
      "model": model,
      "color": color,
      "driverId": driverId,
      "isManagedByAPU": isManagedByAPU,
    };
  }

  factory Vehicle.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    return Vehicle(
      licensePlate: data?['licensePlate'],
      manufacturer: data?['manufacturer'],
      model: data?['model'],
      color: data?['color'],
      driverId: data?['driverId'],
      isManagedByAPU: data?['isManagedByAPU'],
    );
  }
}
