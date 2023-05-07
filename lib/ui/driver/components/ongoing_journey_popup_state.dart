import 'dart:async';

import 'package:ap_lanes/data/model/remote/journey.dart';
import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/data/repo/user_repo.dart';
import 'package:ap_lanes/services/driver_location_service.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class OngoingJourneyPopupState extends ChangeNotifier {
  final BuildContext _context;
  late final firebase_auth.User? _firebaseUser;
  late final MapViewState _mapViewState;
  late final DriverHomeState _driverHomeState;
  late StreamSubscription<QueryDocumentSnapshot<Journey>?> _onJourneyRequestAcceptedListener;

  QueryDocumentSnapshot<Journey>? _ongoingJourneyRequest;
  bool _isLoadingJourneyRequest = false;
  StreamSubscription<Position>? _driverLocationListener;
  QueryDocumentSnapshot<Journey>? _activeJourney;
  QueryDocumentSnapshot<User>? _activeJourneyPassenger;
  StreamSubscription<QuerySnapshot<Journey>>? _activeJourneyListener;

  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();

  bool get isLoadingJourneyRequest => _isLoadingJourneyRequest;

  set isLoadingJourneyRequest(bool value) {
    _isLoadingJourneyRequest = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get ongoingJourneyRequest => _ongoingJourneyRequest;

  set ongoingJourneyRequest(QueryDocumentSnapshot<Journey>? value) {
    _ongoingJourneyRequest = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get activeJourney => _activeJourney;

  set activeJourney(QueryDocumentSnapshot<Journey>? value) {
    _activeJourney = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get activeJourneyPassenger => _activeJourneyPassenger;

  set activeJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _activeJourneyPassenger = value;
    notifyListeners();
  }

  StreamSubscription<QuerySnapshot<Journey>>? get activeJourneyListener => _activeJourneyListener;

  set activeJourneyListener(StreamSubscription<QuerySnapshot<Journey>>? value) {
    _activeJourneyListener = value;
    notifyListeners();
  }

  OngoingJourneyPopupState(this._context) {
    _firebaseUser = Provider.of<firebase_auth.User?>(_context, listen: false);
    _mapViewState = Provider.of<MapViewState>(_context, listen: false);
    _driverHomeState = Provider.of<DriverHomeState>(_context, listen: false);
    _onJourneyRequestAcceptedListener =
        _driverHomeState.onJourneyRequestAccepted.listen(onJourneyRequestAcceptedCallback);
  }

  @override
  void dispose() {
    _onJourneyRequestAcceptedListener.cancel();
    stopOngoingJourneyListenerAndCleanUp();
    super.dispose();
  }

  void onJourneyRequestAcceptedCallback(QueryDocumentSnapshot<Journey>? event) {
    startOngoingJourneyListener();
  }

  void updateCameraBoundsWithPopup(LatLng start, LatLng end) {
    _mapViewState.shouldCenter = false;
    _mapViewState.setCameraBetweenMarkers(
      firstLatLng: start,
      secondLatLng: end,
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
  }

  void updateActiveJourney(QueryDocumentSnapshot<Journey> journeySnapshot) async {
    _activeJourney = journeySnapshot;
    _activeJourneyPassenger = await _userRepo.getUser(journeySnapshot.data().userId);

    if (journeySnapshot.data().isPickedUp) {
      _mapViewState.markers["drop-off"] = Marker(
        point: journeySnapshot.data().endLatLng,
        builder: (_) => const Icon(Icons.location_pin, size: 35),
      );
      updateCameraBoundsWithPopup(_mapViewState.currentPosition!, journeySnapshot.data().endLatLng);
    } else {
      _mapViewState.markers["pick-up"] = Marker(
        point: journeySnapshot.data().startLatLng,
        builder: (_) => const Icon(Icons.location_pin, size: 35),
      );
      updateCameraBoundsWithPopup(_mapViewState.currentPosition!, journeySnapshot.data().startLatLng);
    }
    notifyListeners();
  }

  void handleActiveJourneyDisappear() async {
    if (_activeJourney == null) return;

    final previousJourney = await _activeJourney!.reference.get();
    if (!previousJourney.exists || previousJourney.data()!.isCancelled) {
      stopOngoingJourneyListenerAndCleanUp();
      if (_context.mounted) {
        await showDialog(
          context: _context,
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

  void startOngoingJourneyListener() async {
    isLoadingJourneyRequest = true;

    _registerDriverLocationListener();
    _activeJourneyListener ??= _journeyRepo.getOngoingJourneyStream(_firebaseUser!.uid).listen((snap) async {
      final hasOngoingJourney = snap.size > 0;

      if (hasOngoingJourney) {
        _mapViewState.shouldCenter = false;
        if (!DriverLocationService.isRegistered) {
          DriverLocationService.registerDriverLocationBackgroundService(_driverHomeState.driver);
        }
        updateActiveJourney(snap.docs.first);
        isLoadingJourneyRequest = false;
      } else {
        handleActiveJourneyDisappear();
      }
    });
    notifyListeners();
  }

  void stopOngoingJourneyListenerAndCleanUp() async {
    await _unregisterActiveJourneyListener();
    await _unregisterDriverLocationListener();
    _activeJourney = null;
    _activeJourneyPassenger = null;
    DriverLocationService.unregisterDriverLocationBackgroundService();

    try {
      _mapViewState.shouldCenter = true;
      _mapViewState.markers.remove("drop-off");
      _mapViewState.markers.remove("pick-up");
      _driverHomeState.driverState = DriverState.idle;
      _mapViewState.resetCamera();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _unregisterActiveJourneyListener() async {
    await _activeJourneyListener?.cancel();
    _activeJourneyListener = null;
  }

  Future<void> _registerDriverLocationListener() async {
    _driverLocationListener ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);

      LatLng targetLatLng =
          _activeJourney!.data().isPickedUp ? _activeJourney!.data().endLatLng : _activeJourney!.data().startLatLng;
      updateCameraBoundsWithPopup(latLng, targetLatLng);
    });
  }

  Future<void> _unregisterDriverLocationListener() async {
    await _driverLocationListener?.cancel();
    _driverLocationListener = null;
  }

  void onJourneyDropOff() async {
    bool? shouldDropOff = await requestDropOffConfirmation();

    if (shouldDropOff == null || shouldDropOff == false) {
      return;
    }
    try {
      await _journeyRepo.completeJourney(_activeJourney);
      stopOngoingJourneyListenerAndCleanUp();
    } catch (e) {
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    }
  }

  Future<bool?> requestDropOffConfirmation() async {
    bool? shouldDropOff = await showDialog<bool>(
      context: _context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Confirm Drop-off?"),
          content: const Text('Are you sure you want to mark this journey as complete?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(_context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(_context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return shouldDropOff;
  }

  void onJourneyPickUp() async {
    isLoadingJourneyRequest = true;
    try {
      bool isPickedUp = await _journeyRepo.updateJourneyPickUpStatus(activeJourney);
      if (isPickedUp) {
        _mapViewState.markers.remove("pick-up");
        _mapViewState.markers["pick-up"] = Marker(
          point: activeJourney!.data().endLatLng,
          builder: (_) => const Icon(Icons.location_pin, size: 35),
        );
        updateCameraBoundsWithPopup(_mapViewState.currentPosition!, activeJourney!.data().endLatLng);
      } else {
        _mapViewState.markers.remove("drop-off");
        _mapViewState.markers["pick-up"] = Marker(
          point: activeJourney!.data().startLatLng,
          builder: (_) => const Icon(Icons.location_pin, size: 35),
        );
        updateCameraBoundsWithPopup(_mapViewState.currentPosition!, activeJourney!.data().startLatLng);
      }
    } catch (e) {
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      isLoadingJourneyRequest = false;
    }
  }
}
