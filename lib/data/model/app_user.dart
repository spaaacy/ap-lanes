import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {

  final String id;
  final String email;
  final String type;

  const AppUser({
    required this.id,
    required this.email,
    required this.type
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (email != null) "email": email,
      if (type != null) "type": type,
    };
  }

  factory AppUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
    ) {
    final data = snapshot.data();
    return AppUser(
      id: data?['id'],
      email: data?['email'],
      type: data?['type']
    );
  }

}