import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/journey.dart';

class JourneyRepo {
  JourneyRepo();

  final _firestoreInstance = FirebaseFirestore.instance;

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

  Stream<QuerySnapshot<Journey>> listenForJourney(String userId) {
    return _journeyRef
        .where("userId", isEqualTo: userId)
        .where("isCompleted", isEqualTo: false)
        .where("isCancelled", isEqualTo: false)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Journey>> getOngoingJourneyStream(String driverId) {
    return _journeyRef
        .where("driverId", isEqualTo: driverId)
        .where("isCompleted", isEqualTo: false)
        .where("isCancelled", isEqualTo: false)
        .limit(1)
        .snapshots();
  }

  Future<bool> hasOngoingJourney(String driverId) async {
    final ongoingJourneySnapshots = await _journeyRef
        .where("driverId", isEqualTo: driverId)
        .where("isCompleted", isEqualTo: false)
        .where("isCancelled", isEqualTo: false)
        .limit(1)
        .get();
    return ongoingJourneySnapshots.size > 0;
  }

  Query<Journey> getDefaultJourneyQuery(String driverId) {
    return _journeyRef
        .where("driverId", isEqualTo: "")
        .where("userId", isNotEqualTo: driverId)
        .orderBy("userId")
        .where("isCompleted", isEqualTo: false)
        .where("isCancelled", isEqualTo: false)
        .orderBy("createdAt", descending: false);
  }

  Stream<QuerySnapshot<Journey>> getFirstJourneyRequest(String driverId) {
    return getDefaultJourneyQuery(driverId).limit(3).snapshots();
  }

  Future<QuerySnapshot<Journey>> getNextJourneyRequest(String driverId, DocumentSnapshot<Journey> lastVisible) {
    return getDefaultJourneyQuery(driverId).startAfterDocument(lastVisible).limit(3).get();
  }

  Future<QuerySnapshot<Journey>> getPrevJourneyRequest(String driverId, DocumentSnapshot<Journey> lastVisible) {
    return getDefaultJourneyQuery(driverId).endBeforeDocument(lastVisible).limitToLast(3).get();
  }

  Future<void> cancelJourneyAsPassenger(QueryDocumentSnapshot<Journey> journey) async {
    await _firestoreInstance.runTransaction((transaction) async {
      final snapshot = await transaction.get(journey.reference);
      if (snapshot.data()?.isPickedUp != true) {
        journey.reference.update({"isCancelled": true});
      } else {
        throw Exception("Cannot cancel after picking up.");
      }
    });
  }

  Future<void> completeJourney(DocumentSnapshot<Journey>? activeJourney) {
    return _firestoreInstance.runTransaction((transaction) async {
      if (activeJourney == null) return;

      var ss = await transaction.get<Journey>(activeJourney.reference);
      if (!ss.exists) {
        throw Exception("Error occurred when trying to update drop-off status of given Journey.");
      }

      if (ss.data()!.isCompleted) {
        throw Exception("Cannot update drop-off status of completed Journey.");
      }

      transaction.update(ss.reference, {'isCompleted': true, 'isPickedUp': true});
    });
  }

  Future<bool> updateJourneyPickUpStatus(DocumentSnapshot<Journey>? activeJourney) {
    return _firestoreInstance.runTransaction((transaction) async {
      if (activeJourney == null) throw Exception('Active journey provided is null.');

      var ss = await transaction.get<Journey>(activeJourney.reference);
      if (!ss.exists) {
        throw Exception("Error occurred when trying to update picked-up status of given Journey.");
      }

      if (ss.data()!.isCompleted) {
        throw Exception("Cannot update picked-up status of completed Journey.");
      }

      if (ss.data()!.isPickedUp) {
        transaction.update(ss.reference, {'isPickedUp': false});
        return false;
      } else {
        transaction.update(ss.reference, {'isPickedUp': true});
        return true;
      }
    });
  }

  Future<DocumentSnapshot<Journey>?> acceptJourneyRequest(DocumentSnapshot<Journey> acceptedJourney, String userId) {
    return _firestoreInstance.runTransaction((transaction) async {
      var ss = await transaction.get<Journey>(acceptedJourney.reference);
      if (!ss.exists) {
        throw Exception("Journey does not exist!");
      }

      if (ss.data()!.isCompleted || ss.data()!.driverId.isNotEmpty) {
        throw Exception("Journey already has a driver!");
      }

      transaction.update(ss.reference, {'driverId': userId});

      return ss;
    });
  }
}
