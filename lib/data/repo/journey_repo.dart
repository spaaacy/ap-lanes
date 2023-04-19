import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/journey.dart';

class JourneyRepo {
  JourneyRepo();

  final _journeyRef = FirebaseFirestore.instance
      .collection("journey")
      .withConverter(fromFirestore: Journey.fromFirestore, toFirestore: (Journey journey, _) => journey.toFirestore());

  Future<void> createJourney(Journey journey) async {
    _journeyRef.add(journey);
  }

  Future<void> deleteJourney(QueryDocumentSnapshot<Journey>? journey) async {
    journey?.reference.delete();
  }

  Future<void> updateJourney(QueryDocumentSnapshot<Journey> journey, Map<Object, Object?> updatedValues) async {
    await journey.reference.update(updatedValues);
  }

  StreamSubscription<QuerySnapshot<Journey>> listenForJourney(
    String userId,
    Function(QueryDocumentSnapshot<Journey>) onFound,
  ) {
    final journeyQuery =
        _journeyRef.where("userId", isEqualTo: userId).where("isCompleted", isEqualTo: false).snapshots();
    return journeyQuery.listen((results) {
      if (results.docs.isNotEmpty) {
        onFound(results.docs.first);
      }
    });
  }

  Stream<QuerySnapshot<Journey>> getOngoingJourney(String driverId) {
    return _journeyRef
        .where("driverId", isEqualTo: driverId)
        .where("isCompleted", isEqualTo: false)
        .limit(1)
        .snapshots();
  }

  // todo: paginate this
  Stream<QuerySnapshot<Journey>> getJourneyRequestStream() {
    return _journeyRef.where("driverId", isEqualTo: "").snapshots();
  }
}
