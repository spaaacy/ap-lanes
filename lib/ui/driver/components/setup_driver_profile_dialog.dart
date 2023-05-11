import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/model/remote/driver.dart';
import '../../../data/repo/driver_repo.dart';

class SetupDriverProfileDialog extends StatefulWidget {
  final String userId;

  const SetupDriverProfileDialog({Key? key, required this.userId}) : super(key: key);

  @override
  State<SetupDriverProfileDialog> createState() => _SetupDriverProfileDialogState();
}

class _SetupDriverProfileDialogState extends State<SetupDriverProfileDialog> {
  final _driverSetupFormKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final DriverRepo _driverRepo = DriverRepo();
  bool isLoading = false;

  Future<void> registerDriver(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    if (_driverSetupFormKey.currentState!.validate()) {
      String licensePlate = _licensePlateController.text.trim().toUpperCase();
      await _driverRepo.createDriver(
        Driver(id: widget.userId, licensePlate: licensePlate, isAvailable: false, isVerified: false),
      );

      if (context.mounted) {
        Navigator.of(context).pop('Save');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

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
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your car license plate';
                }
                if (value.length > 9) {
                  return 'Your license plate is too long';
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
          onPressed: isLoading ? null : () => Navigator.of(context).pop('Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading ? null : () => registerDriver(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
