import 'package:cloud_firestore/cloud_firestore.dart';

class Passenger {
  final String id;

  Passenger({required this.id});

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
    };
  }

  factory Passenger.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Passenger(
      id: data?['id'],
    );
  }
}
