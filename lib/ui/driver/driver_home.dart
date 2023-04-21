import 'dart:async';

import 'package:apu_rideshare/data/model/map/marker_info.dart';
import 'package:apu_rideshare/data/repo/driver_repo.dart';
import 'package:apu_rideshare/data/repo/journey_repo.dart';
import 'package:apu_rideshare/ui/driver/state/driver_home_state.dart';
import 'package:apu_rideshare/util/greeting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/driver.dart';
import '../../data/model/firestore/journey.dart';
import '../../data/model/firestore/user.dart';
import '../../data/repo/user_repo.dart';
import '../../util/constants.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view.dart';
import '../passenger/passenger_home.dart';
import 'components/journey_request_popup.dart';
import 'components/ongoing_journey_popup.dart';
import 'components/setup_driver_profile_dialog.dart';

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
  StreamSubscription<QuerySnapshot<Journey>>? _journeyRequestListener;
  int _currentJourneyRequestIndex = 0;
  QuerySnapshot<Journey>? _availableJourneysSnapshot;
  late StreamSubscription<QuerySnapshot<Journey>> _activeJourneyListener;
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = <Polyline>{};
  late final BitmapDescriptor _locationIcon; // Use this for location markers
  late final BitmapDescriptor _driverIcon;
  bool _shouldCenter = true;
  final Set<MarkerInfo> _markers = {};
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
          padding: 25,
          verticalOffset: 0.015,
        );
        _markers.removeWhere((e) => e.markerId == "start" || e.markerId == "destination");
        _markers.add(MarkerInfo(markerId: "start", position: start));
        _markers.add(MarkerInfo(markerId: "destination", position: end));
      });
    });
  }

  void _updateJourneyRequestListener() {
    _polylines.clear();
    _markers.removeWhere((e) => e.markerId == "start" || e.markerId == "destination");
    MapHelper.resetCamera(_mapController, _currentPosition!);

    if (_journeyRequestListener != null) {
      _journeyRequestListener!.cancel();
    }

    if (_isSearching) {
      _journeyRequestListener = _journeyRepo.getJourneyRequestStream(firebaseUser!.uid).listen((journeySnapshot) {
        if (_currentJourneyRequestIndex > journeySnapshot.size - 1) {
          setState(() {
            _currentJourneyRequestIndex = 0;
          });
        }

        setState(() {
          _availableJourneysSnapshot = journeySnapshot;
          if (journeySnapshot.size > 0) {
            updateJourneyRoutePolylines(journeySnapshot.docs.elementAt(_currentJourneyRequestIndex).data());
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Google Map Variable Initialization
    MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize).then(
      (icon) => setState(() => _locationIcon = icon),
    );
    MapHelper.getCustomIcon('assets/icons/driver.png', driverIconSize).then(
      (icon) => setState(() => _driverIcon = icon),
    );
    _locationListener = MapHelper.getCurrentPosition(context).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _markers.removeWhere((element) => element.markerId == "driver-marker");
        _markers.add(MarkerInfo(markerId: "driver-marker", position: _currentPosition!, icon: _driverIcon));

        if (_activeJourney == null) {
          if (_shouldCenter) {
            MapHelper.resetCamera(_mapController, _currentPosition!);
          }
        } else {
          LatLng targetLatLng = _activeJourney!.data()!.isPickedUp
              ? _activeJourney!.data()!.endLatLng
              : _activeJourney!.data()!.startLatLng;

          MapHelper.setCameraBetweenMarkers(
            mapController: _mapController,
            firstLatLng: latLng,
            secondLatLng: targetLatLng,
            verticalOffset: 0.015,
            padding: 10,
          );
        }
      });
    });

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _activeJourneyListener = _journeyRepo.getOngoingJourney(firebaseUser!.uid).listen((ss) {
          if (ss.size > 0) {
            setState(() {
              _activeJourney = ss.docs.first;

              if (_activeJourney!.data()!.isPickedUp) {
                _markers.add(MarkerInfo(markerId: "drop-off", position: _activeJourney!.data()!.endLatLng));
                MapHelper.setCameraBetweenMarkers(
                  mapController: _mapController,
                  firstLatLng: _currentPosition!,
                  secondLatLng: _activeJourney!.data()!.endLatLng,
                  padding: 100,
                );
              } else {
                _markers.add(MarkerInfo(markerId: "pick-up", position: _activeJourney!.data()!.startLatLng));
                MapHelper.setCameraBetweenMarkers(
                  mapController: _mapController,
                  firstLatLng: _currentPosition!,
                  secondLatLng: _activeJourney!.data()!.startLatLng,
                  padding: 100,
                );
              }
            });
          } else {
            setState(() {
              _markers.removeWhere((e) => e.markerId == "drop-off" || e.markerId == "pick-up");
              _activeJourney = null;
            });
          }
        });

        var userData = await _userRepo.getUser(firebaseUser!.uid);
        setState(() {
          _user = userData;
        });
        try {
          var driverData = await _driverRepo.getDriver(firebaseUser!.uid);
          setState(() {
            _driver = driverData;
            // todo: maybe make this check for ongoing journeys instead
            _isSearching = _driver?.data().isAvailable == true;

            _updateJourneyRequestListener();
          });
        } catch (e) {
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

  @override
  void dispose() {
    _journeyRequestListener?.cancel();
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

        _markers.removeWhere((e) => e.markerId == "pick-up" || e.markerId == "drop-off");
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
            _markers.removeWhere((e) => e.markerId == "drop-off");
            _markers.add(MarkerInfo(markerId: "pick-up", position: ss.data()!.startLatLng));
            MapHelper.setCameraBetweenMarkers(
              mapController: _mapController,
              firstLatLng: _currentPosition!,
              secondLatLng: ss.data()!.startLatLng,
              padding: 100,
              verticalOffset: 0.0075,
            );
          });
        } else {
          transaction.update(ss.reference, {'isPickedUp': true});
          setState(() {
            _markers.removeWhere((e) => e.markerId == "pick-up");
            _markers.add(MarkerInfo(markerId: "drop-off", position: ss.data()!.endLatLng));
            MapHelper.setCameraBetweenMarkers(
              mapController: _mapController,
              firstLatLng: _currentPosition!,
              secondLatLng: ss.data()!.endLatLng,
              padding: 100,
              verticalOffset: 0.0075,
            );
          });
        }
      });
    }

    void onJourneyAccept(QueryDocumentSnapshot<Journey> acceptedJourney) async {
      toggleIsSearching();
      await _journeyRequestListener?.cancel();

      try {
        DocumentSnapshot<Journey>? updatedJourney =
            await FirebaseFirestore.instance.runTransaction((transaction) async {
          if (_availableJourneysSnapshot == null || _availableJourneysSnapshot?.size == 0) {
            return null;
          }

          var ss = await transaction.get<Journey>(acceptedJourney.reference);
          if (!ss.exists) {
            throw Exception("Journey does not exist!");
          }

          if (ss.data()!.isCompleted || ss.data()!.driverId.isNotEmpty) {
            throw Exception("Journey already has a driver!");
          }

          transaction.update(ss.reference, {'driverId': firebaseUser!.uid});

          return ss;
        });
        setState(() {
          _polylines.clear();
          _markers.removeWhere((e) => e.markerId == "start" || e.markerId == "destination");
          _activeJourney = updatedJourney;
          _markers.add(MarkerInfo(markerId: "pick-up", position: updatedJourney!.data()!.startLatLng));
          MapHelper.setCameraBetweenMarkers(
            mapController: _mapController,
            firstLatLng: _currentPosition!,
            secondLatLng: updatedJourney.data()!.startLatLng,
            padding: 50,
          );
        });
      } catch (e) {
        print("Failed to accept journey request: $e");

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
            Greeting.getGreeting(_user?.data().lastName),
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
                  journey: _availableJourneysSnapshot?.size != 0
                      ? _availableJourneysSnapshot?.docs.elementAt(_currentJourneyRequestIndex)
                      : null,
                  onNavigate: (direction) {
                    if (_availableJourneysSnapshot != null) {
                      setState(() {
                        _currentJourneyRequestIndex =
                            (_currentJourneyRequestIndex + direction) % _availableJourneysSnapshot!.size;
                        updateJourneyRoutePolylines(
                          _availableJourneysSnapshot!.docs.elementAt(_currentJourneyRequestIndex).data(),
                        );
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
