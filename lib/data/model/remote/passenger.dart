import 'package:cloud_firestore/cloud_firestore.dart';

class Passenger {
  final String id;
  final bool isSearching;

  Passenger({required this.id, this.isSearching = false});

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (isSearching != null) "isSearching": isSearching,
    };
  }

  factory Passenger.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Passenger(
      id: data?['id'],
      isSearching: data?['isSearching'],
    );
  }
}
