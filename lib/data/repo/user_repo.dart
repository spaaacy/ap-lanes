import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user.dart' as model;


class UserRepo {

  final _userRef = FirebaseFirestore.instance.collection("user").withConverter(
  fromFirestore: model.User.fromFirestore, toFirestore: (model.User user, _) => user.toFirestore());

  void createUser(model.User user) async {
    _userRef.add(user);
  }

  Future<String> getUserType(String id) async {
    final snapshot = await _userRef.where('id', isEqualTo: id).get();
    final firstDoc = snapshot.docs.first;
    final user = firstDoc.data();
    return(user.userType);
  }

  // TODO: Get last name

}