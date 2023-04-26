import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/remote/driver.dart';
import '../../data/model/remote/feedback.dart' as remote;
import '../../data/model/remote/user.dart';
import '../../data/repo/driver_repo.dart';
import '../../data/repo/feedback_repo.dart';
import '../../services/auth_service.dart';
import '../auth/auth_wrapper.dart';
import '../driver/driver_home.dart';
import '../passenger/passenger_home.dart';

class AppDrawer extends StatelessWidget {
  final QueryDocumentSnapshot<User>? user;
  final bool isDriver;
  final bool isNavigationLocked;
  final void Function() onNavigateWhenLocked;
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  AppDrawer({
    super.key,
    required this.user,
    required this.isDriver,
    required this.isNavigationLocked,
    required this.onNavigateWhenLocked,
  });

  @override
  Widget build(BuildContext context) {
    final DriverRepo driverRepo = DriverRepo();
    final FeedbackRepo feedbackRepo = FeedbackRepo();

    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          user?.data().getFullName().characters.first.toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Text(
                      user?.data().getFullName() ?? 'Unknown User',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ...?(() {
                    if (isDriver) {
                      return [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                          child: FutureBuilder<QueryDocumentSnapshot<Driver>?>(
                              future: driverRepo.getDriver(user!.data().id),
                              builder: (context, driverSnapshot) {
                                return Text(
                                  driverSnapshot.data?.get('licensePlate') ?? '??? ????',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: "monospace",
                                  ),
                                );
                              }),
                        )
                      ];
                    } else {
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: const Text('   '),
                      );
                    }
                  }())
                ],
              ),
            ),
          ),
          (() {
            if (isDriver) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Passenger Mode'),
                onTap: isNavigationLocked
                    ? () => onNavigateWhenLocked()
                    : () {
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
              onTap: isNavigationLocked
                  ? () => onNavigateWhenLocked()
                  : () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (BuildContext context) => const DriverHome(),
                      ));
                    },
            );
          }()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              context.read<AuthService>().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) => AuthWrapper(context: context),
                ),
              );
            },
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("What would you like to report?"),
                            content: Form(
                                key: _feedbackFormKey,
                                child: TextFormField(
                                  decoration: const InputDecoration(hintText: "Report an issue"),
                                  controller: _feedbackController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Cannot submit empty feedback!";
                                    }
                                    return null;
                                  },
                                )),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, "Cancel");
                                },
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_feedbackFormKey.currentState!.validate()) {
                                    feedbackRepo
                                        .createFeedback(remote.Feedback(feedback: _feedbackController.text.trim()));
                                    Navigator.pop(context, "Send");
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text("Send"),
                                  ],
                                ),
                              ),
                            ],
                          );
                        });
                  },
                  title: const Text("Report an Issue"),
                  leading: const Icon(Icons.bug_report)),
            ),
          )
        ],
      ),
    );
  }
}
