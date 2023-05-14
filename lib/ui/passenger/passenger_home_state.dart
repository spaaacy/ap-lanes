import 'dart:async';

import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/remote/driver.dart';
import '../../data/model/remote/journey.dart';
import '../../data/model/remote/user.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../services/notification_service.dart';
import '../../services/place_service.dart';
import '../../util/constants.dart';
import '../../util/location_helpers.dart';

class PassengerHomeState extends ChangeNotifier {
  /*
  * Variables
  * */
  late final MapViewState mapViewState;
  final NotificationService notificationService = NotificationService();

  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _userRepo = UserRepo();
  final _placeService = PlaceService();

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;

  StreamSubscription<QuerySnapshot<Journey>>? _journeyListener;
  StreamSubscription<QuerySnapshot<Driver>>? _driverListener;

  double? _routeDistance;
  double? _routePrice;
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
  String? _vehicleManufacturer;
  String? _vehicleModel;
  String? _vehicleColor;

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
    _searchController.addListener(() => notifyListeners());
    mapViewState = context.read<MapViewState>();
    initializeFirestore(context);
  }

  Future<void> initializeFirestore(BuildContext context) async {
    final firebaseUser = context.read<firebase_auth.User?>();

    if (firebaseUser != null) {
      // Set user and last name
      _user = (await _userRepo.getUser(firebaseUser.uid))!;
      notifyListeners();

      _journeyListener = _journeyRepo.listenForJourney(firebaseUser.uid).listen((journey) async {
        if (journey.docs.isNotEmpty) {
          _journey = journey.docs.first;
          _inJourney = true;
          notifyListeners();

          if (_journey!.data().driverId.isNotEmpty) {
            if (!_isPickedUp && _journey!.data().isPickedUp) {
              notificationService.notifyPassenger("Your driver has picked you up!");
            }
            _isPickedUp = _journey!.data().isPickedUp == true;
            notifyListeners();

            // Get driver name
            final driverId = _journey!.data().driverId;
            await _userRepo.getUser(driverId).then((driver) {
              if (driver != null) {
                _driverName = driver.data().getFullName();
                _driverPhone = driver.data().phoneNumber;
              }
            });

            _driverRepo.getDriver(driverId).then((driver) {
              if (driver != null) {
                // Get driver details
                _driverLicensePlate = driver.data().licensePlate;
                _vehicleManufacturer = driver.data().vehicleManufacturer;
                _vehicleModel = driver.data().vehicleModel;
                _vehicleColor = driver.data().vehicleColor;
                _hasDriver = true;

                // Clear map state
                _routeDistance = null;
                _routePrice = null;
                mapViewState.polylines.clear();
                mapViewState.shouldCenter = false;
                mapViewState.markers.remove("start");
                mapViewState.markers.remove("destination");
                _isSearching = false;

                if (!_hasDriver) {
                  notificationService.notifyPassenger("Driver has been found!",
                      body:
                          "Your driver for today is $_driverName. Look for the license plate $_driverLicensePlate to meet your driver.");
                }

                notifyListeners();

                // Used to ensure multiple listen calls are not made
                _driverListener ??= _driverRepo.listenToDriver(driverId).listen((driver) {
                  if (driver.docs.isNotEmpty) {
                    final latLng = driver.docs.first.data().currentLatLng;
                    if (latLng != null && mapViewState.currentPosition != null) {
                      mapViewState.markers["driver"] = Marker(
                        point: latLng,
                        builder: (_) => const Icon(Icons.drive_eta, size: 35),
                      );
                      mapViewState.shouldCenter = false;
                      mapViewState.setCameraBetweenMarkers(
                        firstLatLng: latLng,
                        secondLatLng: mapViewState.currentPosition!,
                        topOffsetPercentage: 3.5,
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
            _resetDriverDetails();
            notifyListeners();
          }
        } else if (_journey != null) {
          resetState();
        }
      });
    }
  }

  void _resetDriverDetails() {
    _hasDriver = false;
    _driverName = null;
    _driverPhone = null;
    _driverLicensePlate = null;
    _vehicleColor = null;
    _vehicleManufacturer = null;
    _vehicleColor = null;
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
        mapViewState.setCameraToRoute(
          topOffsetPercentage: 0.5,
          bottomOffsetPercentage: 0.5,
        );
        _routeDistance = calculateRouteDistance(polylines);
        _routePrice = calculateRoutePrice(_routeDistance!);
        notifyListeners(); // Notifies when route is received
      });
    }
  }

  void clearUserLocation() {
    _destinationLatLng = null;
    mapViewState.polylines.clear();
    mapViewState.shouldCenter = true;
    _routeDistance = null;
    _routePrice = null;
    mapViewState.markers.remove("start");
    mapViewState.markers.remove("destination");
    if (mapViewState.currentPosition != null) {
      mapViewState.resetCamera();
    }
    _routeDistance = null;
    _routePrice = null;
    notifyListeners();
  }

  void onLatLng(BuildContext context, LatLng latLng) {
    _destinationLatLng = latLng;
    final start = _toApu ? _destinationLatLng! : apuLatLng;
    final end = _toApu ? apuLatLng : _destinationLatLng!;
    notifyListeners(); // Notifies when _destinationLatLng set
    _placeService.fetchRoute(start, end).then((polylines) {
      mapViewState.polylines.add(polylines);
      mapViewState.shouldCenter = false;
      mapViewState.setCameraToRoute(
        topOffsetPercentage: 0.5,
        bottomOffsetPercentage: 0.5,
      );
      mapViewState.markers["start"] = Marker(
        point: start,
        builder: (_) => const Icon(Icons.location_pin, size: 35),
      );
      mapViewState.markers["destination"] = Marker(
        point: end,
        builder: (_) => const Icon(Icons.location_pin, size: 35),
      );
      _routeDistance = calculateRouteDistance(polylines);
      _routePrice = calculateRoutePrice(_routeDistance!);
      notifyListeners(); // Notifies when route is received
    });
  }

  Future<void> cancelJourneyAsPassenger() async {
    await _journeyRepo.cancelJourneyAsPassenger(_journey!);
  }

  void createJourney(BuildContext context) {
    final firebaseUser = context.read<firebase_auth.User?>();
    if (firebaseUser != null && _routeDistance != null && _routePrice != null) {
      if (_routeDistance! <= 7.0) {
        isSearching = true;
        _journeyRepo.createJourney(
          Journey(
            userId: firebaseUser.uid,
            startLatLng: toApu ? _destinationLatLng! : apuLatLng,
            endLatLng: toApu ? apuLatLng : _destinationLatLng!,
            startDescription: _toApu ? _destinationDescription! : apuDescription,
            endDescription: _toApu ? apuDescription : _destinationDescription!,
            distance: _routeDistance!.toStringAsFixed(2),
            price: _routePrice!.toStringAsFixed(2),
            paymentMode: PaymentMode.cash,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Journeys are limited to a distance of 7 km")));
      }
    }
  }

  void deleteJourney() {
    isSearching = false;
    _journeyRepo.deleteJourney(_journey);
  }

  Future<void> resetState() async {
    if (hasDriver) {
      notificationService.notifyPassenger("Your journey is now complete!", body: "Thank you for using APLanes.");
      hasDriver = false;
    }
    driverName = null;
    driverLicensePlate = null;
    driverPhone = null;
    journey = null;
    isSearching = false;
    inJourney = false;
    isPickedUp = false;
    _searchController.clear();
    routeDistance = null;
    destinationDescription = null;
    destinationLatLng = null;
    mapViewState.polylines.clear();
    mapViewState.shouldCenter = true;
    mapViewState.markers.remove("driver");
    mapViewState.markers.remove("start");
    mapViewState.markers.remove("destination");
    mapViewState.resetCamera();
    await _driverListener?.cancel();
    _driverListener = null;
    notifyListeners();
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

  double? get routeDistance => _routeDistance;

  double? get routePrice => _routePrice;

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

  String? get vehicleModel => _vehicleModel;

  String? get vehicleManufacturer => _vehicleManufacturer;

  String? get vehicleColor => _vehicleColor;

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

  set routePrice(double? value) {
    _routePrice = value;
    notifyListeners();
  }
}
