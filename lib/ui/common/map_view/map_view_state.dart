import 'dart:async';

import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../util/constants.dart';
import '../../../util/location_helpers.dart';
import '../../../util/map_helper.dart';

class MapViewState extends ChangeNotifier {
  /*
  * Variables
  * */
  late final UserMode _userMode;
  GoogleMapController? _mapController;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _locationIcon;
  bool _shouldCenter = true;
  LatLng? _currentPosition;
  final Set<Polyline> _polylines = <Polyline>{};
  final Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  late String _mapStyle;
  StreamSubscription<Position>? _locationListener;

  /*
  * Functions
  * */
  void resetMap() {
    _mapController = null;
    _shouldCenter = true;
    _polylines.clear();
    _markers.clear();
  }

  void onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    controller.setMapStyle(_mapStyle);
  }

  @override
  void dispose() {
    _locationListener?.cancel();
    super.dispose();
  }

  Future<void> initialize(BuildContext context) async {
    _userMode = context.read<UserWrapperState>().userMode;
    _mapStyle = await rootBundle.loadString('assets/map_style.txt');
    _userIcon = await MapHelper.getCustomIcon('assets/icons/user.png', userIconSize);
    _driverIcon = await MapHelper.getCustomIcon('assets/icons/driver.png', driverIconSize);
    _locationIcon = await MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize);
    if (context.mounted) {
      initializeLocation(context);
    }
  }

  void initializeLocation(BuildContext context) async {
    final hasPermissions = await handleLocationPermission(context);

    if (hasPermissions) {
      _locationListener = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      ).listen((position) {
        final latLng = LatLng(position.latitude, position.longitude);
        _currentPosition = latLng;
        _markers[const MarkerId("user")] = Marker(
          markerId: const MarkerId("user"),
          position: _currentPosition!,
          icon: _userIcon!,
        );

        if (_shouldCenter) {
          MapHelper.resetCamera(_mapController, _currentPosition);
        }
        notifyListeners();
      });
    }
  }

  /*
  * Getters
  * */
  GoogleMapController? get mapController => _mapController;

  BitmapDescriptor? get userIcon => _userIcon;

  BitmapDescriptor? get driverIcon => _driverIcon;

  BitmapDescriptor? get locationIcon => _locationIcon;

  String get mapStyle => _mapStyle;

  Map<MarkerId, Marker> get markers => _markers;

  Set<Polyline> get polylines => _polylines;

  LatLng? get currentPosition => _currentPosition;

  bool get shouldCenter => _shouldCenter;

  /*
  * Setters
  * */
  set mapController(GoogleMapController? value) {
    _mapController = value;
    notifyListeners();
  }

  set userIcon(BitmapDescriptor? value) {
    _userIcon = value;
    notifyListeners();
  }

  set driverIcon(BitmapDescriptor? value) {
    _driverIcon = value;
    notifyListeners();
  }

  set locationIcon(BitmapDescriptor? value) {
    _locationIcon = value;
    notifyListeners();
  }

  set mapStyle(String value) {
    _mapStyle = value;
    notifyListeners();
  }

  set currentPosition(LatLng? value) {
    _currentPosition = value;
    notifyListeners();
  }

  set shouldCenter(bool value) {
    _shouldCenter = value;
    notifyListeners();
  }
}
