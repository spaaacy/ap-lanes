import 'package:cloud_firestore/cloud_firestore.dart';

class User {
/*
  final String userId;
  final String userType;
  final String email;
  final String firstName;
  final String lastName;

  User({required this.userId, required this.userType, required this.email, required this.firstName, required this.lastName});

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
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
      userId: data?['userId'],
      userType: data?['userType'],
      email: data?['email'],
      firstName: data?['firstName'],
      lastName: data?['lastName'],
    );
  }
*/
  final String userId;
  final String userType;
  final String email;
  final String fullName;

  User(
      {required this.userId,
      required this.userType,
      required this.email,
      required this.fullName});

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
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
      userId: data?['userId'],
      userType: data?['userType'],
      email: data?['email'],
      fullName: data?['fullName'],
    );
  }
}
