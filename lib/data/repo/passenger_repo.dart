import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/passenger.dart';

class PassengerRepo {
  final _passengerRef = FirebaseFirestore.instance
      .collection("passenger")
      .withConverter(
          fromFirestore: Passenger.fromFirestore,
          toFirestore: (passenger, _) => passenger.toFirestore());

  Future<void> createPassenger(Passenger passenger) async {
    _passengerRef.add(passenger);
  }

  Future<QueryDocumentSnapshot<Passenger>?> getPassenger(String userId) async {
    final passenger =
        await _passengerRef.where("id", isEqualTo: userId).limit(1).get();
    if (passenger.size > 0){
      return passenger.docs.first;
    }
    return null;
  }

}
