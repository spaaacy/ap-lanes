import 'package:apu_rideshare/data/repo/user_repo.dart';
import 'package:apu_rideshare/ui/passenger/passenger_home.dart';
import 'package:apu_rideshare/ui/user_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {

  final BuildContext context;

  AuthWrapper({required this.context});

  final _userRepo = UserRepo();

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    if (firebaseUser != null) {
      final userType = _userRepo.getUserType(firebaseUser.uid).then((value) => )
      return UserWrapper(userType: userType)
      // return PassengerHome();
    } else {
      return AuthScreen(passwordController: passwordController, emailController: emailController);
    }
  }
}