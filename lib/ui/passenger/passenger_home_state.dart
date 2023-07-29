import 'dart:async';

import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:ap_lanes/data/repo/driver_repo.dart';
import 'package:ap_lanes/data/repo/vehicle_repo.dart';
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
  PassengerHomeState(this._context) {
    initialize();
  }

  /*
  * Variables
  * */
  final BuildContext _context;
  late final MapViewState2 mapViewState;
  final NotificationService notificationService = NotificationService();

  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _userRepo = UserRepo();
  final _vehicleRepo = VehicleRepo();
  final _placeService = PlaceService();

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;

  StreamSubscription<QuerySnapshot<Journey>>? _journeyListener;
  StreamSubscription<QuerySnapshot<Driver>>? _driverListener;

  String _paymentMode = PaymentMode.cash;
  double? _routeDistance;
  double? _routePrice;
  LatLng? _destinationLatLng;
  String? _destinationDescription;
  bool _isSearching = false;
  bool _isPickedUp = false;
  bool _hasDriver = false;
  bool _toApu = false;

  String? _driverName;
  String? _driverPhone;
  QueryDocumentSnapshot<Vehicle>? _vehicle;

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

  Future<void> initialize() async {
    _searchController.addListener(() => notifyListeners());
    mapViewState = _context.read<MapViewState2>();
    initializeFirestore();
  }

  // Handles listening to database
  Future<void> initializeFirestore() async {
    final firebaseUser = _context.read<firebase_auth.User?>();

    // Checks if user is logged in
    if (firebaseUser != null) {
      // Assigns user from database
      user = (await _userRepo.get(firebaseUser.uid))!;

      // Begins listening for user created journeys
      _journeyListener = _journeyRepo.listenForJourney(firebaseUser.uid).listen((journey) async {
        if (journey.docs.isNotEmpty) {
          _journey = journey.docs.first;
          notifyListeners();

          // Checks if journey has a driver
          if (_journey!.data().driverId.isNotEmpty) {
            if (!_isPickedUp && _journey!.data().isPickedUp) {
              // Notifies passenger they have been picked up
              notificationService.notifyPassenger("Your driver has picked you up!");
            }
            _isPickedUp = _journey!.data().isPickedUp == true;
            notifyListeners();

            // Gets driver name and phone number
            final driverId = _journey!.data().driverId;
            await _userRepo.get(driverId).then((driver) {
              if (driver != null) {
                _driverName = driver.data().getFullName();
                _driverPhone = driver.data().phoneNumber;
              }
            });

            // Get driver details
            _driverRepo.get(driverId).then((driver) async {
              if (driver != null) {
                // Gets vehicle details
                _vehicle = await _vehicleRepo.get(driver.data().id);

                // Notifies passenger that a driver has been found
                if (!_hasDriver) {
                  notificationService.notifyPassenger("Driver has been found!",
                      body:
                          "Your driver for today is $_driverName. Look for the license plate ${_vehicle?.data().licensePlate} to meet your driver.");
                }
                _hasDriver = true;

                // Clears map state
                _routeDistance = null;
                _routePrice = null;
                mapViewState.polylines.clear();
                mapViewState.shouldCenter = false;
                mapViewState.markers.remove("start");
                mapViewState.markers.remove("destination");
                _isSearching = false;
                notifyListeners();

                // Listens to driver's location and updates map
                // ??= used to ensure multiple listen calls are not made
                _driverListener ??= _driverRepo.listen(driverId).listen((driver) {
                  if (driver.docs.isNotEmpty) {
                    final latLng = driver.docs.first.data().currentLatLng;
                    if (latLng != LatLng(0.0, 0.0) && mapViewState.currentPosition != null) {
                      mapViewState.markers["driver"] = Marker(
                        point: latLng!,
                        builder: (_) => const Icon(Icons.drive_eta, size: 35, color: Colors.black),
                      );
                      mapViewState.shouldCenter = false;
                      mapViewState.setCameraBetweenMarkers(
                        firstLatLng: latLng,
                        secondLatLng: mapViewState.currentPosition!,
                        topOffsetPercentage: 2,
                        bottomOffsetPercentage: 1,
                        leftOffsetPercentage: 1,
                        rightOffsetPercentage: 1,
                      );
                      notifyListeners();
                    }
                  }
                });
              }
            });
            // If driver not yet found
          } else {
            _isSearching = true;
            _resetDriverDetails();
            notifyListeners();
          }
          // If user has not yet created a journey
        } else if (_journey != null) {
          resetState();
        }
      });
    }
  }

  void _resetDriverDetails() {
    mapViewState.markers.remove('driver');
    _hasDriver = false;
    _driverName = null;
    _driverPhone = null;
    _vehicle = null;
  }

  void onDescription(description) {
    _destinationDescription = description;
    _sessionToken = const Uuid().v4();
  }

  Future<void> updateToApu(toApu) async {
    _toApu = toApu;
    notifyListeners();
    if (_destinationLatLng != null) {
      final start = _toApu ? _destinationLatLng! : apuLatLng;
      final end = _toApu ? apuLatLng : _destinationLatLng!;
      try {
        await _placeService.fetchRoute(start, end).then((polylines) async {
          mapViewState.polylines.clear();
          mapViewState.polylines.add(polylines);
          mapViewState.shouldCenter = false;
          mapViewState.setCameraToRoute(
            topOffsetPercentage: 0.5,
            bottomOffsetPercentage: 0.5,
          );
          _routeDistance = calculateRouteDistance(polylines);
          _routePrice = await calculateRoutePrice(double.parse(_routeDistance!.toStringAsFixed(2)));
          notifyListeners(); // Notifies when route is received
        });
      } on Exception catch (e) {
        ScaffoldMessenger.of(_context)
            .showSnackBar(const SnackBar(content: Text("Invalid location! Please use another location.")));
      }
    }
  }

  void clearUserLocation() {
    _searchController.clear();
    _destinationLatLng = null;
    mapViewState.shouldCenter = true;
    mapViewState.polylines.clear();
    mapViewState.markers.remove("start");
    mapViewState.markers.remove("destination");
    if (mapViewState.currentPosition != null) {
      mapViewState.resetCamera();
    }
    _routeDistance = null;
    _routePrice = null;
    notifyListeners();
  }

  Future<void> onLatLng(BuildContext context, LatLng latLng) async {
    try {
      _destinationLatLng = latLng;
      notifyListeners();
      final start = _toApu ? _destinationLatLng! : apuLatLng;
      final end = _toApu ? apuLatLng : _destinationLatLng!;
      await _placeService.fetchRoute(start, end).then((polylines) async {
        mapViewState.polylines.add(polylines);
        mapViewState.shouldCenter = false;
        mapViewState.setCameraToRoute(
          topOffsetPercentage: 0.5,
          bottomOffsetPercentage: 0.5,
        );
        mapViewState.markers["start"] = Marker(
          point: start,
          builder: (_) => const Icon(Icons.location_pin, size: 35, color: Colors.black),
        );
        mapViewState.markers["destination"] = Marker(
          point: end,
          builder: (_) => const Icon(Icons.location_pin, size: 35, color: Colors.black),
        );
        _routeDistance = calculateRouteDistance(polylines);
        _routePrice = await calculateRoutePrice(_routeDistance!);
        notifyListeners();
      });
    } on Exception catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid location! Please use another location.")));
    }
  }

  Future<void> cancelJourneyAsPassenger() async {
    // Cancels journey in database
    await _journeyRepo.cancelJourneyTransaction(_journey!);
  }

  void createJourney() async {
    if (_routeDistance == null) return;
    await showDialog(
        context: _context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
                title: const Text('Select Payment Mode'),
                content: DropdownButton(
                    isExpanded: true,
                    value: _paymentMode,
                    onChanged: (value) {
                      setState(() => paymentMode = value);
                    },
                    items: <DropdownMenuItem>[
                      DropdownMenuItem<String>(value: PaymentMode.cash, child: Text(PaymentMode.cash)),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'Cancel');
                      },
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'Okay');
                    },
                    child: const Text('Okay'),
                  )
                ]);
          });
        });

    // Handles creation of journey
    if (_context.mounted) {
      final firebaseUser = _context.read<firebase_auth.User?>();
      if (firebaseUser != null && _routeDistance != null && _routePrice != null) {
        if (_routeDistance! <= 7.0) {
          isSearching = true;
          _journeyRepo.create(
            Journey(
              userId: firebaseUser.uid,
              startLatLng: toApu ? _destinationLatLng! : apuLatLng,
              endLatLng: toApu ? apuLatLng : _destinationLatLng!,
              startDescription: _toApu ? _destinationDescription! : apuDescription,
              endDescription: _toApu ? apuDescription : _destinationDescription!,
              distance: _routeDistance!.toStringAsFixed(2),
              price: _routePrice!.toStringAsFixed(2),
              paymentMode: _paymentMode,
            ),
          );
        } else {
          ScaffoldMessenger.of(_context)
              .showSnackBar(const SnackBar(content: Text("Journeys are limited to a distance of 7 km")));
        }
      }
    }
  }

  void deleteJourney() async {
    try {
      isSearching = false;
      clearUserLocation();
      await _journeyRepo.delete(_journey);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> resetState() async {
    if (hasDriver) {
      notificationService.notifyPassenger("Your journey is now complete!", body: "Thank you for choosing APLanes.");
      _hasDriver = false;
    }
    _driverName = null;
    _driverPhone = null;
    _vehicle = null;
    _journey = null;
    _isSearching = false;
    _isPickedUp = false;
    _searchController.clear();
    _routeDistance = null;
    _routePrice = null;
    _destinationDescription = null;
    _destinationLatLng = null;
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

  String? get driverName => _driverName;

  String get paymentMode => _paymentMode;

  bool get toApu => _toApu;

  bool get hasDriver => _hasDriver;

  bool get isPickedUp => _isPickedUp;

  bool get isSearching => _isSearching;

  QueryDocumentSnapshot<Vehicle>? get vehicle => _vehicle;

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

  set driverName(String? value) {
    _driverName = value;
    notifyListeners();
  }

  set toApu(bool value) {
    _toApu = value;
    notifyListeners();
  }

  set hasDriver(bool value) {
    _hasDriver = value;
    notifyListeners();
  }

  set paymentMode(String value) {
    _paymentMode = value;
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
