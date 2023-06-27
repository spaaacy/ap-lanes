import 'dart:async';

import 'package:ap_lanes/ui/common/map_view/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../util/location_helpers.dart';

class MapViewState2 extends ChangeNotifier {
  MapViewState2(BuildContext context) {
    initializeLocation(context);
  }

  /*
  * Variables
  * */
  bool _shouldCenter = true;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _locationListener;
  final Set<Polyline> _polylines = <Polyline>{};
  final Map<String, Marker> _markers = <String, Marker>{};
  bool isMapReady = false;
  MapViewState1? mapView;
  final MapController _mapController = MapController();

  /*
  * Functions
  * */
  void initializeLocation(BuildContext context) async {
    // Ensures user has given permission to use phone's location
    final hasPermissions = await handleLocationPermission(context);

    if (hasPermissions) {
      _locationListener = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation),
      ).listen((position) async {
        final latLng = LatLng(position.latitude, position.longitude);
        _currentPosition = latLng;
        // Updates user location icon on map
        _markers["user"] = Marker(
            point: latLng,
            builder: (context) => const Icon(Icons.account_circle_rounded,
                size: 35, color: Colors.black));
        notifyListeners();

        if (_shouldCenter) {
          // Recenter map camera to user's location
          resetCamera();
        }
      });
    }
  }

  Future<void> resetCamera() async {
    if (!isMapReady || currentPosition == null) return;
    mapView?.animateCamera(_currentPosition!, 17.0);
  }

  void setCameraBetweenMarkers({
    required LatLng firstLatLng,
    required LatLng secondLatLng,
    double topOffsetPercentage = 0,
    double bottomOffsetPercentage = 0,
    double leftOffsetPercentage = 0,
    double rightOffsetPercentage = 0,
  }) {
    if (!isMapReady) return;

    double minLat = firstLatLng.latitude;
    double minLng = firstLatLng.longitude;
    double maxLat = secondLatLng.latitude;
    double maxLng = secondLatLng.longitude;

    // Finds the smallest and largest latitude and longitude
    if (secondLatLng.latitude < minLat) {
      maxLat = minLat;
      minLat = secondLatLng.latitude;
    }
    if (secondLatLng.longitude < minLng) {
      maxLng = minLng;
      minLng = secondLatLng.longitude;
    }

    // Calculates the difference between the smallest and largest lat, lng
    // Uses difference to calculate lat, lng to add/subtract to initial values
    final latDifference = maxLat - minLat;
    final topOffsetValue = latDifference * topOffsetPercentage;
    final bottomOffsetValue = latDifference * bottomOffsetPercentage;

    final lngDifference = maxLat - minLat;
    final leftOffsetValue = lngDifference * leftOffsetPercentage;
    final rightOffsetValue = lngDifference * rightOffsetPercentage;

    // Passes lat, lng range to map camera
    final bounds = LatLngBounds(
      LatLng(minLat - bottomOffsetValue, minLng - leftOffsetValue),
      LatLng(maxLat + topOffsetValue, maxLng + rightOffsetValue),
    );

    final centerZoom = _mapController.centerZoomFitBounds(bounds);

    mapView?.animateCamera(centerZoom.center, centerZoom.zoom);
  }

  void setCameraToRoute({
    double topOffsetPercentage = 0,
    double bottomOffsetPercentage = 0,
    double leftOffsetPercentage = 0,
    double rightOffsetPercentage = 0,
  }) {
    if (!isMapReady) return;

    double minLat = _polylines.first.points.first.latitude;
    double minLng = _polylines.first.points.first.longitude;
    double maxLat = _polylines.first.points.first.latitude;
    double maxLng = _polylines.first.points.first.longitude;
    for (var poly in _polylines) {
      for (var point in poly.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    final latDifference = maxLat - minLat;
    final topOffsetValue = latDifference * topOffsetPercentage;
    final bottomOffsetValue = latDifference * bottomOffsetPercentage;

    final lngDifference = maxLat - minLat;
    final leftOffsetValue = lngDifference * leftOffsetPercentage;
    final rightOffsetValue = lngDifference * rightOffsetPercentage;

    final bounds = LatLngBounds(
      LatLng(minLat - bottomOffsetValue, minLng - leftOffsetValue),
      LatLng(maxLat + topOffsetValue, maxLng + rightOffsetValue),
    );

    final centerZoom = _mapController.centerZoomFitBounds(bounds);

    mapView?.animateCamera(centerZoom.center, centerZoom.zoom);
  }

  void resetMap() {
    isMapReady = false;
    mapView = null;
    _shouldCenter = true;
    _polylines.clear();
    _markers.removeWhere((key, value) => key != "user");
  }

  @override
  void dispose() {
    _locationListener?.cancel();
    super.dispose();
  }

  /*
  * Getters
  * */
  MapController get mapController => _mapController;

  LatLng? get currentPosition => _currentPosition;

  Map<String, Marker> get markers => _markers;

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
