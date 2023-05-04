import 'dart:async';

import 'package:ap_lanes/data/model/remote/driver.dart';
import 'package:ap_lanes/data/model/remote/journey.dart';
import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/data/repo/user_repo.dart';
import 'package:ap_lanes/services/place_service.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup_state.dart';
import 'package:ap_lanes/ui/driver/components/setup_driver_profile_dialog.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewDriverHomeState extends ChangeNotifier {
  final BuildContext _context;
  late final firebase_auth.User? _firebaseUser;
  late final MapViewState _mapViewState;
  late final JourneyRequestPopupState _journeyRequestPopupState;

  QueryDocumentSnapshot<User>? _user;

  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Driver>? _driver;

  QueryDocumentSnapshot<Driver>? get driver => _driver;

  set driver(QueryDocumentSnapshot<Driver>? value) {
    _driver = value;
    notifyListeners();
  }

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? _activeJourney;

  QueryDocumentSnapshot<Journey>? get activeJourney => _activeJourney;

  set activeJourney(QueryDocumentSnapshot<Journey>? value) {
    _activeJourney = value;
    notifyListeners();
  }

  late final Stream onSearchingStatusChanged;
  late final StreamController<bool> _onSearchingStatusStreamController;

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();

  NewDriverHomeState(this._context) {
    _mapViewState = Provider.of<MapViewState>(_context, listen: false);
    _journeyRequestPopupState = Provider.of<JourneyRequestPopupState>(_context, listen: false);

    _onSearchingStatusStreamController = StreamController();
    onSearchingStatusChanged = _onSearchingStatusStreamController.stream;

    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    _firebaseUser = Provider.of<firebase_auth.User?>(_context, listen: false);
    if (_firebaseUser == null) throw Exception("Firebase user is null!");

    final existingUser = await _userRepo.getUser(_firebaseUser!.uid);
    if (existingUser == null) throw Exception("User profile does not exist!");
    user = existingUser;

    final existingDriver = await _driverRepo.getDriver(_firebaseUser!.uid);
    if (existingDriver != null) {
      driver = existingDriver;
    } else {
      showDriverSetupDialog();
    }
  }

  bool isLoading() {
    return user == null || driver == null;
  }

  void showDriverSetupDialog() async {
    var result = await showDialog<String?>(
      context: _context,
      builder: (ctx) => SetupDriverProfileDialog(userId: _firebaseUser!.uid),
    );

    if (result == 'Save') {
      var driverSnapshot = await _driverRepo.getDriver(_firebaseUser!.uid);
      if (driverSnapshot == null) throw Exception("Driver profile does not exist!");
      driver = driverSnapshot;
      return;
    }

    if (!_context.mounted) return;
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

    if (!_context.mounted) return;
    _context.read<UserWrapperState>().userMode = UserMode.passengerMode;
  }

  void startSearching() async {
    isSearching = true;

    await _driverRepo.updateDriver(driver!, {'isAvailable': true});

    _onSearchingStatusStreamController.add(true);
    // todo: move to journey req state
    _journeyRequestPopupState.fetchInitialJourneys();
  }

  void stopSearching() async {
    isSearching = false;

    await _driverRepo.updateDriver(driver!, {'isAvailable': false});

    _onSearchingStatusStreamController.add(false);
    // todo: move to journey req state
    _journeyRequestPopupState.resetAvailableJourneys();

    clearMapRoute();
  }

  void clearMapRoute() {
    _mapViewState.polylines.clear();
    _mapViewState.markers.remove("start");
    _mapViewState.markers.remove("destination");
    _mapViewState.shouldCenter = true;
    _mapViewState.notifyListeners();

    MapHelper.resetCamera(_mapViewState.mapController, _mapViewState.currentPosition);
  }
}
