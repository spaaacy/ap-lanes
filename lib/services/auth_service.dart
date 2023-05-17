import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../data/model/remote/user.dart' as model;
import '../data/repo/user_repo.dart';
import '../util/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  Timer? timer;
  bool isEmailVerified = false;

  void _checkIfEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    }
  }

  AuthService(this._firebaseAuth) {
    if (_firebaseAuth.currentUser?.emailVerified == false) {
      timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkIfEmailVerified();
      });
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  final _userRepo = UserRepo();

  Future<String> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      if (_firebaseAuth.currentUser!.emailVerified) {
        timer?.cancel();
        return signedIn;
      } else {
        return "Verify your email to continue";
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      _registerUser(
          firstName: firstName, lastName: lastName, phoneNumber: phoneNumber);
      sendEmailVerification();
      return signedIn;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "";
    }
  }

  void sendEmailVerification() {
    _firebaseAuth.currentUser?.sendEmailVerification();
  }

  void _registerUser(
      {required String firstName,
      required String lastName,
      required String phoneNumber}) {
    final id = _firebaseAuth.currentUser?.uid;
    final userEmail = _firebaseAuth.currentUser?.email;

    _userRepo.createUser(
      model.User(
        id: id!,
        email: userEmail!,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      ),
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    isEmailVerified = false;
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkIfEmailVerified();
    });
  }
}
