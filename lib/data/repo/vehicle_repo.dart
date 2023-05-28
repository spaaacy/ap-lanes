import 'package:ap_lanes/data/model/remote/driver.dart';
import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleRepo {
  VehicleRepo();

  final _firestoreInstance = FirebaseFirestore.instance;

  final _vehicleRef = FirebaseFirestore.instance
      .collection("vehicle")
      .withConverter(fromFirestore: Vehicle.fromFirestore, toFirestore: (Vehicle vehicle, _) => vehicle.toFirestore());

  Future<DocumentReference<Vehicle>> create(Vehicle vehicle) async {
    return await _vehicleRef.add(vehicle);
  }

  Future<void> update(
    QueryDocumentSnapshot<Vehicle> vehicle,
    Map<Object, Object?> updatedValues,
  ) async {
    await vehicle.reference.update(updatedValues);
  }

  Future<QueryDocumentSnapshot<Vehicle>?> get(String? driverId) async {
    if (driverId == null) return null;

    final snapshot = await _vehicleRef.where('driverId', isEqualTo: driverId).limit(1).get();
    if (snapshot.size > 0) {
      return snapshot.docs.first;
    }
    return null;
  }

  Stream<QuerySnapshot<Vehicle>>? snapshots(String? driverId) {
    if (driverId == null) return null;

    return _vehicleRef.where('driverId', isEqualTo: driverId).limit(1).snapshots();
  }

  Stream<QuerySnapshot<Vehicle>> getAPUFleetSnapshots() {
    return _vehicleRef.where('isManagedByAPU', isEqualTo: true).where('driverId', isEqualTo: '').snapshots();
  }

  Future<void> switchToVehicles(QueryDocumentSnapshot<Driver> driver, QueryDocumentSnapshot<Vehicle> newVehicle) async {
    return _firestoreInstance.runTransaction((transaction) async {
      final targetVehicleDoc = await transaction.get(newVehicle.reference);
      final targetDriverDoc = await transaction.get(driver.reference);
      final previousVehicleDoc = await get(targetDriverDoc.data()?.id);

      if (!targetDriverDoc.exists || !targetVehicleDoc.exists) {
        throw Exception("Driver or vehicle does not have data.");
      }

      if (previousVehicleDoc != null) {
        if (previousVehicleDoc.data().driverId != targetDriverDoc.data()?.id) {
          throw Exception("Driver ID of driver's previous vehicle do not match.");
        }

        transaction.update(previousVehicleDoc.reference, {'driverId': ''});
      }

      transaction.update(targetVehicleDoc.reference, {'driverId': targetDriverDoc.data()!.id});
    });
  }

  Future<void> clearVehicleSelection(QueryDocumentSnapshot<Driver> driver) async {
    return _firestoreInstance.runTransaction((transaction) async {
      final targetDriverDoc = await transaction.get(driver.reference);

      if (!targetDriverDoc.exists) {
        throw Exception("Driver or vehicle does not have data.");
      }

      final driverVehicleDocs = await _vehicleRef.where('driverId', isEqualTo: targetDriverDoc.data()!.id).get();

      for (var v in driverVehicleDocs.docs) {
        v.reference.update({'driverId': ''});
      }
    });
  }
}
