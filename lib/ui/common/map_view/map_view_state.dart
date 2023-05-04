import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import '../../../util/constants.dart';
import '../../../util/location_helpers.dart';
import '../../../util/map_helper.dart';

class MapViewState extends ChangeNotifier {
  /*
  * Variables
  * */
  GoogleMapController? _mapController;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _locationIcon;
  bool _shouldCenter = true;
  LatLng? _currentPosition;
  latlong2.LatLng? _newCurrentPosition;
  final Set<Polyline> _polylines = <Polyline>{};
  late String _mapStyle;
  StreamSubscription<Position>? _locationListener;

  // Flutter map variables
  final _newMapController = flutter_map.MapController();
  final Map<String, flutter_map.Marker> _newMarkers = <String, flutter_map.Marker>{};


  /*
  * Functions
  * */
  void resetMap() {
    _mapController = null;
    _shouldCenter = true;
    _polylines.clear();
    _newMarkers.clear();
  }

  @override
  void dispose() {
    _locationListener?.cancel();
    super.dispose();
  }

  void initializeLocation(BuildContext context) async {
    final hasPermissions = await handleLocationPermission(context);

    if (hasPermissions) {
      _locationListener = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      ).listen((position) async {
        final latLng = LatLng(position.latitude, position.longitude);
        final newLatLng = latlong2.LatLng(latLng.latitude, latLng.longitude);
        _currentPosition = latLng;
        _newCurrentPosition = newLatLng;
        _newMarkers["user"] = flutter_map.Marker(
            point: newLatLng, builder: (context) => const Icon(Icons.account_circle_rounded, size: 35));

        if (_shouldCenter) {
          MapHelper.resetCamera(_newMapController, _newCurrentPosition);
        }
        notifyListeners();
      });
    }
  }

  /*
  * Getters
  * */
  latlong2.LatLng? get newCurrentPosition => _newCurrentPosition;

  Map<String, flutter_map.Marker> get newMarkers => _newMarkers;

  flutter_map.MapController get newMapController => _newMapController;

  GoogleMapController? get mapController => _mapController;

  BitmapDescriptor? get userIcon => _userIcon;

  BitmapDescriptor? get driverIcon => _driverIcon;

  BitmapDescriptor? get locationIcon => _locationIcon;

  String get mapStyle => _mapStyle;

  Set<Polyline> get polylines => _polylines;

  LatLng? get currentPosition => _currentPosition;

  bool get shouldCenter => _shouldCenter;

  /*
  * Setters
  * */

  set newCurrentPosition(latlong2.LatLng? value) {
    _newCurrentPosition = value;
    notifyListeners();
  }

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
