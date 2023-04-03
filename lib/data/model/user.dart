import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  // TODO: Change to first name/last name

  final String id;
  final String userType;
  final String email;
  final String fullName;

  User({
    required this.id,
    required this.userType,
    required this.email,
    required this.fullName
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (userType != null) "userType": userType,
      if (email != null) "email": email,
      if (fullName != null) "fullName": fullName,
    };
  }

  factory User.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return User(
        id: data?['id'],
        userType: data?['userType'],
        email: data?['email'],
        fullName: data?['fullName'],
    );
  }

}