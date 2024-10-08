import 'dart:async';

import 'package:ap_lanes/data/model/remote/journey.dart';
import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/data/repo/user_repo.dart';
import 'package:ap_lanes/services/place_service.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

class JourneyRequestPopupState extends ChangeNotifier {
  final BuildContext _context;
  late final firebase_auth.User? _firebaseUser;
  late final MapViewState2 _mapViewState;
  late final DriverHomeState _driverHomeState;

  StreamSubscription<MapEntry<DriverState, dynamic>>? _onDriverStateChangedListener;
  StreamSubscription<QuerySnapshot<Journey>>? _initialJourneysListener;

  JourneyRequestPopupState(this._context) {
    _firebaseUser = Provider.of<firebase_auth.User?>(_context, listen: false);
    _mapViewState = Provider.of<MapViewState2>(_context, listen: false);
    _driverHomeState = Provider.of<DriverHomeState>(_context, listen: false);
    _onDriverStateChangedListener = _driverHomeState.onDriverStateChanged.listen(onDriverStateChangedCallback);

    if (_driverHomeState.driverState == DriverState.searching) {
      fetchInitialJourneys();
      debugPrint("Ran initial fetch");
    }
  }

  @override
  void dispose() async {
    super.dispose();
    // await _onDriverStateChangedListener?.cancel();
    await _initialJourneysListener?.cancel();
    _initialJourneysListener = null;
  }

  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();

  QueryDocumentSnapshot<User>? _availableJourneyPassenger;

  QueryDocumentSnapshot<User>? get availableJourneyPassenger => _availableJourneyPassenger;

  set availableJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _availableJourneyPassenger = value;
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

  double _routeDistance = 0;

  double get routeDistance => _routeDistance;

  set routeDistance(double value) {
    _routeDistance = value;
    notifyListeners();
  }

  int _currentJourneyIndex = 0;

  bool _isLoadingJourneyRequests = true;

  bool get isLoadingJourneyRequests => _isLoadingJourneyRequests;

  set isLoadingJourneyRequests(bool value) {
    _isLoadingJourneyRequests = value;
    notifyListeners();
  }

  Future<void> updateAvailableJourney(QueryDocumentSnapshot<Journey>? journey) async {
    if (journey != null) {
      _availableJourney = journey;
      _availableJourneyPassenger = await _userRepo.get(journey.data().userId);
      await updateJourneyRoutePolylines(journey.data());
    } else {
      resetAvailableJourneys();
    }
    notifyListeners();
  }

  Future<void> updateJourneyRoutePolylines(Journey journey) async {
    final start = journey.startLatLng;
    final end = journey.endLatLng;
    final polylines = await _placeService.fetchRoute(start, end);
    _mapViewState.polylines.clear();
    _mapViewState.polylines.add(polylines);
    _mapViewState.shouldCenter = false;
    _mapViewState.setCameraToRoute(
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
    _mapViewState.markers["start"] = Marker(
      point: start,
      builder: (_) => const Icon(Icons.location_pin, size: 35, color: Colors.black),
    );
    _mapViewState.markers["destination"] = Marker(
      point: end,
      builder: (_) => const Icon(Icons.location_pin, size: 35, color: Colors.black),
    );
    _mapViewState.notifyListeners();
  }

  void onRequestPopupNavigate(RequestNavigationDirection direction, BuildContext context) async {
    isLoadingJourneyRequests = true;
    QueryDocumentSnapshot<Journey>? journeyToShow = _availableJourney;
    switch (direction) {
      case RequestNavigationDirection.forward:
        if ((_currentJourneyIndex + 1) <= availableJourneys!.size - 1) {
          _currentJourneyIndex++;
          journeyToShow = availableJourneys!.docs.elementAt(_currentJourneyIndex);
        } else {
          final nextJourneys = await _journeyRepo.getNextJourneyRequest(_firebaseUser!.uid, availableJourney!);

          if (nextJourneys.size > 0) {
            _availableJourneys = nextJourneys;
            _currentJourneyIndex = 0;
            journeyToShow = availableJourneys!.docs.elementAt(_currentJourneyIndex);
            await _initialJourneysListener?.cancel();
            _initialJourneysListener = null;
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reached end of request list."),
                ),
              );
            }
          }
        }
        break;
      case RequestNavigationDirection.backward:
        if ((_currentJourneyIndex - 1) >= 0) {
          _currentJourneyIndex--;
          journeyToShow = availableJourneys!.docs.elementAt(_currentJourneyIndex);
        } else {
          final previousJourneys = await _journeyRepo.getPrevJourneyRequest(_firebaseUser!.uid, availableJourney!);

          if (previousJourneys.size > 0) {
            _availableJourneys = previousJourneys;
            _currentJourneyIndex = availableJourneys!.size - 1;
            journeyToShow = availableJourneys!.docs.elementAt(_currentJourneyIndex);
            await _initialJourneysListener?.cancel();
            _initialJourneysListener = null;
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reached start of request list."),
                ),
              );
            }
          }
        }
        break;
    }
    await updateAvailableJourney(journeyToShow);
    isLoadingJourneyRequests = false;
    notifyListeners();
  }

  Future<void> fetchInitialJourneys() async {
    _isLoadingJourneyRequests = true;
    _initialJourneysListener ??= _journeyRepo.getFirstJourneyRequest(_firebaseUser!.uid).listen((snap) async {
      _availableJourneys = snap;
      final journeyIndex = _currentJourneyIndex > (snap.size - 1) ? snap.size - 1 : _currentJourneyIndex;
      final journeyToShow = snap.size > 0 ? snap.docs.elementAt(journeyIndex) : null;
      await updateAvailableJourney(journeyToShow);
      _isLoadingJourneyRequests = false;
      notifyListeners();
    });
  }

  void resetAvailableJourneys() {
    _currentJourneyIndex = 0;
    _mapViewState.polylines.clear();
    _mapViewState.markers.removeWhere((key, value) => key == "start" || key == "destination");
    _mapViewState.notifyListeners();
    _availableJourneys = null;
    _availableJourney = null;
    _availableJourneyPassenger = null;
    notifyListeners();
  }

  void onJourneyAccept() async {
    try {
      await _journeyRepo.acceptJourneyRequest(_availableJourney!, _firebaseUser!.uid);

      _driverHomeState.stopSearching();

      await _initialJourneysListener?.cancel();
      _initialJourneysListener = null;

      _driverHomeState.didAcceptJourneyRequest(availableJourney!);
    } catch (e) {
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void onDriverStateChangedCallback(MapEntry<DriverState, dynamic> state) {
    if (!_context.mounted) return;
    switch (state.key) {
      case DriverState.idle:
        resetAvailableJourneys();
        _initialJourneysListener?.cancel();
        _initialJourneysListener = null;
        break;
      case DriverState.searching:
        fetchInitialJourneys();
        break;
      case DriverState.ongoing:
        // nothing
        break;
    }
  }
}

enum RequestNavigationDirection {
  forward,
  backward,
}
