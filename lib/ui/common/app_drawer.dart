import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/user.dart';
import '../../services/auth_service.dart';
import '../auth/auth_wrapper.dart';
import '../driver/driver_home.dart';
import '../passenger/passenger_home.dart';

class AppDrawer extends StatelessWidget {
  final QueryDocumentSnapshot<User>? user;
  final bool isDriver;

  const AppDrawer({
    super.key,
    required this.user,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
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
                        user?.data().fullName.characters.first.toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
                Text(
                  user?.data().fullName ?? 'Unknown User',
                  style: const TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
          (() {
            if (isDriver) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Passenger Mode'),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const PassengerHome(),
                    ),
                    (_) => false,
                  );
                },
              );
            }
            return ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Driver Mode'),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (BuildContext context) => const DriverHome(),
                ));
              },
            );
          }()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              context.read<AuthService>().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) => AuthWrapper(context: context),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
