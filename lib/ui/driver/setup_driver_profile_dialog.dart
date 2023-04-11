import 'package:apu_rideshare/data/model/firestore/driver.dart';
import 'package:apu_rideshare/data/repo/driver_repo.dart';
import 'package:apu_rideshare/util/ui_helper.dart' as ui_helper;
import 'package:flutter/material.dart';

class SetupDriverProfileDialog extends StatelessWidget {
  final String userId;

  SetupDriverProfileDialog({super.key, required this.userId});

  final _driverSetupFormKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final DriverRepo _driverRepo = DriverRepo();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Driver Setup'),
      content: Form(
        key: _driverSetupFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
              controller: _licensePlateController,
              decoration: const InputDecoration(hintText: "Car License Plate"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop('Cancel');
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_driverSetupFormKey.currentState!.validate()) {
              ui_helper.showLoaderDialog(context, 'Loading...');
              String licensePlate = _licensePlateController.text.trim();
              await _driverRepo.createDriver(Driver(id: userId, licensePlate: licensePlate, isAvailable: false));

              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop('Save');
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
