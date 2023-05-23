import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/driver.dart';

class DriverRepo {
  DriverRepo();

  final _driverRef = FirebaseFirestore.instance
      .collection("driver")
      .withConverter(fromFirestore: Driver.fromFirestore, toFirestore: (Driver driver, _) => driver.toFirestore());

  Future<DocumentReference<Driver>> create(Driver driver) async {
    return await _driverRef.add(driver);
  }

  Future<QueryDocumentSnapshot<Driver>?> get(String id) async {
    final snapshot = await _driverRef.where('id', isEqualTo: id).limit(1).get();
    if (snapshot.size > 0) {
      return snapshot.docs.first;
    }
    return null;
  }

  Future<void> update(QueryDocumentSnapshot<Driver> driver, Map<Object, Object?> updatedValues) async {
    await driver.reference.update(updatedValues);
  }

  Stream<QuerySnapshot<Driver>> listen(String userId) {
    return _driverRef.where("id", isEqualTo: userId).limit(1).snapshots();
  }
}
