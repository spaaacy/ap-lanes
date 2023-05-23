import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/user.dart' as model;

class UserRepo {
  final _userRef = FirebaseFirestore.instance
      .collection("user")
      .withConverter(fromFirestore: model.User.fromFirestore, toFirestore: (model.User user, _) => user.toFirestore());

  Future<void> create(model.User user) async {
    _userRef.add(user);
  }

  Future<QueryDocumentSnapshot<model.User>?> get(String userId) async {
    final snapshot = await _userRef.where('id', isEqualTo: userId).limit(1).get();
    if (snapshot.size > 0) {
      return snapshot.docs.first;
    }
    return null;
  }
}
