import 'package:apu_rideshare/data/repo/driver_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/model/firestore/driver.dart';
import '../data/model/firestore/user.dart' as model;
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

      _registerUser(); // Temporary

      return SIGNED_IN;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  Future<String> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      _registerUser();
      return SIGNED_IN;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  void _registerUser() {
    final userId = _firebaseAuth.currentUser?.uid;
    final userEmail = _firebaseAuth.currentUser?.email;
    _userRepo.createUser(model.User(id: userId!, userType: PASSENGER, email: userEmail!, fullName: "FirstName LastName"));

    // Temporary
    // final driverRepo = DriverRepo();
    // driverRepo.createDriver(Driver(id: userId!, licensePlate: "ABC1234", isAvailable: false));
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

