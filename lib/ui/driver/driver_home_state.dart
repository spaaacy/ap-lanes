import 'dart:async';
import 'dart:ui';

import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/components/setup_driver_profile_dialog.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/model/remote/driver.dart';
import '../../../data/model/remote/journey.dart';
import '../../../data/model/remote/user.dart';
import '../../../data/repo/driver_repo.dart';
import '../../../data/repo/journey_repo.dart';
import '../../../data/repo/user_repo.dart';
import '../../../services/place_service.dart';

// this will be used as notification channel id
const notificationChannelId = 'driver_location_updater';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await Firebase.initializeApp();
  Timer.periodic(const Duration(seconds: 15), (Timer t) async {
    final String? driverDocPath = preferences.getString("driverPath");
    if (driverDocPath == null) return;

    var driverDoc = FirebaseFirestore.instance.doc(driverDocPath);
    debugPrint('in driverLocationUpdater.executeTask().Timer.periodic()');
    var pos = await Geolocator.getCurrentPosition();
    driverDoc.update({'currentLatLng': '${pos.latitude}, ${pos.longitude}'});
  });
}

class DriverHomeState extends ChangeNotifier {
  late final MapViewState mapViewState;
  late final BuildContext context;
  firebase_auth.User? firebaseUser;

  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<User>? _activeJourneyPassenger;
  QueryDocumentSnapshot<Driver>? _driver;
  QueryDocumentSnapshot<Journey>? _activeJourney;
  QueryDocumentSnapshot<Journey>? _availableJourneySnapshot;
  QueryDocumentSnapshot<User>? _availableJourneyPassenger;

  StreamSubscription<QuerySnapshot<Journey>>? _activeJourneyListener;
  StreamSubscription<Position>? _driverLocationListener;

  bool _isSearching = false;

  final _userRepo = UserRepo();
  final _driverRepo = DriverRepo();
  final _journeyRepo = JourneyRepo();
  final _placeService = PlaceService();

  @override
  void dispose() async {
    super.dispose();
    await _activeJourneyListener?.cancel();
    _unregisterDriverLocationBackgroundService();
    _unregisterDriverLocationListener();
  }

  Future<void> initialize(BuildContext context) async {
    this.context = context;
    mapViewState = context.read<MapViewState>();
    initializeFirestore();
  }

  Future<void> _registerDriverLocationListener() async {
    _driverLocationListener ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);

      LatLng targetLatLng =
      _activeJourney!.data().isPickedUp ? _activeJourney!.data().endLatLng : _activeJourney!.data().startLatLng;
      updateCameraBoundsWithPopup(latLng, targetLatLng);
    });
  }

  void _unregisterDriverLocationListener() {
    _driverLocationListener?.cancel();
    _driverLocationListener = null;
  }

  void updateCameraBoundsWithPopup(LatLng start, LatLng end) {
    mapViewState.shouldCenter = false;
    MapHelper.setCameraBetweenMarkers(
      mapController: mapViewState.mapController,
      firstLatLng: start,
      secondLatLng: end,
      topOffsetPercentage: 1,
      bottomOffsetPercentage: 0.2,
    );
  }

  Future<void> initializeFirestore() async {
    firebaseUser = context.read<firebase_auth.User?>();
    if (firebaseUser == null) return;

    var userData = await _userRepo.getUser(firebaseUser!.uid);
    user = userData;

    var driverData = await _driverRepo.getDriver(firebaseUser!.uid);
    if (driverData != null) {
      driver = driverData;
      // todo: maybe make this check for ongoing journeys instead
      isSearching = _driver
          ?.data()
          .isAvailable == true;
    } else {
      if (!context.mounted) return;

      var result = await showDialog<String?>(
        context: context,
        builder: (ctx) => SetupDriverProfileDialog(userId: firebaseUser!.uid),
      );

      if (result == 'Save') {
        var driverSnapshot = await _driverRepo.getDriver(firebaseUser!.uid);
        driver = driverSnapshot;
      } else {
        if (!context.mounted) return;

        await showDialog(
          context: context,
          builder: (ctx) =>
              AlertDialog(
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
        context
            .read<UserWrapperState>()
            .userMode = UserMode.passengerMode;
      }
    }

    bool hasOngoingJourney = await _journeyRepo.hasOngoingJourney(firebaseUser!.uid);
    if (hasOngoingJourney) {
      startOngoingJourneyListener();
    }
  }

  void _unregisterDriverLocationBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
  }

  void _registerDriverLocationBackgroundService() async {
    final service = FlutterBackgroundService();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString("driverPath", driver!.reference.path);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'APLanes', // title
      description: 'Driver location is being updated periodically.', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'APLanes',
        initialNotificationContent: 'Driver location is periodically being updated.',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
      ),
    );
  }

  void startOngoingJourneyListener() async {
    await activeJourneyListener?.cancel();

    activeJourneyListener = _journeyRepo.getOngoingJourneyStream(firebaseUser!.uid).listen((ss) async {
      if (ss.size > 0) {
        _registerDriverLocationBackgroundService();

        _registerDriverLocationListener();
        activeJourney = ss.docs.first;

        activeJourneyPassenger = await _userRepo.getUser(_activeJourney!.data().userId);

        if (_activeJourney!.data().isPickedUp) {
          mapViewState.markers[const MarkerId("drop-off")] = Marker(
            markerId: const MarkerId("drop-off"),
            position: _activeJourney!.data().endLatLng,
            icon: mapViewState.locationIcon!,
          );
          updateCameraBoundsWithPopup(mapViewState.currentPosition!, _activeJourney!.data().endLatLng);
        } else {
          mapViewState.markers[const MarkerId("pick-up")] = Marker(
            markerId: const MarkerId("pick-up"),
            position: _activeJourney!.data().startLatLng,
            icon: mapViewState.locationIcon!,
          );
          updateCameraBoundsWithPopup(mapViewState.currentPosition!, _activeJourney!.data().startLatLng);
        }
      } else {
        _unregisterDriverLocationBackgroundService();
        if (_activeJourney != null) {
          var previousJourney = await _activeJourney!.reference.get();
          if (previousJourney.exists && previousJourney.data()!.isCancelled) {
            _activeJourneyListener?.cancel();
            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      title: const Text("Journey Cancelled"),
                      content: const Text("The journey has been cancelled by the passenger."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            textStyle: Theme
                                .of(context)
                                .textTheme
                                .labelLarge,
                          ),
                          child: const Text("Ok"),
                        )
                      ],
                    ),
              );
            }
          }
        }
        mapViewState.markers.remove(const MarkerId("drop-off"));
        mapViewState.markers.remove(const MarkerId("pick-up"));
        mapViewState.shouldCenter = true;
        activeJourney = null;
        availableJourneySnapshot = null;
        availableJourneyPassenger = null;
        _unregisterDriverLocationListener();
        MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition);
        notifyListeners();
      }
    });
  }

  void onJourneyDropOff() async {
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

      mapViewState.markers.remove(const MarkerId("drop-off"));
      mapViewState.markers.remove(const MarkerId("pick-up"));
      mapViewState.shouldCenter = true;
      activeJourney = null;

      MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition!);
      availableJourneySnapshot = null;
      availableJourneyPassenger = null;
      notifyListeners();
      _unregisterDriverLocationBackgroundService();
      _unregisterDriverLocationListener();
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

  void onJourneyPickUp() async {
    try {
      bool isPickedUp = await _journeyRepo.updateJourneyPickUpStatus(activeJourney);
      if (isPickedUp) {
        mapViewState.markers.remove(const MarkerId("pick-up"));
        mapViewState.markers[const MarkerId("pick-up")] = Marker(
          markerId: const MarkerId("pick-up"),
          position: activeJourney!.data().endLatLng,
          icon: mapViewState.locationIcon!,
        );
        updateCameraBoundsWithPopup(mapViewState.currentPosition!, activeJourney!.data().endLatLng);
      } else {
        mapViewState.markers.remove(const MarkerId("drop-off"));
        mapViewState.markers[const MarkerId("pick-up")] = Marker(
          markerId: const MarkerId("pick-up"),
          position: activeJourney!.data().startLatLng,
          icon: mapViewState.locationIcon!,
        );
        updateCameraBoundsWithPopup(mapViewState.currentPosition!, activeJourney!.data().startLatLng);
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

  void onJourneyAccept() async {
    try {
      await _journeyRepo.acceptJourneyRequest(_availableJourneySnapshot!, firebaseUser!.uid);

      toggleIsSearching();

      mapViewState.polylines.clear();
      mapViewState.markers.remove(const MarkerId("start"));
      mapViewState.markers.remove(const MarkerId("destination"));

      startOngoingJourneyListener();
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

  void onRequestPopupNavigate(int direction) async {
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
    if (newJourneyRequest.size > 0 && newJourneyRequest.docs.first.id != _availableJourneySnapshot!.id) {
      updateJourneyRoutePolylines(newJourneyRequest.docs.first.data());
      availableJourneySnapshot = newJourneyRequest.docs.first;
      availableJourneyPassenger = await _userRepo.getUser(_availableJourneySnapshot!.data().userId);
    }
  }

  void updateJourneyRoutePolylines(Journey journey) {
    final start = journey.startLatLng;
    final end = journey.endLatLng;
    _placeService.fetchRoute(start, end).then((polylines) {
      mapViewState.polylines.clear();
      mapViewState.polylines.add(polylines);
      MapHelper.setCameraToRoute(
        mapController: mapViewState.mapController,
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
      mapViewState.notifyListeners();
      notifyListeners();
    });
  }

  Future<void> updateJourneyRequestListener() async {
    toggleIsSearching();
    mapViewState.polylines.clear();
    mapViewState.markers.remove(const MarkerId("start"));
    mapViewState.markers.remove(const MarkerId("destination"));

    if (_isSearching) {
      StreamSubscription<QuerySnapshot<Journey>>? journeyListener;
      journeyListener = _journeyRepo.getFirstJourneyRequest(firebaseUser!.uid).listen((nextJourneySnapshot) async {
        if (nextJourneySnapshot.size > 0) {
          journeyListener?.cancel();
          updateJourneyRoutePolylines(nextJourneySnapshot.docs.first.data());
          availableJourneySnapshot = nextJourneySnapshot.docs.first;
          availableJourneyPassenger = await _userRepo.getUser(availableJourneySnapshot!.data().userId);
        }
      });
    } else {
      availableJourneySnapshot = null;
      availableJourneyPassenger = null;
      MapHelper.resetCamera(mapViewState.mapController, mapViewState.currentPosition);
    }
  }

  void toggleIsSearching() {
    _driverRepo.updateDriver(driver!, {'isAvailable': !isSearching});
    isSearching = !isSearching;
    mapViewState.shouldCenter = !isSearching;
  }

  //region getters and setters
  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get activeJourneyPassenger => _activeJourneyPassenger;

  set activeJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _activeJourneyPassenger = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Driver>? get driver => _driver;

  set driver(QueryDocumentSnapshot<Driver>? value) {
    _driver = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get activeJourney => _activeJourney;

  set activeJourney(QueryDocumentSnapshot<Journey>? value) {
    _activeJourney = value;
    notifyListeners();
  }

  bool get isSearching => _isSearching;

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Journey>? get availableJourneySnapshot => _availableJourneySnapshot;

  set availableJourneySnapshot(QueryDocumentSnapshot<Journey>? value) {
    _availableJourneySnapshot = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get availableJourneyPassenger => _availableJourneyPassenger;

  set availableJourneyPassenger(QueryDocumentSnapshot<User>? value) {
    _availableJourneyPassenger = value;
    notifyListeners();
  }

  StreamSubscription<QuerySnapshot<Journey>>? get activeJourneyListener => _activeJourneyListener;

  set activeJourneyListener(StreamSubscription<QuerySnapshot<Journey>>? value) {
    _activeJourneyListener = value;
    notifyListeners();
  }

//endregion
}
