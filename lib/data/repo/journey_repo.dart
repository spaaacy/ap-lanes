import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/firestore/journey.dart';

class JourneyRepo {
  JourneyRepo();

  final _journeyRef = FirebaseFirestore.instance
      .collection("journey")
      .withConverter(
          fromFirestore: Journey.fromFirestore,
          toFirestore: (Journey journey, _) => journey.toFirestore());

  void createJourney(Journey journey) {
    _journeyRef.add(journey);
  }
}
