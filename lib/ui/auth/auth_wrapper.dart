import 'package:apu_rideshare/ui/passenger/passenger_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final BuildContext context;

  const AuthWrapper({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return const PassengerHome();
    } else {
      return AuthScreen();
    }
  }
}
