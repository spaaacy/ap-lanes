import 'dart:async';

import 'package:ap_lanes/ui/auth/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/map_view/map_view_state.dart';
import '../common/user_wrapper/user_wrapper.dart';
import '../common/user_wrapper/user_wrapper_state.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final BuildContext context;

  const AuthWrapper({super.key, required this.context});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isEmailVerified = false;
  Timer? timer;


  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        FirebaseAuth.instance.currentUser?;
        {
          isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null && firebaseUser.emailVerified) {
      timer?.cancel();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserWrapperState>(
              create: (context) => UserWrapperState()),
          ChangeNotifierProvider<MapViewState>(
              create: (context) => MapViewState(context))
        ],
        child: const UserWrapper(),
      );
    } else {
      return const LandingPage();
    }
  }
}

