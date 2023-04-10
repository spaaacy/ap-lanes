import 'package:apu_rideshare/data/model/firestore/user.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:apu_rideshare/ui/driver/driver_home.dart';
import 'package:apu_rideshare/ui/passenger/components/search_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repo/user_repo.dart';
import '../../services/auth_service.dart';
import '../../util/greeting.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();
    final userRepo = UserRepo();
    final userFuture = userRepo.getUser(firebaseUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Greeting.getGreeting(),
        ),
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
              title: const Text('Driver Mode'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const DriverHome(),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: SearchTextField(controller: _searchController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
