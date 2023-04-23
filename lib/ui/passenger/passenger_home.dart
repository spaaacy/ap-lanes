import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/driver.dart';
import '../../data/model/firestore/journey.dart';
import '../../data/model/firestore/passenger.dart';
import '../../data/model/firestore/user.dart';
import '../../data/model/map/marker_info.dart';
import '../../data/repo/driver_repo.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/passenger_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../util/constants.dart';
import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view.dart';
import 'components/journey_detail.dart';
import 'components/passenger_go_button.dart';
import 'components/search_bar.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();

  final _passengerRepo = PassengerRepo();
  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();
  final _driverRepo = DriverRepo();

  late final firebase_auth.User? firebaseUser;
  QueryDocumentSnapshot<Passenger>? _passenger;
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;
  late StreamSubscription<QuerySnapshot<Journey>> _journeyListener;

  double? _routeDistance;
  String? _lastName;
  String? _driverId;
  LatLng? _destinationLatLng;
  String? _locationDescription;
  bool _isSearching = false;
  bool _isPickedUp = false;
  bool _hasDriver = false;
  bool _inJourney = false;
  bool _toApu = false;
  String? _driverName;
  String? _driverLicensePlate;
  StreamSubscription<QuerySnapshot<Driver>>? _driverListener;

  // Google Map Variables
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = <Polyline>{};
  late final BitmapDescriptor _userIcon;
  late final BitmapDescriptor _driverIcon;
  bool _shouldCenter = true;
  LatLng? _currentPosition;
  late StreamSubscription<Position> _locationListener;
  final Set<MarkerInfo> _markers = {};

  @override
  void initState() {
    super.initState();
    MapHelper.getCustomIcon('assets/icons/user.png', userIconSize).then((icon) => setState(() => _userIcon = icon));
    MapHelper.getCustomIcon('assets/icons/driver.png', userIconSize).then((icon) => setState(() => _driverIcon = icon));

    _locationListener = MapHelper.getCurrentPosition(context).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _markers.removeWhere((element) => element.markerId == "user-marker");
        _markers.add(MarkerInfo(markerId: "user-marker", position: _currentPosition!, icon: _userIcon));

        if (_shouldCenter) {
          if (_currentPosition != null) {
            MapHelper.resetCamera(_mapController, _currentPosition!);
          }
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _passenger = await _passengerRepo.getPassenger(firebaseUser!.uid);
        _isSearching = _passenger!.data().isSearching;

        _userRepo.getUser(firebaseUser!.uid).then((userData) {
          setState(() {
            _user = userData;
            _lastName = userData.data().lastName;
          });
        });

        _journeyListener = _journeyRepo.listenForJourney(firebaseUser!.uid).listen((journey) async {
          if (journey.docs.isNotEmpty) {
            _journey = journey.docs.first;
            _inJourney = true;
            setState(() {});

            if (_journey!.data().driverId.isNotEmpty) {
              setState(() {
                _isPickedUp = _journey!.data().isPickedUp;
              });

              if (_passenger!.data().isSearching) {
                _passengerRepo.updateIsSearching(_passenger!, false);
              }

              final driverId = _journey!.data().driverId;

              // Get name
              final driverUser = await _userRepo.getUser(driverId);
              final driverName = driverUser.data().getFullName();

              _driverRepo.getDriver(driverId).then((driver) {
                // Sets journey details
                _driverName = driverName;
                _driverLicensePlate = driver!.data().licensePlate;
                _hasDriver = true;
                _polylines.clear();
                _markers.removeWhere((e) => e.markerId == "start" || e.markerId == "destination");
                _routeDistance = null;
                setState(() {});

                // Sets the marker
                if (_driverId != driverId) {
                  // Used to ensure multiple listen calls are not made
                  if (_driverListener != null) {
                    _driverListener!.cancel();
                  }

                  _driverId = driverId;
                  _driverListener = _driverRepo.listenToDriver(_driverId!).listen((driver) {
                    if (driver.docs.isNotEmpty) {
                      final latLng = driver.docs.first.data().currentLatLng;
                      if (latLng != null && _currentPosition != null) {
                        setState(() {
                          MapHelper.setCameraBetweenMarkers(
                            mapController: _mapController!,
                            firstLatLng: latLng,
                            secondLatLng: _currentPosition!,
                            topOffsetPercentage: 3,
                            bottomOffsetPercentage: 1,
                          );
                          _markers.removeWhere((e) => e.markerId == "driver-marker");
                          _markers.add(
                            MarkerInfo(
                              markerId: "driver-marker",
                              position: latLng,
                              icon: _driverIcon,
                            ),
                          );
                        });
                      }
                    }
                  });
                }
              });
            }
          } else if (_journey != null) {
            // Runs after journey completion
            _driverName = null;
            _driverLicensePlate = null;
            _journey = null;
            _isSearching = false;
            _inJourney = false;
            _isPickedUp = false;
            _hasDriver = false;
            _searchController.clear();
            _driverListener?.cancel();
            _markers.removeWhere((e) => e.markerId == "driver-marker");
            if (_currentPosition != null && _locationDescription == null) {
              MapHelper.resetCamera(_mapController!, _currentPosition!);
            }
            setState(() {});
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Greeting.getGreeting(_lastName),
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
      body: (_passenger == null || _user == null)
          ? const Align(child: CircularProgressIndicator())
          : Stack(
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
                  setMapController: (controller) {
                    setState(() {
                      _mapController = controller;
                    });
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
                              routeDistance: _routeDistance,
                              toApu: _toApu,
                              updateToApu: (toApu) {
                                setState(() {
                                  _toApu = toApu;
                                  if (_destinationLatLng != null) {
                                    final start = _toApu ? _destinationLatLng! : apuLatLng;
                                    final end = _toApu ? apuLatLng : _destinationLatLng!;
                                    MapHelper.drawRoute(start, end).then((polylines) {
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
                              userLocation: _destinationLatLng,
                              onLatLng: (latLng) {
                                setState(() {
                                  _destinationLatLng = latLng;
                                  final start = _toApu ? _destinationLatLng! : apuLatLng;
                                  final end = _toApu ? apuLatLng : _destinationLatLng!;
                                  MapHelper.drawRoute(start, end).then((polylines) {
                                    setState(() {
                                      _polylines.add(polylines);
                                      MapHelper.setCameraToRoute(
                                        mapController: _mapController!,
                                        polylines: _polylines,
                                        topOffsetPercentage: 0.5,
                                        bottomOffsetPercentage: 0.25,
                                      );
                                      _markers.add(MarkerInfo(markerId: "start", position: start));
                                      _markers.add(MarkerInfo(markerId: "destination", position: end));
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
                                  _markers.removeWhere((e) => e.markerId == "start" || e.markerId == "destination");
                                  if (_currentPosition != null) {
                                    MapHelper.resetCamera(_mapController, _currentPosition!);
                                  }
                                  _routeDistance = null;
                                });
                              },
                              onDescription: (description) {
                                _locationDescription = description;
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
                          child: PassengerGoButton(
                            isSearching: _isSearching,
                            hasDriver: _hasDriver,
                            updateIsSearching: (isSearching) { // TODO: Fix here
                              _passengerRepo.updateIsSearching(_passenger!, isSearching);
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
                                    startDescription: _toApu ? _locationDescription! : apuDescription,
                                    endDescription: _toApu ? apuDescription : _locationDescription!),
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
}
