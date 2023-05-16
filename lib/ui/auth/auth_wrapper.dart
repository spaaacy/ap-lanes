import 'dart:async';

import 'package:ap_lanes/services/auth_service.dart';
import 'package:ap_lanes/ui/auth/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/map_view/map_view_state.dart';
import '../common/user_wrapper/user_wrapper.dart';
import '../common/user_wrapper/user_wrapper_state.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final BuildContext context;

  AuthWrapper({super.key, required this.context});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? timer;
  bool isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null && isEmailVerified) {
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
