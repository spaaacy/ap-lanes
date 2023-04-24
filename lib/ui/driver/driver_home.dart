import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../data/model/firestore/driver.dart';
import '../../data/model/firestore/journey.dart';
import '../../data/model/firestore/user.dart';
import '../../data/repo/driver_repo.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../util/constants.dart';
import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view.dart';
import '../passenger/passenger_home.dart';
import 'components/journey_request_popup.dart';
import 'components/ongoing_journey_popup.dart';
import 'components/setup_driver_profile_dialog.dart';
import 'state/driver_home_state.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _isSearching = false;
  DocumentSnapshot<Journey>? _activeJourney;
  late final firebase_auth.User? firebaseUser;
  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Driver>? _driver;
  QueryDocumentSnapshot<Journey>? _availableJourneySnapshot;
  late StreamSubscription<QuerySnapshot<Journey>> _activeJourneyListener;
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = <Polyline>{};
  late final BitmapDescriptor _locationIcon; // Use this for location markers
  late final BitmapDescriptor _driverIcon;
  bool _shouldCenter = true;
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  LatLng? _currentPosition;
  late StreamSubscription<Position> _locationListener;

  void updateJourneyRoutePolylines(Journey journey) {
    final start = journey.startLatLng;
    final end = journey.endLatLng;
    MapHelper.drawRoute(start, end).then((polylines) {
      setState(() {
        _polylines.clear();
        _polylines.add(polylines);
        MapHelper.setCameraToRoute(
          mapController: _mapController!,
          polylines: _polylines,
          topOffsetPercentage: 1,
          bottomOffsetPercentage: 0.2,
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
      });
    });
  }

  Future<void> _updateJourneyRequestListener() async {
    _polylines.clear();
    _markers.remove(const MarkerId("start"));
    _markers.remove(const MarkerId("destination"));

    if (_isSearching) {
      final nextJourneySnapshot = await _journeyRepo.getFirstJourneyRequest(firebaseUser!.uid);
      if (nextJourneySnapshot.size > 0) {
        updateJourneyRoutePolylines(nextJourneySnapshot.docs.first.data());
        setState(() {
          _availableJourneySnapshot = nextJourneySnapshot.docs.first;
        });
      }
    } else {
      MapHelper.resetCamera(_mapController, _currentPosition);
    }
  }

  @override
  initState() {
    super.initState();

    if (mounted) {
      _locationListener = MapHelper.getCurrentPosition(context).listen((position) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = latLng;
          _markers[const MarkerId("driver-marker")] = Marker(
            markerId: const MarkerId("driver-marker"),
            position: _currentPosition!,
            icon: _driverIcon,
          );

          if (_activeJourney == null) {
            if (_shouldCenter) {
              MapHelper.resetCamera(_mapController, _currentPosition!);
            }
          } else {
            LatLng targetLatLng = _activeJourney!.data()!.isPickedUp
                ? _activeJourney!.data()!.endLatLng
                : _activeJourney!.data()!.startLatLng;
            updateCameraBoundsWithPopup(latLng, targetLatLng);
          }
        });
      });
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _locationIcon = await MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize);
      _driverIcon = await MapHelper.getCustomIcon('assets/icons/driver.png', userIconSize);

      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _activeJourneyListener = _journeyRepo.getOngoingJourney(firebaseUser!.uid).listen((ss) {
          if (ss.size > 0) {
            setState(() {
              _activeJourney = ss.docs.first;

              if (_activeJourney!.data()!.isPickedUp) {
                _markers[const MarkerId("drop-off")] = Marker(
                  markerId: const MarkerId("drop-off"),
                  position: _activeJourney!.data()!.endLatLng,
                  icon: _locationIcon,
                );
                updateCameraBoundsWithPopup(_currentPosition, _activeJourney!.data()!.endLatLng);
              } else {
                _markers[const MarkerId("pick-up")] = Marker(
                  markerId: const MarkerId("pick-up"),
                  position: _activeJourney!.data()!.startLatLng,
                  icon: _locationIcon,
                );
                updateCameraBoundsWithPopup(_currentPosition, _activeJourney!.data()!.startLatLng);
              }
            });
          } else {
            setState(() {
              _markers.remove(const MarkerId("drop-off"));
              _markers.remove(const MarkerId("pick-up"));
              _activeJourney = null;
            });
          }
        });

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
          if (!context.mounted) return;
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
            if (!context.mounted) return;

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

            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) => const PassengerHome(),
              ),
              (_) => false,
            );
          }
        }
      }
    });
  }

  void updateCameraBoundsWithPopup(LatLng? latLng, LatLng? otherLatLng) {
    if (latLng == null || otherLatLng == null) {
      return;
    }
    MapHelper.setCameraBetweenMarkers(
      mapController: _mapController,
      firstLatLng: latLng,
      secondLatLng: otherLatLng,
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
  }

  @override
  void dispose() {
    _activeJourneyListener.cancel();
    _locationListener.cancel();
    super.dispose();
  }

  void toggleIsSearching() {
    _driverRepo.updateDriver(_driver!, {'isAvailable': !_isSearching});
    setState(() {
      _isSearching = !_isSearching;
    });
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (activeJourney == null) return;

        var ss = await transaction.get<Journey>(activeJourney.reference);
        if (!ss.exists) {
          throw Exception("Error occurred when trying to update drop-off status of given Journey.");
        }

        if (ss.data()!.isCompleted) {
          throw Exception("Cannot update drop-off status of completed Journey.");
        }

        transaction.update(ss.reference, {'isCompleted': true, 'isPickedUp': true});

        _markers.remove(const MarkerId("drop-off"));
        _markers.remove(const MarkerId("pick-up"));
        MapHelper.resetCamera(_mapController, _currentPosition!);
      });
    }

    void onJourneyPickUp(DocumentSnapshot<Journey>? activeJourney) async {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (activeJourney == null) return;

        var ss = await transaction.get<Journey>(activeJourney.reference);
        if (!ss.exists) {
          throw Exception("Error occurred when trying to update picked-up status of given Journey.");
        }

        if (ss.data()!.isCompleted) {
          throw Exception("Cannot update picked-up status of completed Journey.");
        }

        if (ss.data()!.isPickedUp) {
          transaction.update(ss.reference, {'isPickedUp': false});
          setState(() {
            _markers.remove(const MarkerId("drop-off"));
            _markers[const MarkerId("pick-up")] = Marker(
              markerId: const MarkerId("pick-up"),
              position: ss.data()!.startLatLng,
              icon: _locationIcon,
            );
            updateCameraBoundsWithPopup(_currentPosition, ss.data()!.startLatLng);
          });
        } else {
          transaction.update(ss.reference, {'isPickedUp': true});
          setState(() {
            _markers.remove(const MarkerId("pick-up"));
            _markers[const MarkerId("pick-up")] = Marker(
              markerId: const MarkerId("pick-up"),
              position: ss.data()!.endLatLng,
              icon: _locationIcon,
            );
            updateCameraBoundsWithPopup(_currentPosition, ss.data()!.endLatLng);
          });
        }
      });
    }

    void onJourneyAccept(QueryDocumentSnapshot<Journey> acceptedJourney) async {
      try {
        DocumentSnapshot<Journey>? updatedJourney =
            await FirebaseFirestore.instance.runTransaction((transaction) async {
          var ss = await transaction.get<Journey>(acceptedJourney.reference);
          if (!ss.exists) {
            throw Exception("Journey does not exist!");
          }

          if (ss.data()!.isCompleted || ss.data()!.driverId.isNotEmpty) {
            throw Exception("Journey already has a driver!");
          }

          transaction.update(ss.reference, {'driverId': firebaseUser!.uid});

          toggleIsSearching();

          return ss;
        });
        setState(() {
          _polylines.clear();
          _markers.remove(const MarkerId("start"));
          _markers.remove(const MarkerId("destination"));
          _activeJourney = updatedJourney;
          _markers[const MarkerId("pick-up")] = Marker(
            markerId: const MarkerId("pick-up"),
            position: updatedJourney!.data()!.startLatLng,
            icon: _locationIcon,
          );
          updateCameraBoundsWithPopup(_currentPosition, updatedJourney.data()!.startLatLng);
        });
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("A problem occurred when accepting this request: $e"),
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
        ..mapController = _mapController
        ..activeJourney = _activeJourney
        ..polylines = _polylines,
      child: Scaffold(
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
            MapView(
              userLatLng: _currentPosition,
              markers: _markers,
              polylines: _polylines,
              mapController: _mapController,
              setMapController: (controller) => setState(() {
                _mapController = controller;
              }),
              setShouldCenter: (shouldCenter) {
                setState(() {
                  _shouldCenter = shouldCenter;
                });
              },
            ),
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
                  routeDistance: MapHelper.calculateRouteDistance(_polylines.firstOrNull),
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
