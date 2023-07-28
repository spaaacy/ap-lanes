import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  // final String customerId;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    // required this.customerId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) "id": id,
      if (email != null) "email": email,
      if (firstName != null) "firstName": firstName,
      if (lastName != null) "lastName": lastName,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
      // if (customerId != null) "customerId": customerId,
    };
  }

  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return User(
      id: data?['id'],
      email: data?['email'],
      firstName: data?['firstName'],
      lastName: data?['lastName'],
      phoneNumber: data?['phoneNumber'],
      // customerId: data?['customerId'],
    );
  }

  String getFullName() {
    return "$firstName $lastName";
  }
}
