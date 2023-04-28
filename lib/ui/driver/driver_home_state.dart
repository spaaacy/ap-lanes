import 'dart:async';
import 'dart:isolate';

import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/components/setup_driver_profile_dialog.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/model/remote/driver.dart';
import '../../../data/model/remote/journey.dart';
import '../../../data/model/remote/user.dart';
import '../../../data/repo/driver_repo.dart';
import '../../../data/repo/journey_repo.dart';
import '../../../data/repo/user_repo.dart';
import '../../../services/place_service.dart';

class DriverHomeState extends ChangeNotifier {
  late final MapViewState mapViewState;
  late final BuildContext context;
  firebase_auth.User? firebaseUser;

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<User>? _activeJourneyPassenger;
  QueryDocumentSnapshot<Driver>? _driver;
  QueryDocumentSnapshot<Journey>? _activeJourney;
  QueryDocumentSnapshot<Journey>? _availableJourneySnapshot;
  QueryDocumentSnapshot<User>? _availableJourneyPassenger;

  StreamSubscription<QuerySnapshot<Journey>>? _activeJourneyListener;
  StreamSubscription<Position>? _driverLocationListener;

  bool _isSearching = false;

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();
  bool _isLocationUpdaterIsolateStarting = false;
  Isolate? _locationUpdaterIsolate;

  @override
  void dispose() async {
    super.dispose();
    await _activeJourneyListener?.cancel();
    await _driverLocationListener?.cancel();
    stopLocationUpdaterIsolate();
  }

  //region getters and setters
  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get activeJourneyPassenger => _activeJourneyPassenger;

  set activeJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _activeJourneyPassenger = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Driver>? get driver => _driver;

  set driver(QueryDocumentSnapshot<Driver>? value) {
    _driver = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get activeJourney => _activeJourney;

  set activeJourney(QueryDocumentSnapshot<Journey>? value) {
    _activeJourney = value;
    notifyListeners();
  }

  bool get isSearching => _isSearching;

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get availableJourneySnapshot => _availableJourneySnapshot;

  set availableJourneySnapshot(QueryDocumentSnapshot<Journey>? value) {
    _availableJourneySnapshot = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get availableJourneyPassenger => _availableJourneyPassenger;

  set availableJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _availableJourneyPassenger = value;
    notifyListeners();
  }

  StreamSubscription<QuerySnapshot<Journey>>? get activeJourneyListener => _activeJourneyListener;

  set activeJourneyListener(StreamSubscription<QuerySnapshot<Journey>>? value) {
    _activeJourneyListener = value;
    notifyListeners();
  }

  double get routeDistance => MapHelper.calculateRouteDistance(mapViewState.polylines.firstOrNull);

  //endregion

  Future<void> initialize(BuildContext context) async {
    this.context = context;
    initializeFirestore();
  }

  Future<void> locationListenerCallback() async {
    _driverLocationListener = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);

      LatLng targetLatLng =
          _activeJourney!.data().isPickedUp ? _activeJourney!.data().endLatLng : _activeJourney!.data().startLatLng;
      updateCameraBoundsWithPopup(latLng, targetLatLng);
    });
  }

  void updateCameraBoundsWithPopup(LatLng start, LatLng end) {
    MapHelper.setCameraBetweenMarkers(
      mapController: mapViewState.mapController,
      firstLatLng: start,
      secondLatLng: end,
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
  }

  Future<void> initializeFirestore() async {
    firebaseUser = context.read<firebase_auth.User?>();
    if (firebaseUser == null) return;
    startOngoingJourneyListener();

    var userData = await _userRepo.getUser(firebaseUser!.uid);
    user = userData;

    var driverData = await _driverRepo.getDriver(firebaseUser!.uid);
    if (driverData != null) {
      driver = driverData;
      // todo: maybe make this check for ongoing journeys instead
      isSearching = _driver?.data().isAvailable == true;

      updateJourneyRequestListener();
    } else {
      if (!context.mounted) return;

      var result = await showDialog<String?>(
        context: context,
        builder: (ctx) => SetupDriverProfileDialog(userId: firebaseUser!.uid),
      );

      if (result == 'Save') {
        var driverSnapshot = await _driverRepo.getDriver(firebaseUser!.uid);
        driver = driverSnapshot;
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
        context.read<UserWrapperState>().userMode = UserMode.passengerMode;
      }
    }
  }

  void stopLocationUpdaterIsolate() {
    if (_locationUpdaterIsolate != null) {
      _locationUpdaterIsolate?.kill();
      _locationUpdaterIsolate = null;
    }
  }

  void startLocationUpdaterIsolate() async {
    if (_isLocationUpdaterIsolateStarting) {
      // An isolate is already being spawned; no need to do anything.
      return;
    }

    stopLocationUpdaterIsolate();

    _isLocationUpdaterIsolateStarting = true;
    try {
      _locationUpdaterIsolate = await Isolate.spawn((message) {
        Timer.periodic(const Duration(seconds: 15), (Timer t) async {
          if (driver == null) return;
          var pos = await Geolocator.getCurrentPosition();
          _driverRepo.updateDriver(driver!, {'currentLatLng': '${pos.latitude}, ${pos.longitude}'});
        });
      }, null);
    } finally {
      _isLocationUpdaterIsolateStarting = false;
    }
  }

  void startOngoingJourneyListener() async {
    await activeJourneyListener?.cancel();

    activeJourneyListener = _journeyRepo.getOngoingJourney(firebaseUser!.uid).listen((ss) async {
      if (ss.size > 0) {
        if (_locationUpdaterIsolate == null) {
          startLocationUpdaterIsolate();
        }
        activeJourney = ss.docs.first;

        activeJourneyPassenger = await _userRepo.getUser(_activeJourney!.data().userId);

        if (_activeJourney!.data().isPickedUp) {
          mapViewState.markers[const MarkerId("drop-off")] = Marker(
            markerId: const MarkerId("drop-off"),
            position: _activeJourney!.data().endLatLng,
            icon: mapViewState.locationIcon!,
          );
          updateCameraBoundsWithPopup(mapViewState.currentPosition!, _activeJourney!.data().endLatLng);
        } else {
          mapViewState.markers[const MarkerId("pick-up")] = Marker(
            markerId: const MarkerId("pick-up"),
            position: _activeJourney!.data().startLatLng,
            icon: mapViewState.locationIcon!,
          );
          updateCameraBoundsWithPopup(mapViewState.currentPosition!, _activeJourney!.data().startLatLng);
        }
      } else {
        if (_locationUpdaterIsolate != null) {
          stopLocationUpdaterIsolate();
        }
        if (_activeJourney != null) {
          var previousJourney = await _activeJourney!.reference.get();
          if (previousJourney.exists && previousJourney.data()!.isCancelled) {
            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Journey Cancelled"),
                  content: const Text("The journey has been cancelled by the passenger."),
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
          }
        }
        mapViewState.markers.remove(const MarkerId("drop-off"));
        mapViewState.markers.remove(const MarkerId("pick-up"));
        activeJourney = null;
      }
    });
  }

  void onJourneyDropOff() async {
    bool? shouldDropOff = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Confirm Drop-off?"),
            content: const Text('Are you sure you want to mark this journey as complete?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          );
        });

    if (shouldDropOff == null || shouldDropOff == false) {
      return;
    }

    try {
      await _journeyRepo.completeJourney(activeJourney);
      await _activeJourneyListener?.cancel();

      mapViewState.markers.remove(const MarkerId("drop-off"));
      mapViewState.markers.remove(const MarkerId("pick-up"));
      activeJourney = null;

      MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    }
  }

  void onJourneyPickUp() async {
    try {
      bool isPickedUp = await _journeyRepo.updateJourneyPickUpStatus(activeJourney);
      if (isPickedUp) {
        mapViewState.markers.remove(const MarkerId("pick-up"));
        mapViewState.markers[const MarkerId("pick-up")] = Marker(
          markerId: const MarkerId("pick-up"),
          position: activeJourney!.data().endLatLng,
          icon: mapViewState.locationIcon!,
        );
        updateCameraBoundsWithPopup(mapViewState.currentPosition!, activeJourney!.data().endLatLng);
      } else {
        mapViewState.markers.remove(const MarkerId("drop-off"));
        mapViewState.markers[const MarkerId("pick-up")] = Marker(
          markerId: const MarkerId("pick-up"),
          position: activeJourney!.data().startLatLng,
          icon: mapViewState.locationIcon!,
        );
        updateCameraBoundsWithPopup(mapViewState.currentPosition!, activeJourney!.data().startLatLng);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  void onJourneyAccept() async {
    try {
      await _journeyRepo.acceptJourneyRequest(_availableJourneySnapshot!, firebaseUser!.uid);

      toggleIsSearching();

      mapViewState.polylines.clear();
      mapViewState.markers.remove(const MarkerId("start"));
      mapViewState.markers.remove(const MarkerId("destination"));

      startOngoingJourneyListener();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void onRequestPopupNavigate(int direction) async {
    QuerySnapshot<Journey> newJourneyRequest;
    if (direction == 1) {
      newJourneyRequest = await _journeyRepo.getNextJourneyRequest(
        firebaseUser!.uid,
        _availableJourneySnapshot!,
      );
    } else {
      newJourneyRequest = await _journeyRepo.getPrevJourneyRequest(
        firebaseUser!.uid,
        _availableJourneySnapshot!,
      );
    }
    if (newJourneyRequest.size > 0 && newJourneyRequest.docs.first.id != _availableJourneySnapshot!.id) {
      updateJourneyRoutePolylines(newJourneyRequest.docs.first.data());
      availableJourneySnapshot = newJourneyRequest.docs.first;
      availableJourneyPassenger = await _userRepo.getUser(_availableJourneySnapshot!.data().userId);
    }
  }

  void updateJourneyRoutePolylines(Journey journey) {
    final start = journey.startLatLng;
    final end = journey.endLatLng;
    _placeService.fetchRoute(start, end).then((polylines) {
      mapViewState.polylines.clear();
      mapViewState.polylines.add(polylines);
      MapHelper.setCameraToRoute(
        mapController: mapViewState.mapController,
        polylines: mapViewState.polylines,
        topOffsetPercentage: 1,
        bottomOffsetPercentage: 0.2,
      );
      mapViewState.markers[const MarkerId("start")] = Marker(
        markerId: const MarkerId("start"),
        position: start,
        icon: mapViewState.locationIcon!,
      );
      mapViewState.markers[const MarkerId("destination")] = Marker(
        markerId: const MarkerId("destination"),
        position: end,
        icon: mapViewState.locationIcon!,
      );
    });
  }

  Future<void> updateJourneyRequestListener() async {
    toggleIsSearching();
    mapViewState.polylines.clear();
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));

    if (_isSearching) {
      StreamSubscription<QuerySnapshot<Journey>>? journeyListener;
      journeyListener = _journeyRepo.getFirstJourneyRequest(firebaseUser!.uid).listen((nextJourneySnapshot) async {
        if (nextJourneySnapshot.size > 0) {
          journeyListener?.cancel();
          updateJourneyRoutePolylines(nextJourneySnapshot.docs.first.data());
          availableJourneySnapshot = nextJourneySnapshot.docs.first;
          availableJourneyPassenger = await _userRepo.getUser(availableJourneySnapshot!.data().userId);
        }
      });
    } else {
      availableJourneySnapshot = null;
      availableJourneyPassenger = null;
      MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition);
    }
  }

  void toggleIsSearching() {
    _driverRepo.updateDriver(driver!, {'isAvailable': !isSearching});
    isSearching = !isSearching;
  }
}
