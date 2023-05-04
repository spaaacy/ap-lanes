import 'dart:async';

import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/remote/driver.dart';
import '../../data/model/remote/journey.dart';
import '../../data/model/remote/passenger.dart';
import '../../data/model/remote/user.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/passenger_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../services/place_service.dart';
import '../../util/constants.dart';
import '../../util/map_helper.dart';

class PassengerHomeState extends ChangeNotifier {
  /*
  * Variables
  * */
  late final MapViewState mapViewState;

  final _passengerRepo = PassengerRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _userRepo = UserRepo();
  final _placeService = PlaceService();

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Passenger>? _passenger;
  QueryDocumentSnapshot<Journey>? _journey;

  StreamSubscription<QuerySnapshot<Journey>>? _journeyListener;
  StreamSubscription<QuerySnapshot<Driver>>? _driverListener;

  String? _lastName;
  double? _routeDistance;
  LatLng? _destinationLatLng;
  String? _destinationDescription;
  bool _isSearching = false;
  bool _isPickedUp = false;
  bool _hasDriver = false;
  bool _inJourney = false;
  bool _toApu = false;
  String? _driverName;
  String? _driverLicensePlate;
  String? _driverPhone;

  final _searchController = TextEditingController();
  String _sessionToken = const Uuid().v4();

  /*
  * Functions
  * */
  @override
  void dispose() {
    _driverListener?.cancel();
    _journeyListener?.cancel();
    super.dispose();
  }

  Future<void> initialize(BuildContext context) async {
    mapViewState = context.read<MapViewState>();
    initializeFirestore(context);
  }
  
  Future<void> initializeFirestore(BuildContext context) async {
    final firebaseUser = context.read<firebase_auth.User?>();

    if (firebaseUser != null) {
      // Set user and last name
      _user = (await _userRepo.getUser(firebaseUser.uid))!;
      _lastName = _user!.data().lastName;
      _passenger = (await _passengerRepo.getPassenger(firebaseUser.uid))!;
      notifyListeners();

      _journeyListener = _journeyRepo.listenForJourney(firebaseUser.uid).listen((journey) async {
        if (journey.docs.isNotEmpty) {
          _journey = journey.docs.first;
          _inJourney = true;
          notifyListeners();

          if (_journey!.data().driverId.isNotEmpty) {
            _isPickedUp = _journey!.data().isPickedUp;
            notifyListeners();

            // Get driver name
            final driverId = _journey!.data().driverId;
            _userRepo.getUser(driverId).then((driver) {
              if (driver != null) {
                _driverName = driver.data().getFullName();
                _driverPhone = driver.data().phoneNumber;
              }
            });

            _driverRepo.getDriver(driverId).then((driver) {
              // Sets journey details
              if (driver != null) {
                _hasDriver = true;
                _driverLicensePlate = driver.data().licensePlate;
                _routeDistance = null;
                mapViewState.polylines.clear();
                mapViewState.shouldCenter = true;
                mapViewState.markers.remove(const MarkerId("start"));
                mapViewState.markers.remove(const MarkerId("destination"));
                notifyListeners();

                // Used to ensure multiple listen calls are not made
                _driverListener ??= _driverRepo.listenToDriver(driverId).listen((driver) {
                  if (driver.docs.isNotEmpty) {
                    final latLng = driver.docs.first.data().currentLatLng;
                    if (latLng != null && mapViewState.currentPosition != null) {
                      mapViewState.markers[const MarkerId("driver")] =
                          Marker(markerId: const MarkerId("driver"), position: latLng, icon: mapViewState.driverIcon!); // TODO: Recheck assertion
                      mapViewState.shouldCenter = false;
                      MapHelper.setCameraBetweenMarkers(
                        mapController: mapViewState.mapController!,
                        firstLatLng: latLng,
                        secondLatLng: mapViewState.currentPosition!,
                        topOffsetPercentage: 3,
                        bottomOffsetPercentage: 1,
                      );
                      notifyListeners();
                    }
                  }
                });
              }
            });
          } else {
            _isSearching = true;
            notifyListeners();
          }
        } else if (_journey != null) {
          // Runs after journey completion/deletion/cancellation
          resetState();
        }
      });
    }
  }

  void onDescription(description) {
    _destinationDescription = description;
    _sessionToken = const Uuid().v4();
  }

  void updateToApu(toApu) {
    _toApu = toApu;
    notifyListeners(); // Notifies when _toApu set
    if (_destinationLatLng != null) {
      final start = _toApu ? _destinationLatLng! : apuLatLng;
      final end = _toApu ? apuLatLng : _destinationLatLng!;
      _placeService.fetchRoute(start, end).then((polylines) {
        mapViewState.polylines.clear();
        mapViewState.polylines.add(polylines);
        mapViewState.shouldCenter = false;
        MapHelper.setCameraToRoute(
          mapController: mapViewState.mapController!,
          polylines: mapViewState.polylines,
          topOffsetPercentage: 0.5,
          bottomOffsetPercentage: 0.5,
        );
        _routeDistance = MapHelper.calculateRouteDistance(polylines);
        notifyListeners(); // Notifies when route is received
      });
    }
  }

  void clearUserLocation() {
    _destinationLatLng = null;
    mapViewState.polylines.clear();
    mapViewState.shouldCenter = true;
    _routeDistance = null;
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));
    if (mapViewState.currentPosition != null) {
      MapHelper.resetCamera(mapViewState.newMapController, mapViewState.newCurrentPosition!);
    }
    _routeDistance = null;
    notifyListeners();
  }

  void onLatLng(BuildContext context, latLng) {
    _destinationLatLng = latLng;
    final start = _toApu ? _destinationLatLng! : apuLatLng;
    final end = _toApu ? apuLatLng : _destinationLatLng!;
    notifyListeners(); // Notifies when _destinationLatLng set
    _placeService.fetchRoute(start, end).then((polylines) {
      mapViewState.polylines.add(polylines);
      mapViewState.shouldCenter = false;
      MapHelper.setCameraToRoute(
        mapController: mapViewState.mapController!,
        polylines: mapViewState.polylines,
        topOffsetPercentage: 0.5,
        bottomOffsetPercentage: 0.5,
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
      _routeDistance = MapHelper.calculateRouteDistance(polylines);
      notifyListeners(); // Notifies when route is received
    });
  }

  Future<void> cancelJourneyAsPassenger() async {
    await _journeyRepo.cancelJourneyAsPassenger(_journey!);
  }

  void createJourney(BuildContext context) {
    final firebaseUser = context.read<firebase_auth.User?>();
    if (firebaseUser != null){
      _journeyRepo.createJourney(
        Journey(
            userId: firebaseUser.uid,
            startLatLng: toApu ? _destinationLatLng! : apuLatLng,
            endLatLng: toApu ? apuLatLng : _destinationLatLng!,
            startDescription: _toApu ? _destinationDescription! : apuDescription,
            endDescription: _toApu ? apuDescription : _destinationDescription!),
      );
    }
  }

  void deleteJourney() {
    _journeyRepo.deleteJourney(_journey);
  }

  Future<void> resetState() async {
    driverName = null;
    driverLicensePlate = null;
    driverPhone = null;
    journey = null;
    isSearching = false;
    inJourney = false;
    isPickedUp = false;
    hasDriver = false;
    _searchController.clear();
    routeDistance = null;
    destinationDescription = null;
    destinationLatLng = null;
    mapViewState.polylines.clear();
    mapViewState.shouldCenter = true;
    mapViewState.markers.remove(const MarkerId("driver"));
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));
    MapHelper.resetCamera(mapViewState.newMapController, mapViewState.newCurrentPosition);
    await _driverListener?.cancel();
    _driverListener = null;
    notifyListeners();
  }

  void disposeListener() {
    _journeyListener?.cancel();
    _driverListener?.cancel();
  }

  /*
  * Getters
  * */
  get searchController => _searchController;

  String get sessionToken => _sessionToken;

  QueryDocumentSnapshot<User>? get user => _user;

  StreamSubscription<QuerySnapshot<Journey>>? get journeyListener => _journeyListener;

  StreamSubscription<QuerySnapshot<Driver>>? get driverListener => _driverListener;

  QueryDocumentSnapshot<Journey>? get journey => _journey;

  QueryDocumentSnapshot<Passenger>? get passenger => _passenger;

  String? get lastName => _lastName;

  double? get routeDistance => _routeDistance;

  LatLng? get destinationLatLng => _destinationLatLng;

  String? get destinationDescription => _destinationDescription;

  String? get driverPhone => _driverPhone;

  String? get driverLicensePlate => _driverLicensePlate;

  String? get driverName => _driverName;

  bool get toApu => _toApu;

  bool get inJourney => _inJourney;

  bool get hasDriver => _hasDriver;

  bool get isPickedUp => _isPickedUp;

  bool get isSearching => _isSearching;

  /*
  * Setters
  * */
  set sessionToken(String value) {
    _sessionToken = value;
    notifyListeners();
  }

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  set journeyListener(StreamSubscription<QuerySnapshot<Journey>>? value) {
    _journeyListener = value;
    notifyListeners();
  }

  set driverListener(StreamSubscription<QuerySnapshot<Driver>>? value) {
    _driverListener = value;
    notifyListeners();
  }

  set journey(QueryDocumentSnapshot<Journey>? value) {
    _journey = value;
    notifyListeners();
  }

  set passenger(QueryDocumentSnapshot<Passenger>? value) {
    _passenger = value;
    notifyListeners();
  }

  set driverPhone(String? value) {
    _driverPhone = value;
    notifyListeners();
  }

  set driverLicensePlate(String? value) {
    _driverLicensePlate = value;
    notifyListeners();
  }

  set driverName(String? value) {
    _driverName = value;
    notifyListeners();
  }

  set toApu(bool value) {
    _toApu = value;
    notifyListeners();
  }

  set inJourney(bool value) {
    _inJourney = value;
    notifyListeners();
  }

  set hasDriver(bool value) {
    _hasDriver = value;
    notifyListeners();
  }

  set isPickedUp(bool value) {
    _isPickedUp = value;
    notifyListeners();
  }

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  set destinationDescription(String? value) {
    _destinationDescription = value;
    notifyListeners();
  }

  set destinationLatLng(LatLng? value) {
    _destinationLatLng = value;
    notifyListeners();
  }

  set routeDistance(double? value) {
    _routeDistance = value;
    notifyListeners();
  }

  set lastName(String? value) {
    _lastName = value;
    notifyListeners();
  }
}
