import 'package:apu_rideshare/ui/user_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {

  final BuildContext context;

  AuthWrapper({required this.context});


  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return UserWrapper(userId: firebaseUser.uid);
    } else {
      return AuthScreen();
    }
  }
}