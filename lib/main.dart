import 'package:apu_rideshare/firebase_options.dart';
import 'package:apu_rideshare/services/authentication_service.dart';
import 'package:apu_rideshare/ui/auth/authentication_screen.dart';
import 'package:apu_rideshare/ui/auth/sign_up_screen.dart';
import 'package:apu_rideshare/ui/passenger/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(create: (_) => AuthenticationService(FirebaseAuth.instance)),

        StreamProvider<User?>(
          create: (context) => context.read<AuthenticationService>().authStateChanges, initialData: null,
        )
      ],
        child: MaterialApp(
          title: "AP Ride",
          theme: ThemeData(backgroundColor: Colors.blue),
          home: (AuthenticationWrapper()
      ))
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    if (firebaseUser != null) {
      return HomeScreen();
    } else {
      return AuthenticationScreen(passwordController: passwordController, emailController: emailController);
    }
  }
}