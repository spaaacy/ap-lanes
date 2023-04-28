import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/model/remote/driver.dart';
import '../../data/model/remote/journey.dart';
import '../../data/model/remote/user.dart';
import '../../data/repo/driver_repo.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../services/place_service.dart';
import '../../util/constants.dart';
import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view/map_view.dart';
import '../common/map_view/map_view_state.dart';
import '../passenger/passenger_home.dart';
import '../passenger/passenger_home_state.dart';
import 'components/journey_request_popup.dart';
import 'components/ongoing_journey_popup.dart';
import 'components/setup_driver_profile_dialog.dart';
import 'driver_home_state.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}


class _DriverHomeState extends State<DriverHome> {
  late final MapViewState mapViewState;
  late final firebase_auth.User? firebaseUser;

  bool _isSearching = false;

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();
  DocumentSnapshot<Journey>? _activeJourney;
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Driver>? _driver;
  QueryDocumentSnapshot<Journey>? _availableJourneySnapshot;
  StreamSubscription<QuerySnapshot<Journey>>? _activeJourneyListener;

  void updateJourneyRoutePolylines(Journey journey) {
    final start = journey.startLatLng;
    final end = journey.endLatLng;
    _placeService.fetchRoute(start, end).then((polylines) {
      setState(() {
        mapViewState.polylines.clear();
        mapViewState.polylines.add(polylines);
        MapHelper.setCameraToRoute(
          mapController: mapViewState.mapController!,
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
    });
  }

  Future<void> _updateJourneyRequestListener() async {
    mapViewState.polylines.clear();
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));

    if (_isSearching) {
      StreamSubscription<QuerySnapshot<Journey>>? journeyListener;
      journeyListener = _journeyRepo.getFirstJourneyRequest(firebaseUser!.uid).listen((nextJourneySnapshot) {
        if (nextJourneySnapshot.size > 0) {
          journeyListener?.cancel();
          updateJourneyRoutePolylines(nextJourneySnapshot.docs.first.data());
          _availableJourneySnapshot = nextJourneySnapshot.docs.first;
        }
      });
    } else {
      _availableJourneySnapshot = null;
      MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition);
    }
    setState(() {});
  }

  @override
  initState() {
    super.initState();
    mapViewState = context.read<MapViewState>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        firebaseUser = context.read<firebase_auth.User?>();
      }
      if (firebaseUser != null) {
        startOngoingJourneyListener();

        var userData = await _userRepo.getUser(firebaseUser!.uid);
        setState(() {
          _user = userData;
        });

        var driverData = await _driverRepo.getDriver(firebaseUser!.uid);
        if (driverData != null) {
          setState(() {
            _driver = driverData;
            // todo: maybe make this check for ongoing journeys instead
            _isSearching = _driver?.data().isAvailable == true;

            _updateJourneyRequestListener();
          });
        } else {
          if (!mounted) return;
          var result = await showDialog<String?>(
            context: context,
            builder: (ctx) => SetupDriverProfileDialog(userId: firebaseUser!.uid),
          );

          if (result == 'Save') {
            var driverSnapshot = await _driverRepo.getDriver(firebaseUser!.uid);
            setState(() {
              _driver = driverSnapshot;
            });
          } else {
            if (!mounted) return;

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

            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) => ChangeNotifierProvider(
                    create: (context) {
                      return PassengerHomeState()..initialize(context);
                    },
                    child: const PassengerHome()),
              ),
              (_) => false,
            );
          }
        }
      }
    });
  }

  void startOngoingJourneyListener() async {
    await _activeJourneyListener?.cancel();

    _activeJourneyListener = _journeyRepo.getOngoingJourney(firebaseUser!.uid).listen((ss) async {
      if (ss.size == 0 && _activeJourney != null) {
        await _activeJourneyListener?.cancel();
        if (!mounted) return;
        showDialog(
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

      if (ss.size > 0) {
        setState(() {
          _activeJourney = ss.docs.first;

          if (_activeJourney!.data()!.isPickedUp) {
            mapViewState.markers[const MarkerId("drop-off")] = Marker(
              markerId: const MarkerId("drop-off"),
              position: _activeJourney!.data()!.endLatLng,
              icon: mapViewState.locationIcon!,
            );
            updateCameraBoundsWithPopup(mapViewState.currentPosition, _activeJourney!.data()!.endLatLng);
          } else {
            mapViewState.markers[const MarkerId("pick-up")] = Marker(
              markerId: const MarkerId("pick-up"),
              position: _activeJourney!.data()!.startLatLng,
              icon: mapViewState.locationIcon!,
            );
            updateCameraBoundsWithPopup(mapViewState.currentPosition, _activeJourney!.data()!.startLatLng);
          }
        });
      } else {
        setState(() {
          mapViewState.markers.remove(const MarkerId("drop-off"));
          mapViewState.markers.remove(const MarkerId("pick-up"));
          _activeJourney = null;
        });
      }
    });
  }

  void updateCameraBoundsWithPopup(LatLng? latLng, LatLng? otherLatLng) {
    if (latLng == null || otherLatLng == null) {
      return;
    }
    MapHelper.setCameraBetweenMarkers(
      mapController: mapViewState.mapController,
      firstLatLng: latLng,
      secondLatLng: otherLatLng,
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
  }

  @override
  void dispose() {
    _activeJourneyListener?.cancel();
    super.dispose();
  }

  void toggleIsSearching() {
    _driverRepo.updateDriver(_driver!, {'isAvailable': !_isSearching});
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  bool isLoading() {
    return _user == null || _driver == null;
  }

  @override
  Widget build(BuildContext context) {
    void onJourneyDropOff(DocumentSnapshot<Journey>? activeJourney) async {
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

        setState(() {
          mapViewState.markers.remove(const MarkerId("drop-off"));
          mapViewState.markers.remove(const MarkerId("pick-up"));
          _activeJourney = null;
        });

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

    void onJourneyPickUp(DocumentSnapshot<Journey>? activeJourney) async {
      try {
        bool isPickedUp = await _journeyRepo.updateJourneyPickUpStatus(activeJourney);
        if (isPickedUp) {
          setState(() {
            mapViewState.markers.remove(const MarkerId("pick-up"));
            mapViewState.markers[const MarkerId("pick-up")] = Marker(
              markerId: const MarkerId("pick-up"),
              position: activeJourney!.data()!.endLatLng,
              icon: mapViewState.locationIcon!,
            );
            updateCameraBoundsWithPopup(mapViewState.currentPosition, activeJourney.data()!.endLatLng);
          });
        } else {
          setState(() {
            mapViewState.markers.remove(const MarkerId("drop-off"));
            mapViewState.markers[const MarkerId("pick-up")] = Marker(
              markerId: const MarkerId("pick-up"),
              position: activeJourney!.data()!.startLatLng,
              icon: mapViewState.locationIcon!,
            );
            updateCameraBoundsWithPopup(mapViewState.currentPosition, activeJourney.data()!.startLatLng);
          });
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

    void onJourneyAccept(QueryDocumentSnapshot<Journey> acceptedJourney) async {
      try {
        DocumentSnapshot<Journey>? updatedJourney = await _journeyRepo.acceptJourneyRequest(
          acceptedJourney,
          firebaseUser!.uid,
        );
        toggleIsSearching();
        setState(() {
          mapViewState.polylines.clear();
          mapViewState.markers.remove(const MarkerId("start"));
          mapViewState.markers.remove(const MarkerId("destination"));
          _activeJourney = updatedJourney;
          mapViewState.markers[const MarkerId("pick-up")] = Marker(
            markerId: const MarkerId("pick-up"),
            position: updatedJourney!.data()!.startLatLng,
            icon: mapViewState.locationIcon!,
          );
          updateCameraBoundsWithPopup(mapViewState.currentPosition, updatedJourney.data()!.startLatLng);
          startOngoingJourneyListener();
        });
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

    return ChangeNotifierProvider(
      create: (ctx) => DriverHomeState()
        ..driver = _driver
        ..user = _user
        ..isSearching = _isSearching
        ..mapController = mapViewState.mapController
        ..activeJourney = _activeJourney
        ..polylines = mapViewState.polylines,
      child: isLoading()
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
        appBar: AppBar(
          title: Text(
            getGreeting(_user?.data().lastName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        drawer: AppDrawer(
            user: _user,
            isDriver: true,
            isNavigationLocked: _isSearching || _activeJourney != null,
            onNavigateWhenLocked: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You cannot change to passenger mode while you are searching or carrying out a job."),
                ),
              );
            }),
        body: Stack(
                children: [
                  const MapView(),
                  Positioned.fill(
                    bottom: 100.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: (() {
                        if (_activeJourney == null) {
                          return ElevatedButton(
                            onPressed: () {
                              toggleIsSearching();
                              _updateJourneyRequestListener();
                            },
                            style: ElevatedButtonTheme.of(context).style?.copyWith(
                                  shape: const MaterialStatePropertyAll(CircleBorder()),
                                  padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                                  elevation: const MaterialStatePropertyAll(6.0),
                                ),
                            child: _isSearching
                                ? const Icon(
                                    Icons.close,
                                    size: 20,
                                  )
                                : const Text("GO"),
                          );
                        }
                      }()),
                    ),
                  ),
                  (() {
                    if (_activeJourney != null) {
                      return OngoingJourneyPopup(
                        activeJourney: _activeJourney,
                        onDropOff: onJourneyDropOff,
                        onPickUp: onJourneyPickUp,
                      );
                    } else {
                      return JourneyRequestPopup(
                        isSearching: _isSearching,
                        journey: _availableJourneySnapshot,
                        routeDistance: MapHelper.calculateRouteDistance(mapViewState.polylines.firstOrNull),
                        onNavigate: (direction) async {
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
                          if (newJourneyRequest.size > 0 &&
                              newJourneyRequest.docs.first.id != _availableJourneySnapshot!.id) {
                            updateJourneyRoutePolylines(newJourneyRequest.docs.first.data());
                            setState(() {
                              _availableJourneySnapshot = newJourneyRequest.docs.first;
                            });
                          }
                        },
                        onAccept: onJourneyAccept,
                      );
                    }
                  }()),
                ],
              ),
      ),
    );
  }
}
