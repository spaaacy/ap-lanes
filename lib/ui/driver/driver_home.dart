import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/ui/passenger/passenger_home.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/user.dart';
import '../../data/repo/user_repo.dart';
import '../../services/auth_service.dart';
import '../common/custom_map.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _isMatchmaking = false;
  Journey? _journey;

  /*
  ` todo:
     1. enable/disable buttons when journey not found
     2. loading when journey not found
  */

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();
    final userRepo = UserRepo();
    final userFuture = userRepo.getUser(firebaseUser!.uid);
    final matchmakingButtonTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Driver"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: FutureBuilder<User>(
                  future: userFuture,
                  builder: (ctx, userSnapshot) => Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  userSnapshot.data?.fullName.characters.first.toUpperCase() ?? '?',
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            userSnapshot.data?.fullName ?? 'Unknown User',
                            style: const TextStyle(color: Colors.white),
                          )
                        ],
                      )),
            ),
            ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Passenger Mode'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const PassengerHome(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                context.read<AuthService>().signOut();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const CustomMap(),
          Positioned.fill(
            bottom: 100.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isMatchmaking = !_isMatchmaking;
                    _journey = Journey(userId: 'swag', startPoint: 'startPoint', destination: 'destination');
                  });
                },
                style: ElevatedButtonTheme.of(context).style?.copyWith(
                      shape: const MaterialStatePropertyAll(CircleBorder()),
                      padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                      elevation: const MaterialStatePropertyAll(6.0),
                    ),
                child: const Text("GO"),
              ),
            ),
          ),
          Visibility(
            visible: _isMatchmaking,
            child: Positioned.fill(
              left: 24,
              right: 24,
              top: 24,
              child: Column(
                children: [
                  Material(
                    elevation: 2,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.transparent),
                      height: 100,
                      child: _journey == null
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: Name Here',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Location: APU',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.red),
                        ),
                        onPressed: _journey == null ? null : () {},
                        child: Text(
                          'REJECT',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.green),
                        ),
                        onPressed: _journey == null ? null : () {},
                        child: Text(
                          'ACCEPT',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
