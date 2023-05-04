import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../util/location_helpers.dart';
import '../../../util/map_helper.dart';

class MapViewState extends ChangeNotifier {
  /*
  * Variables
  * */
  bool _shouldCenter = true;
  final _newMapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _locationListener;
  final Set<Polyline> _polylines = <Polyline>{};
  final Map<String, Marker> _markers = <String, Marker>{};


  /*
  * Functions
  * */
  void resetMap() {
    _shouldCenter = true;
    _polylines.clear();
    _markers.clear();
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
        final newLatLng = LatLng(latLng.latitude, latLng.longitude);
        _currentPosition = newLatLng;
        _markers["user"] = Marker(
            point: newLatLng, builder: (context) => const Icon(Icons.account_circle_rounded, size: 35));

        if (_shouldCenter) {
          MapHelper.resetCamera(_newMapController, _currentPosition);
        }
        notifyListeners();
      });
    }
  }

  /*
  * Getters
  * */
  LatLng? get currentPosition => _currentPosition;

  Map<String, Marker> get markers => _markers;

  MapController get mapController => _newMapController;

  Set<Polyline> get polylines => _polylines;

  bool get shouldCenter => _shouldCenter;

  /*
  * Setters
  * */

  set shouldCenter(bool value) {
    _shouldCenter = value;
    notifyListeners();
  }
}
