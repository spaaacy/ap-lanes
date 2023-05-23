import 'dart:async';

import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:ap_lanes/data/repo/vehicle_repo.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DriverVehicleDropdownState extends ChangeNotifier {
  final BuildContext _context;
  final TextEditingController _searchController = TextEditingController();
  late final DriverHomeState _driverHomeState;

  final VehicleRepo _vehicleRepo = VehicleRepo();

  StreamSubscription<QuerySnapshot<Vehicle>>? _vehicleRepoListener;
  QuerySnapshot<Vehicle>? _apuFleet;

  QuerySnapshot<Vehicle>? get apuFleet => _apuFleet;

  DriverVehicleDropdownState(this._context) {
    _driverHomeState = Provider.of<DriverHomeState>(_context, listen: false);
    _vehicleRepoListener = _vehicleRepo.getAPUFleetSnapshots().listen((snap) {
      _apuFleet = snap;
    });
  }

  @override
  void dispose() {
    _vehicleRepoListener?.cancel();
    super.dispose();
  }

  void onVehicleChanged(QueryDocumentSnapshot<Vehicle> suggestion) async {
    if (_driverHomeState.driver == null) {
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text("Driver not found."),
        ),
      );
      return;
    }

    _searchController.text = suggestion.data().licensePlate;
    try {
      await _vehicleRepo.switchToVehicles(_driverHomeState.driver!, suggestion);
      _driverHomeState.vehicle = suggestion;
    } catch (e) {
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text("Driver not found."),
        ),
      );
    }
  }

  FutureOr<Iterable<QueryDocumentSnapshot<Vehicle>>> onQueryChanged(String pattern) {
    if (pattern == '') return _apuFleet?.docs.take(4) ?? [];

    return _apuFleet?.docs.where(
          (e) =>
              e.data().licensePlate.toLowerCase().contains(pattern.toLowerCase()) ||
              e.data().manufacturer.toLowerCase().contains(pattern.toLowerCase()) ||
              e.data().model.toLowerCase().contains(pattern.toLowerCase()) ||
              e.data().color.toLowerCase().contains(pattern.toLowerCase()),
        ) ??
        [];
  }

  TextEditingController get searchController => _searchController;

  void clearVehicleSelection() async {
    if (_driverHomeState.driver == null) return;

    searchController.clear();
    try {
      await _vehicleRepo.clearVehicleSelection(_driverHomeState.driver!);
      _driverHomeState.vehicle = null;
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong."),
        ),
      );
    }
  }
}
