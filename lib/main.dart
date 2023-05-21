import 'dart:async';

import 'package:ap_lanes/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'color_schemes.g.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'ui/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FlutterMapTileCaching.initialise();
  await dotenv.load(fileName: 'assets/.env');
  Stripe.publishableKey = dotenv.env['STRIPE_TEST_PUBLISHABLE']!;
  await Stripe.instance.applySettings();
  FMTC.instance('mapStore').manage.create();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialized here to access context
    NotificationService().initialize(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(FirebaseAuth.instance),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: "AP Lanes",
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        theme: ThemeData(
          useMaterial3: true, colorScheme: lightColorScheme,
          scaffoldBackgroundColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButtonTheme.of(context).style,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
