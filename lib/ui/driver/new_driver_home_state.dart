import 'package:ap_lanes/data/model/remote/driver.dart';
import 'package:ap_lanes/data/model/remote/journey.dart';
import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/data/repo/user_repo.dart';
import 'package:ap_lanes/services/place_service.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/components/setup_driver_profile_dialog.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class NewDriverHomeState extends ChangeNotifier {
  final BuildContext context;
  late final firebase_auth.User? firebaseUser;
  late final MapViewState mapViewState;

  QueryDocumentSnapshot<User>? _user;

  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? _availableJourneyPassenger;

  QueryDocumentSnapshot<User>? get availableJourneyPassenger => _availableJourneyPassenger;

  set availableJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _availableJourneyPassenger = value;
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

  QueryDocumentSnapshot<Journey>? _availableJourney;

  QueryDocumentSnapshot<Journey>? get availableJourney => _availableJourney;

  set availableJourney(QueryDocumentSnapshot<Journey>? value) {
    _availableJourney = value;
    notifyListeners();
  }

  QuerySnapshot<Journey>? _availableJourneys;

  QuerySnapshot<Journey>? get availableJourneys => _availableJourneys;

  set availableJourneys(QuerySnapshot<Journey>? value) {
    _availableJourneys = value;
    notifyListeners();
  }

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();

  NewDriverHomeState(this.context) {
    mapViewState = Provider.of<MapViewState>(context, listen: false);
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
    if (firebaseUser == null) throw Exception("Firebase user is null!");

    final existingUser = await _userRepo.getUser(firebaseUser!.uid);
    if (existingUser == null) throw Exception("User profile does not exist!");
    user = existingUser;

    final existingDriver = await _driverRepo.getDriver(firebaseUser!.uid);
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
      context: context,
      builder: (ctx) => SetupDriverProfileDialog(userId: firebaseUser!.uid),
    );

    if (result == 'Save') {
      var driverSnapshot = await _driverRepo.getDriver(firebaseUser!.uid);
      if (driverSnapshot == null) throw Exception("Driver profile does not exist!");
      driver = driverSnapshot;
      return;
    }

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
    context.read<UserWrapperState>().userMode = UserMode.passengerMode;
  }

  void startSearching() async {
    isSearching = true;

    await _driverRepo.updateDriver(driver!, {'isAvailable': true});

    _availableJourneys = await _journeyRepo.getFirstThreeJourneyRequest(firebaseUser!.uid);

    updateAvailableJourney(availableJourneys!.docs.firstOrNull);
  }

  void stopSearching() async {
    isSearching = false;

    await _driverRepo.updateDriver(driver!, {'isAvailable': false});

    _availableJourney = null;

    _availableJourneyPassenger = null;
    notifyListeners();

    clearMapRoute();
  }

  Future<void> updateAvailableJourney(QueryDocumentSnapshot<Journey>? journey) async {
    _availableJourney = null;
    _availableJourneyPassenger = null;

    _availableJourney = journey;
    if (journey != null) {
      _availableJourneyPassenger = await _userRepo.getUser(journey.data().userId);
      // update journey route polylines
    }
    notifyListeners();
  }

  void clearMapRoute() {
    mapViewState.polylines.clear();
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));
    mapViewState.shouldCenter = true;
    mapViewState.notifyListeners();

    MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition);
  }

  int _currentJourneyIndex = 0;

  // TODO: Test this once Aakif enables MapsAPI
  void onRequestPopupNavigate(RequestNavigationDirection direction) async {
    switch (direction) {
      case RequestNavigationDirection.forward:
        if (_currentJourneyIndex < availableJourneys!.size - 1) {
          _currentJourneyIndex++;
          updateAvailableJourney(availableJourneys!.docs.elementAt(_currentJourneyIndex));
        } else {
          _availableJourneys = await _journeyRepo.getNextJourneyRequest(firebaseUser!.uid, availableJourney!);
          _currentJourneyIndex = 0;
          updateAvailableJourney(availableJourneys!.docs.elementAt(_currentJourneyIndex));
        }
        break;
      case RequestNavigationDirection.backward:
        if (_currentJourneyIndex > 0) {
          _currentJourneyIndex--;
          updateAvailableJourney(availableJourneys!.docs.elementAt(_currentJourneyIndex));
        } else {
          _availableJourneys = await _journeyRepo.getPrevJourneyRequest(firebaseUser!.uid, availableJourney!);
          _currentJourneyIndex = availableJourneys!.size - 1;
          if (_currentJourneyIndex >= 0) {
            updateAvailableJourney(availableJourneys!.docs.elementAt(_currentJourneyIndex));
          }
        }
        break;
    }
    notifyListeners();
  }
}

enum RequestNavigationDirection {
  forward,
  backward,
}
