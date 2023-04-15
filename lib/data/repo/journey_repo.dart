import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/journey.dart';

class JourneyRepo {
  JourneyRepo();

  final _journeyRef = FirebaseFirestore.instance
      .collection("journey")
      .withConverter(
          fromFirestore: Journey.fromFirestore,
          toFirestore: (Journey journey, _) => journey.toFirestore());

  Future<void> createJourney(Journey journey) async {
    _journeyRef.add(journey);
  }

  Future<void> deleteJourney(QueryDocumentSnapshot<Journey>? journey) async {
    journey?.reference.delete();
  }

  void listenForJourney(String userId, Function(QueryDocumentSnapshot<Journey>) onFound) {
    final journeyQuery = _journeyRef.where("userId", isEqualTo: userId).where("isCompleted", isEqualTo: false).snapshots();
    journeyQuery.listen((results) => onFound(results.docs.first));
  }

}
