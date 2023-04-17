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
  GoogleMapController? _mapController;

  final _passengerRepo = PassengerRepo();
  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();
  final _driverRepo = DriverRepo();
  final _placeService = PlaceService();

  late final firebase_auth.User? firebaseUser;
  QueryDocumentSnapshot<Passenger>? _passenger;
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;

  LatLng? _userLatLng;
  String? _userLocationDescription;
  final Set<Polyline> _polylines = Set<Polyline>();

  bool _isSearching = false;
  bool _toApu = false;
  final List<String> _journeyDetails = ["Finding a driver..."];

  late StreamSubscription<QuerySnapshot<Journey>> _journeyStream;


  @override
  void initState() {
    super.initState();

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
    super.dispose();
    await _journeyStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Greeting.getGreeting(),
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
                  userLatLng: _userLatLng,
                  userLocationDescription: _userLocationDescription,
                  toApu: _toApu,
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
                              MapHelper.drawRoute(_userLatLng!, _toApu, _polylines, (polylines) {
                                setState(() {
                                  _polylines.add(polylines);
                                  MapHelper.setCameraToRoute(_mapController!, _polylines);
                                });
                              });
                            });
                          },
                          controller: _searchController,
                          userLocation: _userLatLng,
                          onLatLng: (latLng) {
                            setState(() {
                              _userLatLng = latLng;
                              MapHelper.drawRoute(_userLatLng!, _toApu, _polylines, (polylines) {
                                setState(() {
                                  _polylines.add(polylines);
                                  MapHelper.setCameraToRoute(_mapController!, _polylines);
                                });
                              });
                            });
                          },
                          clearUserLocation: () {
                            setState(() {
                              _userLatLng = null;
                              _polylines.clear();
                            });
                          },
                          onDescription: (description) {
                            _userLocationDescription = description;
                          },
                        ),
                      ),
                    ),
                  ),
                if (_userLatLng != null || _isSearching)
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
                          final String userLatLng = "${_userLatLng!.latitude}, ${_userLatLng!.longitude}";
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
