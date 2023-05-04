import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../util/location_helpers.dart';

class MapViewState extends ChangeNotifier {
  /*
  * Variables
  * */
  bool _shouldCenter = true;
  final _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _locationListener;
  final Set<Polyline> _polylines = <Polyline>{};
  final Map<String, Marker> _markers = <String, Marker>{};
  TickerProviderStateMixin? ticker;

  /*
  * Functions
  * */
  Future<void> resetCamera() async {
    if (currentPosition == null || ticker == null) return;
    _animateCamera(_currentPosition!, 17.0);
  }

  void setCameraBetweenMarkers({
    required LatLng firstLatLng,
    required LatLng secondLatLng,
    double topOffsetPercentage = 0,
    double bottomOffsetPercentage = 0,
    double leftOffsetPercentage = 0,
    double rightOffsetPercentage = 0,
  }) {
    double minLat = firstLatLng.latitude;
    double minLng = firstLatLng.longitude;
    double maxLat = secondLatLng.latitude;
    double maxLng = secondLatLng.longitude;

    if (secondLatLng.latitude < minLat) {
      maxLat = minLat;
      minLat = secondLatLng.latitude;
    }
    if (secondLatLng.longitude < minLng) {
      maxLng = minLng;
      minLng = secondLatLng.longitude;
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

    _animateCamera(centerZoom.center, centerZoom.zoom);
  }

  void setCameraToRoute({
    double topOffsetPercentage = 0,
    double bottomOffsetPercentage = 0,
    double leftOffsetPercentage = 0,
    double rightOffsetPercentage = 0,
  }) {
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

    _animateCamera(centerZoom.center, centerZoom.zoom);

  }

  void _animateCamera(LatLng destLocation, double destZoom) {
    if (ticker == null) return;

    const startedId = 'AnimatedMapController#MoveStarted';
    const inProgressId = 'AnimatedMapController#MoveInProgress';
    const finishedId = 'AnimatedMapController#MoveFinished';

    final latTween = Tween<double>(begin: _mapController.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: ticker!);

    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    final startIdWithTarget = '$startedId#${destLocation.latitude},${destLocation.longitude},$destZoom';
    bool hasTriggeredMove = false;

    controller.addListener(() {
      final String id;
      if (animation.value == 1.0) {
        id = finishedId;
      } else if (!hasTriggeredMove) {
        id = startIdWithTarget;
      } else {
        id = inProgressId;
      }

      hasTriggeredMove |= _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: id,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void resetMap() {
    _shouldCenter = true;
    _polylines.clear();
    _markers.clear();
    ticker = null;
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
        _currentPosition = latLng;
        _markers["user"] =
            Marker(point: latLng, builder: (context) => const Icon(Icons.account_circle_rounded, size: 35));

        if (_shouldCenter) {
          resetCamera();
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

  MapController get mapController => _mapController;

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
