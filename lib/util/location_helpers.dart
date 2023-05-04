import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


double calculateRouteDistance(Polyline? polylines) {
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


LatLng getLatLngFromString(String? latLngString) {
  LatLng latLng;
  if (latLngString != null) {
    List<double>? latLngList = latLngString.split(',').map((e) => double.tryParse(e.trim()) ?? 0).toList();
    latLng = LatLng(latLngList[0], latLngList[1]);
  } else {
    latLng = LatLng(0.0, 0.0);
  }
  return latLng;
}

String trimDescription(String description) {
  return description.split(", ").take(3).join(', ');
}

Future<bool> handleLocationPermission(context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location services are disabled. Please enable the services'),
      ),
    );
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are denied'),
        ),
      );
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location permissions are permanently denied, we cannot request permissions.'),
      ),
    );
    return false;
  }
  return true;
}
