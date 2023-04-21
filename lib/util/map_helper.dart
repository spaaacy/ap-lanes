import 'dart:async';
import 'dart:math';

import 'package:apu_rideshare/services/place_service.dart';
import 'package:apu_rideshare/util/resize_asset.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_permissions.dart';

class MapHelper {
  static Future<Polyline> drawRoute(LatLng start, LatLng end) async {
    final placeService = PlaceService();
    return placeService.generateRoute(start, end);
  }

  static void setCameraToRoute({
    required GoogleMapController? mapController,
    required Set<Polyline> polylines,
    required double padding,
    double verticalOffset = 0,
    double horizontalOffset = 0,
  }) {
    double minLat = polylines.first.points.first.latitude;
    double minLng = polylines.first.points.first.longitude;
    double maxLat = polylines.first.points.first.latitude;
    double maxLng = polylines.first.points.first.longitude;
    polylines.forEach((poly) {
      poly.points.forEach((point) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      });
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat + min(verticalOffset, 0), minLng + min(horizontalOffset, 0)),
          northeast: LatLng(maxLat + max(verticalOffset, 0), maxLng + max(horizontalOffset, 0)),
        ),
        padding,
      ),
    );
  }

  static void setCameraBetweenMarkers({
    required GoogleMapController? mapController,
    required LatLng firstLatLng,
    required LatLng secondLatLng,
    required double padding,
    double verticalOffset = 0,
    double horizontalOffset = 0,
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

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  static Stream<Position> getCurrentPosition(BuildContext context) async* {
    final hasPermissions = await LocationPermissions.handleLocationPermission(context);

    if (hasPermissions) {
      yield* Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      );
    }
  }

  static Future<BitmapDescriptor> getCustomIcon(String path, int size) async {
    final Uint8List? resizedIcon = await ResizeAsset.getBytesFromAsset(path, size);
    return resizedIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.fromBytes(resizedIcon);
  }

  static Future<String> getMapStyle() async {
    return rootBundle.loadString('assets/map_style.txt');
  }

  static void resetCamera(GoogleMapController? mapController, LatLng? currentPosition) {
    if (currentPosition == null) return;
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentPosition, 17.0));
  }
}
