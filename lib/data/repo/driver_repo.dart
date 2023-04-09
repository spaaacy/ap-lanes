import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/driver.dart';

class DriverRepo {
  DriverRepo();

  final _driverRef = FirebaseFirestore.instance.collection("driver").withConverter(
      fromFirestore: Driver.fromFirestore, toFirestore: (Driver driver, _) => driver.toFirestore());

  void createDriver(Driver driver) {
    _driverRef.add(driver);
  }

}