import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:ap_lanes/data/repo/vehicle_repo.dart';
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
  final _vehicleManufacturerController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final DriverRepo _driverRepo = DriverRepo();
  final VehicleRepo _vehicleRepo = VehicleRepo();
  bool isLoading = false;

  Future<void> registerDriver(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    if (_driverSetupFormKey.currentState!.validate()) {
      String licensePlate = _licensePlateController.text.trim().toUpperCase();
      String vehicleManufacturer = _vehicleManufacturerController.text.trim().toUpperCase();
      String vehicleModel = _vehicleModelController.text.trim().toUpperCase();
      String vehicleColor = _vehicleColorController.text.trim().toUpperCase();
      await _driverRepo.create(
        Driver(
          id: widget.userId,
          isAvailable: false,
          isVerified: false,
        ),
      );

      await _vehicleRepo.create(
        Vehicle(
          licensePlate: licensePlate,
          manufacturer: vehicleManufacturer,
          model: vehicleModel,
          color: vehicleColor,
          driverId: widget.userId
        ),
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
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your vehicle manufacturer';
                }
                return null;
              },
              controller: _vehicleManufacturerController,
              decoration: const InputDecoration(hintText: "Vehicle Manufacturer (e.g. Proton)"),
            ),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your vehicle model';
                }
                return null;
              },
              controller: _vehicleModelController,
              decoration: const InputDecoration(hintText: "Vehicle Model (e.g. x50)"),
            ),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your vehicle color';
                }
                return null;
              },
              controller: _vehicleColorController,
              decoration: const InputDecoration(hintText: "Vehicle Color (e.g. Red)"),
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
