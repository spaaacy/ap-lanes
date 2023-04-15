import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/passenger.dart';

class PassengerRepo {
  final _passengerRef = FirebaseFirestore.instance
      .collection("passenger")
      .withConverter(
          fromFirestore: Passenger.fromFirestore,
          toFirestore: (passenger, _) => passenger.toFirestore());

  Future<void> createPassenger(Passenger passenger) async {
    _passengerRef.add(passenger);
  }

  Future<QueryDocumentSnapshot<Passenger>> getPassenger(String userId) async {
    final passenger =
        await _passengerRef.where("id", isEqualTo: userId).get();
    return passenger.docs.first;
  }

  Future<void> updateIsSearching(QueryDocumentSnapshot<Passenger> passenger,
      bool isSearching) async {
    passenger.reference.update({"isSearching": isSearching});
  }

}
