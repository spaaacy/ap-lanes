import 'package:cloud_firestore/cloud_firestore.dart';

class Passenger {
  final String userId;
  final bool isSearching;

  Passenger({required this.userId, required this.isSearching});

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (isSearching != null) "isSearching": isSearching,
    };
  }

  factory Passenger.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Passenger(
      userId: data?['userId'],
      isSearching: data?['isSearching'],
    );
  }
}
