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

  Future<QueryDocumentSnapshot<model.User>?> getUser(String userId) async {
    final snapshot = await _userRef.where('id', isEqualTo: userId).limit(1).get();
    if (snapshot.size > 0){
      return snapshot.docs.first;
    }
    return null;
  }

}
