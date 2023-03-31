import 'package:firebase_auth/firebase_auth.dart';

import '../data/model/app_user.dart';
import '../data/repo/user_repo.dart';
import '../util/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  final _userRepo = UserRepo();

  Future<String> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      // final userId = _firebaseAuth.currentUser?.uid;
      // _userRepo.createUser(AppUser(id: userId, email: email, type: PASSENGER));

      return SIGNED_IN;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  Future<String> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      final userId = _firebaseAuth.currentUser?.uid;

      // Uncomment when looking to register a driver
      // _userRepo.createUser(AppUser(id: userId!, email: email, type: DRIVER));
      _userRepo.createUser(AppUser(id: userId!, email: email, type: PASSENGER));

      return SIGNED_IN;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

