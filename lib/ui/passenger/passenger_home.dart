import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/model/firestore/driver.dart';
import '../../data/model/firestore/journey.dart';
import '../../data/model/firestore/passenger.dart';
import '../../data/model/firestore/user.dart';
import '../../data/repo/driver_repo.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/passenger_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../services/place_service.dart';
import '../../util/constants.dart';
import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view.dart';
import 'components/journey_detail.dart';
import 'components/go_button.dart';
import 'components/search_bar.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();
  String _sessionToken = const Uuid().v4();

  final _passengerRepo = PassengerRepo();
  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();
  final _driverRepo = DriverRepo();
  final _placeService = PlaceService();

  late final firebase_auth.User? firebaseUser;
  QueryDocumentSnapshot<Passenger>? _passenger;
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;
  late StreamSubscription<QuerySnapshot<Journey>> _journeyListener;
  late StreamSubscription<Position> _locationListener;
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

  // Google Map Variables
  GoogleMapController? _mapController;
  late final BitmapDescriptor _userIcon;
  late final BitmapDescriptor _driverIcon;
  late final BitmapDescriptor _locationIcon;
  bool _shouldCenter = true;
  LatLng? _currentPosition;
  final Set<Polyline> _polylines = <Polyline>{};
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  late String _mapStyle;

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userIcon = await MapHelper.getCustomIcon('assets/icons/user.png', userIconSize);
      _driverIcon = await MapHelper.getCustomIcon('assets/icons/driver.png', userIconSize);
      _locationIcon = await MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize);

      if (mounted) {
        _locationListener = MapHelper.getCurrentPosition(context).listen((position) {
          final latLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentPosition = latLng;
            _markers[const MarkerId("user-marker")] = Marker(
              markerId: const MarkerId("user-marker"),
              position: _currentPosition!,
              icon: _userIcon,
            );

            if (_shouldCenter) {
              MapHelper.resetCamera(_mapController, _currentPosition);
            }
          });
        });
      }

      await initializeFirestore();
    });
  }

  Future<void> initializeFirestore() async {
    firebaseUser = context.read<firebase_auth.User?>();

    if (firebaseUser != null) {
      // Set user and last name
      _user = (await _userRepo.getUser(firebaseUser!.uid))!;
      _lastName = _user!.data().lastName;
      setState(() {});

      // Set passenger and isSearching
      _passenger = (await _passengerRepo.getPassenger(firebaseUser!.uid))!;
      _isSearching = _passenger!.data().isSearching;

      _journeyListener = _journeyRepo.listenForJourney(firebaseUser!.uid).listen((journey) async {
        if (journey.docs.isNotEmpty) {
          setState(() {
            _journey = journey.docs.first;
            _inJourney = true;
          });

          if (_journey!.data().driverId.isNotEmpty) {
            setState(() {
              _isPickedUp = _journey!.data().isPickedUp;
            });

            if (_isSearching) {
              _passengerRepo.updateIsSearching(_passenger!, false);
            }

            // Get driver name
            final driverId = _journey!.data().driverId;
            _userRepo.getUser(driverId).then((driver) {
              if (driver != null) {
                _driverName = driver.data().getFullName();
              }
            });

            _driverRepo.getDriver(driverId).then((driver) {
              // Sets journey details
              if (driver != null) {
                setState(() {
                  _hasDriver = true;
                  _driverLicensePlate = driver.data().licensePlate;
                  _routeDistance = null;
                  _polylines.clear();
                  _markers.remove(const MarkerId("start"));
                  _markers.remove(const MarkerId("destination"));
                });

                // Used to ensure multiple listen calls are not made
                _driverListener ??= _driverRepo.listenToDriver(driverId).listen((driver) {
                  if (driver.docs.isNotEmpty) {
                    final latLng = driver.docs.first.data().currentLatLng;
                    if (latLng != null && _currentPosition != null) {
                      setState(() {
                        _markers[const MarkerId("driver-marker")] =
                            Marker(markerId: const MarkerId("driver-marker"), position: latLng, icon: _driverIcon);
                        MapHelper.setCameraBetweenMarkers(
                          mapController: _mapController!,
                          firstLatLng: latLng,
                          secondLatLng: _currentPosition!,
                          topOffsetPercentage: 3,
                          bottomOffsetPercentage: 1,
                        );
                      });
                    }
                  }
                });
              }
            });
          }
        } else if (_journey != null) {
          // Runs after journey completion/deletion/cancellation
          resetState();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return _user == null
        ? const Scaffold(body: Align(child: CircularProgressIndicator()))
    : Scaffold(
      appBar: AppBar(
        title: Text(
          getGreeting(_lastName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      drawer: AppDrawer(
          user: _user,
          isDriver: false,
          isNavigationLocked: _isSearching,
          onNavigateWhenLocked: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("You cannot change to driver mode while you are searching for a driver or are in a journey."),
              ),
            );
          }),
      body: Stack(
              children: [
                MapView(
                  userLatLng: _currentPosition,
                  setShouldCenter: (shouldCenter) {
                    setState(() {
                      _shouldCenter = shouldCenter;
                    });
                  },
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) async {
                    setState(() {
                      _mapController = controller;
                    });
                    _mapStyle = await MapHelper.getMapStyle();
                    controller.setMapStyle(_mapStyle);
                  },
                  mapController: _mapController,
                ),
                if (_isSearching || _hasDriver)
                  JourneyDetail(
                    inJourney: _inJourney,
                    driverName: _driverName,
                    driverLicensePlate: _driverLicensePlate,
                    isPickedUp: _isPickedUp,
                    hasDriver: _hasDriver,
                    journey: _journey,
                  ),
                ...?(() {
                  if (!_isSearching && !_hasDriver) {
                    return [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SearchBar(
                              sessionToken: _sessionToken,
                              routeDistance: _routeDistance,
                              toApu: _toApu,
                              updateToApu: (toApu) {
                                setState(() {
                                  _toApu = toApu;
                                  if (_destinationLatLng != null) {
                                    final start = _toApu ? _destinationLatLng! : apuLatLng;
                                    final end = _toApu ? apuLatLng : _destinationLatLng!;
                                    _placeService.generateRoute(start, end).then((polylines) {
                                      setState(() {
                                        _polylines.clear();
                                        _polylines.add(polylines);
                                        MapHelper.setCameraToRoute(
                                          mapController: _mapController!,
                                          polylines: _polylines,
                                          topOffsetPercentage: 0.5,
                                          bottomOffsetPercentage: 0.25,
                                        );
                                        _routeDistance = MapHelper.calculateRouteDistance(polylines);
                                      });
                                    });
                                  }
                                });
                              },
                              controller: _searchController,
                              destinationLatLng: _destinationLatLng,
                              onLatLng: (latLng) {
                                setState(() {
                                  _destinationLatLng = latLng;
                                  final start = _toApu ? _destinationLatLng! : apuLatLng;
                                  final end = _toApu ? apuLatLng : _destinationLatLng!;
                                  _placeService.generateRoute(start, end).then((polylines) {
                                    setState(() {
                                      _polylines.add(polylines);
                                      MapHelper.setCameraToRoute(
                                        mapController: _mapController!,
                                        polylines: _polylines,
                                        topOffsetPercentage: 0.5,
                                        bottomOffsetPercentage: 0.25,
                                      );
                                      _markers[const MarkerId("start")] = Marker(
                                        markerId: const MarkerId("start"),
                                        position: start,
                                        icon: _locationIcon,
                                      );
                                      _markers[const MarkerId("destination")] = Marker(
                                        markerId: const MarkerId("destination"),
                                        position: end,
                                        icon: _locationIcon,
                                      );
                                      _routeDistance = MapHelper.calculateRouteDistance(polylines);
                                    });
                                  });
                                });
                              },
                              clearUserLocation: () {
                                setState(() {
                                  _destinationLatLng = null;
                                  _polylines.clear();
                                  _routeDistance = null;
                                  _markers.remove(const MarkerId("start"));
                                  _markers.remove(const MarkerId("destination"));
                                  if (_currentPosition != null) {
                                    MapHelper.resetCamera(_mapController, _currentPosition!);
                                  }
                                  _routeDistance = null;
                                });
                              },
                              onDescription: (description) {
                                _destinationDescription = description;
                                _sessionToken = const Uuid().v4();
                              },
                            ),
                          ),
                        ),
                      ),
                    ];
                  }
                }()),
                ...?(() {
                  if (_destinationLatLng != null || _isSearching) {
                    return [
                      Positioned.fill(
                        bottom: 100.0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: GoButton(
                            isSearching: _isSearching,
                            hasDriver: _hasDriver,
                            updateIsSearching: (isSearching) {
                              if (_passenger != null) {
                                _passengerRepo.updateIsSearching(_passenger!, isSearching);
                              }
                              setState(() {
                                _isSearching = isSearching;
                              });
                            },
                            createJourney: () {
                              _journeyRepo.createJourney(
                                Journey(
                                    userId: firebaseUser!.uid,
                                    startLatLng: _toApu ? _destinationLatLng! : apuLatLng,
                                    endLatLng: _toApu ? apuLatLng : _destinationLatLng!,
                                    startDescription: _toApu ? _destinationDescription! : apuDescription,
                                    endDescription: _toApu ? apuDescription : _destinationDescription!),
                              );
                            },
                            deleteJourney: () {
                              _journeyRepo.deleteJourney(_journey);
                            },
                          ),
                        ),
                      )
                    ];
                  }
                }()),
              ],
            ),
    );
  }

  @override
  void dispose() async {
    _journeyListener.cancel();
    _locationListener.cancel();
    _driverListener?.cancel();
    super.dispose();
  }

  Future<void> resetState() async {
    setState(() {
      _driverName = null;
      _driverLicensePlate = null;
      _journey = null;
      _isSearching = false;
      _inJourney = false;
      _isPickedUp = false;
      _hasDriver = false;
      _searchController.clear();
      _routeDistance = null;
      _destinationDescription = null;
      _destinationLatLng = null;
      _polylines.clear();
      _markers.remove(const MarkerId("driver-marker"));
      _markers.remove(const MarkerId("start"));
      _markers.remove(const MarkerId("destination"));
      MapHelper.resetCamera(_mapController!, _currentPosition);
    });
    await _driverListener?.cancel();
    _driverListener = null;
  }
}
