import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/app_user.dart';

class UserRepo {

  final _userRef = FirebaseFirestore.instance.collection("user").withConverter(
  fromFirestore: AppUser.fromFirestore, toFirestore: (AppUser appUser, _) => appUser.toFirestore());

  void createUser(AppUser user) {
    _userRef.add(user);
  }

  Future<String> getUserType(String id) async {
    final snapshot = await _userRef.where('id', isEqualTo: id).get();
    final firstDoc = snapshot.docs.first;
    final user = firstDoc.data();
    return user.type;
  }

}