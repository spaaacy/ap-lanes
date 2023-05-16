import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../data/model/remote/user.dart' as model;
import '../data/repo/user_repo.dart';
import '../util/constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  final _userRepo = UserRepo();

  Future<String> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      if (_firebaseAuth.currentUser!.emailVerified) {
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
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _firebaseAuth.currentUser?.sendEmailVerification();
    }
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
  }
}
