import 'package:apu_rideshare/firebase_options.dart';
import 'package:apu_rideshare/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'ui/auth/auth_wrapper.dart';

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
        Provider<AuthService>(create: (_) => AuthService(FirebaseAuth.instance)),

        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges, initialData: null,
        )
      ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "AP Ride", // TODO: Check if this is necessary
          theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: Colors.white, primaryColor: Colors.black),
          home: AuthWrapper(context: context)
      )
    );
  }
}