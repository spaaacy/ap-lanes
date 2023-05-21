import 'package:ap_lanes/services/auth_service.dart';
import 'package:ap_lanes/ui/auth/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/map_view/map_view_state.dart';
import '../common/user_wrapper/user_wrapper.dart';
import '../common/user_wrapper/user_wrapper_state.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final authService = context.watch<AuthService>();

    if (firebaseUser != null && authService.isEmailVerified) {
      authService.timer?.cancel();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserWrapperState>(
              create: (context) => UserWrapperState()),
          ChangeNotifierProvider<MapViewState2>(
              create: (context) => MapViewState2(context))
        ],
        child: const UserWrapper(),
      );
    } else {
      return const LandingPage();
    }
  }
}