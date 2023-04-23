import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/place_service.dart';
import 'location_permissions.dart';
import 'resize_asset.dart';

class MapHelper {
  static Future<Polyline> drawRoute(LatLng start, LatLng end) async {
    final placeService = PlaceService();
    return placeService.generateRoute(start, end);
  }

  static void setCameraToRoute({
    required GoogleMapController? mapController,
    required Set<Polyline> polylines,
    double topOffsetPercentage = 0,
    double bottomOffsetPercentage = 0,
    double leftOffsetPercentage = 0,
    double rightOffsetPercentage = 0,
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

    final latDifference = maxLat - minLat;
    final topOffsetValue = latDifference * topOffsetPercentage;
    final bottomOffsetValue = latDifference * bottomOffsetPercentage;

    final lngDifference = maxLat - minLat;
    final leftOffsetValue = lngDifference * leftOffsetPercentage;
    final rightOffsetValue = lngDifference * rightOffsetPercentage;

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - bottomOffsetValue, minLng - leftOffsetValue),
          northeast: LatLng(maxLat + topOffsetValue , maxLng + rightOffsetValue),
        ),
        50,
      ),
    );
  }

  static void setCameraBetweenMarkers({
    required GoogleMapController? mapController,
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

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - bottomOffsetValue, minLng - leftOffsetValue),
          northeast: LatLng(maxLat + topOffsetValue , maxLng + rightOffsetValue),
        ),
        50,
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

  static double calculateRouteDistance(Polyline? polylines){
    if (polylines == null) return 0;

    var p = 0.017453292519943295;
    double totalDistance = 0;

    polylines.points.asMap().forEach((index, currentLatLng) {
      if (index < polylines.points.length - 1) {
        final nextLatLng = polylines.points[index + 1];
        var a = 0.5 -
            cos((nextLatLng.latitude - currentLatLng.latitude) * p) / 2 +
            cos(currentLatLng.latitude * p) *
                cos(nextLatLng.latitude * p) *
                (1 - cos((nextLatLng.longitude - currentLatLng.longitude) * p)) /
                2;
        totalDistance += 12742 * asin(sqrt(a));
      }
    });

    return totalDistance;
  }

}
