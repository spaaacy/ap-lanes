import 'package:apu_rideshare/data/repo/driver_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/driver.dart';
import '../../data/model/firestore/journey.dart';
import '../../data/model/firestore/user.dart';
import '../../data/repo/user_repo.dart';
import '../../services/auth_service.dart';
import '../auth/auth_wrapper.dart';
import '../common/custom_map.dart';
import '../passenger/passenger_home.dart';
import 'setup_driver_profile_dialog.dart';

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
  late final firebase_auth.User? firebaseUser;
  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Driver>? _driver;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _userRepo
            .getUser(firebaseUser!.uid)
            .then((userData) {
              setState(() {
                _user = userData;
              });
              return userData;
            })
            .then((userData) => _driverRepo.getDriver(userData.get('id')))
            .then((driverData) {
              setState(() {
                _driver = driverData;
                // todo: maybe make this check for ongoing journeys instead
                _isMatchmaking = _driver?.data().isAvailable == true;
              });
            })
            .catchError((e) async {
              var result = await showDialog<String?>(
                context: context,
                builder: (ctx) => SetupDriverProfileDialog(userId: _user!.get('id')),
              );

              if (result == 'Save') {
                var driverSnapshot = await _driverRepo.getDriver(_user?.get('id'));
                setState(() {
                  _driver = driverSnapshot;
                });
              } else {
                if (!context.mounted) return;

                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: const Text('You need to set up a driver profile before you can start driving.'),
                    title: const Text('Driver profile not set up'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop('Ok');
                        },
                        child: const Text('Ok'),
                      ),
                    ],
                  ),
                );

                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const PassengerHome(),
                  ),
                  (_) => false,
                );
              }
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          _user?.data().fullName.characters.first.toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _user?.data().fullName ?? 'Unknown User',
                    style: const TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Passenger Mode'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const PassengerHome(),
                  ),
                  (_) => false,
                );
              },
            ),
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
                  _driverRepo.updateDriver(_driver!, {'isAvailable': !_isMatchmaking});
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
                child: _isMatchmaking
                    ? const Icon(
                        Icons.close,
                        size: 20,
                      )
                    : const Text("GO"),
              ),
            ),
          ),
          TweenAnimationBuilder(
            curve: Curves.bounceInOut,
            duration: const Duration(milliseconds: 250),
            tween: Tween<double>(begin: _isMatchmaking ? 0 : 1, end: _isMatchmaking ? 1 : 0),
            builder: (_, topOffset, w) {
              return Positioned.fill(
                left: 24,
                right: 24,
                top: -200 + (224 * topOffset),
                child: Visibility(
                  visible: topOffset != 0,
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
              );
            },
          )
        ],
      ),
    );
  }
}
