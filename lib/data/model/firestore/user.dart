import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String userType;
  final String email;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.userType,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (userType != null) "userType": userType,
      if (email != null) "email": email,
      if (firstName != null) "firstName": firstName,
      if (lastName != null) "lastName": lastName,
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
      firstName: data?['firstName'],
      lastName: data?['lastName'],
    );
  }

  String getFullName() {
    return "$firstName $lastName";
  }
}
