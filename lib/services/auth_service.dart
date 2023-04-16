import 'package:apu_rideshare/data/model/firestore/passenger.dart';
import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/model/firestore/user.dart' as model;
import '../data/repo/user_repo.dart';
import '../util/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  final _userRepo = UserRepo();
  final _passengerRepo = PassengerRepo();

  Future<String> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      // _registerUser(); // Temporary

      return signedIn;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      _registerUser(firstName: firstName, lastName: lastName);
      return signedIn;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  void _registerUser({required String firstName, required String lastName}) {
    final id = _firebaseAuth.currentUser?.uid;
    final userEmail = _firebaseAuth.currentUser?.email;
    _userRepo.createUser(
      model.User(
        id: id!,
        userType: passenger,
        email: userEmail!,
        fullName: "$firstName $lastName",
      ),
    );

    _passengerRepo.createPassenger(Passenger(id: id));
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
