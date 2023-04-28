import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/map_view/map_view_state.dart';
import '../common/user_wrapper/user_wrapper.dart';
import '../common/user_wrapper/user_wrapper_state.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final BuildContext context;

  const AuthWrapper({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserWrapperState>(create: (context) => UserWrapperState()),
          ChangeNotifierProvider<MapViewState>(create: (context) => MapViewState()..initialize(context))
        ],
        child: const UserWrapper(),
      );
    } else {
      return AuthScreen();
    }
  }
}
