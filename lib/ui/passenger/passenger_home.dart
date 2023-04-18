import 'dart:async';

import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/model/firestore/user.dart';
import 'package:apu_rideshare/data/repo/driver_repo.dart';
import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:apu_rideshare/ui/common/app_drawer.dart';
import 'package:apu_rideshare/ui/common/map_view.dart';
import 'package:apu_rideshare/ui/passenger/components/journey_detail.dart';
import 'package:apu_rideshare/ui/passenger/components/passenger_go_button.dart';
import 'package:apu_rideshare/ui/passenger/components/search_bar.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:apu_rideshare/util/map_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/passenger.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../services/place_service.dart';
import '../../util/greeting.dart';

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
  late StreamSubscription<QuerySnapshot<Journey>> _journeyStream;

  String? _lastName;
  LatLng? _destinationLatLng;
  String? _userLocationDescription;
  bool _isSearching = false;
  bool _toApu = false;
  final List<String> _journeyDetails = ["Finding a driver..."];

  // Google Map Variables
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = <Polyline>{};
  late final BitmapDescriptor _locationIcon;
  late final BitmapDescriptor _userIcon;
  Marker? _userMarker;
  Marker? _destinationMarker;
  Marker? _startMarker;
  LatLng? _currentPosition;
  late StreamSubscription<Position> _locationSubscription;



  @override
  void initState() {
    super.initState();
    MapHelper.getCustomIcon('assets/icons/location_icon.png', locationIconSize).then((icon) => setState(() => _locationIcon = icon));
    MapHelper.getCustomIcon('assets/icons/user_icon.png', userIconSize).then((icon) => setState(() => _userIcon = icon));

    _locationSubscription = MapHelper.getCurrentPosition(context).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _userMarker = Marker(markerId: const MarkerId("user-marker"), position: _currentPosition!, icon: _userIcon);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _passengerRepo.getPassenger(firebaseUser!.uid).then((passenger) {
          _passenger = passenger;
          _isSearching = _passenger?.data().isSearching == true;
        });

        _userRepo.getUser(firebaseUser!.uid).then((userData) {
          setState(() {
            _user = userData;
            _lastName = userData.data().lastName;
          });
        });

        _journeyStream = _journeyRepo.listenForJourney(firebaseUser!.uid, (journey) {
          _journey = journey;
          _journeyDetails.clear();
          if (_journey!.data().driverId.isNotEmpty) {
            final driverId = _journey!.data().driverId;
            _userRepo.getUser(driverId).then((user) {
              _journeyDetails.add("Your Driver:");
              _journeyDetails.add(user.data().getFullName());
              return user.data().id;
            }).then((id) => _driverRepo.getDriver(id).then((driver) {
                  _journeyDetails.add(driver.data().licensePlate);
                  _polylines.clear();
                  setState(() {});
                }));
          } else {
            setState(() => _journeyDetails.add("Finding a driver..."));
          }
        });
      }
    });
  }

  @override
  void dispose() async {
    await _journeyStream.cancel();
    _locationSubscription.cancel();
    super.dispose();
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
                content: Text("You cannot change to driver mode while you are searching for a driver or are in a journey."),
              ),
            );
          }),
      body: _passenger == null
          ? const Align(child: CircularProgressIndicator())
          : Stack(
              children: [

                MapView(
                  userLatLng: _currentPosition,
                  destinationMarker: _destinationMarker,
                  startMarker: _startMarker,
                  userMarker: _userMarker,
                  polylines: _polylines,
                  setMapController: (controller) {
                    setState((){
                      _mapController = controller;
                    });
                  },
                  mapController: _mapController,
                ),

                Positioned(
                    child: Align(
                      alignment: Alignment.topCenter,
                        child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: JourneyDetail(
                              isSearching: _isSearching,
                              journey: _journey,
                              journeyDetails: _journeyDetails,
                            )))
                ),
                if (!_isSearching)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SearchBar(
                          toApu: _toApu,
                          updateToApu: (toApu) {
                            setState(() {
                              _toApu = toApu;
                              if(_destinationLatLng != null){
                                final start = _toApu ? _destinationLatLng! : apuLatLng;
                                final end = _toApu ? apuLatLng : _destinationLatLng!;
                                MapHelper.drawRoute(_polylines, start, end, (polylines) {
                                  setState(() {
                                    _polylines.clear();
                                    _polylines.add(polylines);
                                    MapHelper.setCameraToRoute(_mapController!, _polylines);
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
                              MapHelper.drawRoute(_polylines, start, end, (polylines) {
                                setState(() {
                                  _polylines.add(polylines);
                                  MapHelper.setCameraToRoute(_mapController!, _polylines);
                                  _destinationMarker = Marker(
                                      markerId: const MarkerId("destination"),
                                      position: latLng,
                                      icon: _locationIcon
                                  );
                                  _startMarker = Marker(
                                      markerId: const MarkerId("start"),
                                      position: apuLatLng,
                                      icon: _locationIcon
                                  );
                                });
                              });
                            });
                          },
                          clearUserLocation: () {
                            setState(() {
                              _destinationLatLng = null;
                              _polylines.clear();
                              _destinationMarker = null;
                              _startMarker = null;
                              MapHelper.resetCamera(_mapController, _currentPosition!);
                            });
                          },
                          onDescription: (description) {
                            _userLocationDescription = description;
                          },
                        ),
                      ),
                    ),
                  ),
                if (_destinationLatLng != null || _isSearching)
                  Positioned.fill(
                    bottom: 100.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: PassengerGoButton(
                        isSearching: _isSearching,
                        updateIsSearching: (isSearching) {
                          _passengerRepo.updateIsSearching(_passenger!, isSearching);
                          setState(() {
                            _isSearching = isSearching;
                          });
                        },
                        createJourney: () {
                          final String userLatLng = "${_destinationLatLng!.latitude}, ${_destinationLatLng!.longitude}";
                          final String apuLatLngString = "${apuLatLng.latitude}, ${apuLatLng.longitude}";
                          _journeyRepo.createJourney(Journey(
                            userId: firebaseUser!.uid,
                            startLatLng: _toApu ? userLatLng : apuLatLngString,
                            endLatLng: _toApu ? apuLatLngString : userLatLng,
                            startDescription: _toApu ? _userLocationDescription! : apuDescription,
                            endDescription: _toApu ? apuDescription : _userLocationDescription!
                          ));
                        },
                        deleteJourney: () {
                          _journeyRepo.deleteJourney(_journey);
                        },
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
