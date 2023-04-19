import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/driver.dart';

class DriverRepo {
  DriverRepo();

  final _driverRef = FirebaseFirestore.instance
      .collection("driver")
      .withConverter(
          fromFirestore: Driver.fromFirestore,
          toFirestore: (Driver driver, _) => driver.toFirestore());

  Future<DocumentReference<Driver>> createDriver(Driver driver) async {
    return await _driverRef.add(driver);
  }

  Future<QueryDocumentSnapshot<Driver>> getDriver(String id) async {
    final snapshot = await _driverRef.where('id', isEqualTo: id).get();
    return snapshot.docs.first;
  }

  Future<void> updateDriver(QueryDocumentSnapshot<Driver> driver,
      Map<Object, Object?> updatedValues) async {
    await driver.reference.update(updatedValues);
  }

  Stream<QuerySnapshot<Driver>> listenToDriver(String userId) {
    return _driverRef.where("id", isEqualTo: userId).snapshots();
  }

}
