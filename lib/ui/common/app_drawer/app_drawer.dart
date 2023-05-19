import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/ui/common/app_drawer/app_drawer_provider.dart';
import 'package:ap_lanes/ui/driver/driver_home_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../map_view/map_view_provider.dart';
import '../user_wrapper/user_wrapper_provider.dart';

class AppDrawer extends StatelessWidget {
  final QueryDocumentSnapshot<User>? user;
  final bool isDriverMode;
  final bool isNavigationLocked;
  final void Function() onNavigateWhenLocked;
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  AppDrawer({
    super.key,
    required this.user,
    required this.isDriverMode,
    required this.isNavigationLocked,
    required this.onNavigateWhenLocked,
  });

  Widget getDriverHeaderContent(BuildContext context) {
    final state = Provider.of<DriverHomeProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Text(
        state.driver?.data().licensePlate ?? 'XXX 0000',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: "monospace",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MapViewProvider mapViewState = context.watch<MapViewProvider>();
    final AppDrawerProvider appDrawerState = context.watch<AppDrawerProvider>();

    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: isDriverMode ? 250 : 200,
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
                    if (isDriverMode) {
                      return [getDriverHeaderContent(context)];
                    }
                  }())
                ],
              ),
            ),
          ),
          (() {
            if (isDriverMode) {
              return ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Passenger Mode'),
                  onTap: isNavigationLocked
                      ? () => onNavigateWhenLocked()
                      : () {
                          mapViewState.resetMap();
                          context.read<UserWrapperProvider>().userMode = UserMode.passengerMode;
                        });
            }
            return ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Driver Mode'),
              onTap: isNavigationLocked
                  ? () => onNavigateWhenLocked()
                  : () {
                      mapViewState.resetMap();
                      context.read<UserWrapperProvider>().userMode = UserMode.driverMode;
                    },
            );
          }()),
          const Divider(),
          ListTile(
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
                        ),
                      ),
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
                              appDrawerState.submitFeedback(_feedbackController.text.trim());
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
            leading: const Icon(Icons.bug_report),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () {
                  context.read<AuthService>().signOut();
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
