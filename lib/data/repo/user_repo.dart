import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';

import '../model/firestore/user.dart' as model;

class UserRepo {
  final _userRef = FirebaseFirestore.instance.collection("user").withConverter(
      fromFirestore: model.User.fromFirestore,
      toFirestore: (model.User user, _) => user.toFirestore());

  Future<void> createUser(model.User user) async {
    _userRef.add(user);
  }

  Future<QueryDocumentSnapshot<model.User>> getUser(String userId) async {
    final snapshot = await _userRef.where('id', isEqualTo: userId).get();
    return snapshot.docs.first;
  }

  Future<String> getUserType(String userId) async {
    final user = await getUser(userId);
    return user.get("userType");
  }

  Future<String> getLastName(String userId) async {
    final user = await getUser(userId);
    return user.get("lastName");
  }

}
