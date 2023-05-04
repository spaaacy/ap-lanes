import 'dart:async';
import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapHelper {
  static Future<void> resetCamera(MapController mapController, LatLng? currentPosition) async {
    if (currentPosition == null) return;
    mapController.move(currentPosition, 17.0);
  }

  static void setCameraToRoute({
    required MapController mapController,
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
    for (var poly in polylines) {
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

    mapController.fitBounds(bounds);
  }

  static void setCameraBetweenMarkers({
    required MapController mapController,
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

    mapController.fitBounds(bounds);
  }

  static double calculateRouteDistance(Polyline? polylines) {
    if (polylines == null) return 0;

    var p = 0.017453292519943295;
    double totalDistance = 0;

    polylines.points.asMap().forEach((index, currentLatLng) {
      if (index < polylines.points.length - 1) {
        final LatLng nextLatLng = polylines.points[index + 1];
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
