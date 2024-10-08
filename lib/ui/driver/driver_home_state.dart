import 'dart:async';

import 'package:ap_lanes/data/model/remote/driver.dart';
import 'package:ap_lanes/data/model/remote/journey.dart';
import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/data/repo/user_repo.dart';
import 'package:ap_lanes/data/repo/vehicle_repo.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/components/setup_driver_profile_dialog.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum DriverState {
  idle,
  searching,
  ongoing,
}

class DriverHomeState extends ChangeNotifier {
  final BuildContext _context;
  late final firebase_auth.User? _firebaseUser;
  late final MapViewState2 _mapViewState;

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Driver>? _driver;
  QueryDocumentSnapshot<Vehicle>? _vehicle;

  DriverState _driverState = DriverState.idle;

  late final StreamController<MapEntry<DriverState, dynamic>> _onDriverStateStreamController;
  late final Stream<MapEntry<DriverState, dynamic>> onDriverStateChanged;

  late final StreamController<QueryDocumentSnapshot<Journey>?> _onJourneyRequestAcceptedStreamController;
  late final Stream<QueryDocumentSnapshot<Journey>?> onJourneyRequestAccepted;

  StreamSubscription<QuerySnapshot<Vehicle>>? _vehicleListener;

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _vehicleRepo = VehicleRepo();


  DriverHomeState(this._context) {
    handleAdditionalLocationPermission(_context);

    _onDriverStateStreamController = StreamController.broadcast();
    onDriverStateChanged = _onDriverStateStreamController.stream;

    _onJourneyRequestAcceptedStreamController = StreamController();
    onJourneyRequestAccepted = _onJourneyRequestAcceptedStreamController.stream;

    _mapViewState = Provider.of<MapViewState2>(_context, listen: false);
    initializeFirebase();
  }

  @override
  void dispose() async {
    super.dispose();

    await _onDriverStateStreamController.close();
    await _onJourneyRequestAcceptedStreamController.close();
    await _vehicleListener?.cancel();
  }

  Future<void> initializeFirebase() async {
    _firebaseUser = Provider.of<firebase_auth.User?>(_context, listen: false);
    if (_firebaseUser == null) throw Exception("Firebase user is null!");

    final existingUser = await _userRepo.get(_firebaseUser!.uid);
    if (existingUser == null) throw Exception("User profile does not exist!");
    user = existingUser;

    final existingDriver = await _driverRepo.get(_firebaseUser!.uid);
    if (existingDriver != null) {
      driver = existingDriver;
    } else {
      final setupResult = await showDriverSetupDialog();
      if (setupResult == false) {
        _context.read<UserWrapperState>().userMode = UserMode.passengerMode;
        return;
      }
    }

    if (!driver!.data().isVerified) {
      if (_context.mounted) {
        await showDialog(
          context: _context,
          builder: (context) => AlertDialog(
            title: const Text("Awaiting Verification"),
            content: const Text(
              "You have already setup your driver profile. However, we still need to verify your identity. Until your account gets verified, you are unable to start driving.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text("Ok"),
              )
            ],
          ),
        );
      }
      if (!_context.mounted) return;
      _context.read<UserWrapperState>().userMode = UserMode.passengerMode;
      return;
    }

    _vehicleListener = _vehicleRepo.snapshots(driver!.data().id)?.listen((snap) {
      if (snap.size > 0) {
        vehicle = snap.docs.first;
      } else {
        vehicle = null;
      }
    });

    final hasPreviousOngoingJourney = await _journeyRepo.hasOngoingJourney(_firebaseUser!.uid);
    if (hasPreviousOngoingJourney) {
      didAcceptJourneyRequest(null);
    }
  }

  bool isLoading() {
    return user == null || driver == null;
  }

  Future<bool> showDriverSetupDialog() async {
    var result = await showDialog<String?>(
      context: _context,
      builder: (ctx) => SetupDriverProfileDialog(userId: _firebaseUser!.uid),
    );

    if (result == 'Save') {
      var driverSnapshot = await _driverRepo.get(_firebaseUser!.uid);
      if (driverSnapshot == null) throw Exception("Driver profile does not exist!");
      driver = driverSnapshot;
      return true;
    }

    if (!_context.mounted) return false;
    await showDialog(
      context: _context,
      builder: (ctx) => AlertDialog(
        content: const Text('You need to set up a driver profile before you can start driving.'),
        title: const Text('Driver profile not set up'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(_context).pop('Ok');
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );

    return false;
  }

  void startSearching() async {
    if (vehicle == null) {
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text("No vehicle selected. Please choose one using the search bar above."),
        ),
      );
      return;
    }

    _driverState = DriverState.searching;

    await _driverRepo.update(driver!, {'isAvailable': true});

    _onDriverStateStreamController.add(const MapEntry(DriverState.searching, null));
    notifyListeners();
  }

  void stopSearching() async {
    _driverState = DriverState.idle;

    await _driverRepo.update(driver!, {'isAvailable': false});

    _onDriverStateStreamController.add(const MapEntry(DriverState.idle, null));

    clearMapRoute();

    notifyListeners();
  }

  void clearMapRoute() {
    _mapViewState.polylines.clear();
    _mapViewState.markers.remove("start");
    _mapViewState.markers.remove("destination");
    _mapViewState.shouldCenter = true;
    _mapViewState.notifyListeners();

    _mapViewState.resetCamera();
  }

  void didAcceptJourneyRequest(QueryDocumentSnapshot<Journey>? acceptedJourneyRequest) {
    _driverState = DriverState.ongoing;
    _onDriverStateStreamController.add(const MapEntry(DriverState.ongoing, null));
    _onJourneyRequestAcceptedStreamController.add(acceptedJourneyRequest);
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Driver>? get driver => _driver;

  set driver(QueryDocumentSnapshot<Driver>? value) {
    _driver = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Vehicle>? get vehicle => _vehicle;

  set vehicle(QueryDocumentSnapshot<Vehicle>? value) {
    _vehicle = value;
    notifyListeners();
  }

  DriverState get driverState => _driverState;

  set driverState(DriverState value) {
    _driverState = value;
    notifyListeners();
  }

  MapViewState2 get mapViewState => _mapViewState;
}
