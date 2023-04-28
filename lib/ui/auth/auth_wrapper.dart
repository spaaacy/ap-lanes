import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../passenger/passenger_home.dart';
import '../passenger/state/passenger_home_state.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final BuildContext context;

  const AuthWrapper({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return ChangeNotifierProvider<PassengerHomeState>(
        create: (context) {
          return PassengerHomeState()..initialize(context);
        },
        child: const PassengerHome(),
      );
    } else {
      return AuthScreen();
    }
  }
}
