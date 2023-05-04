import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

LatLng newGetLatLngFromString(String? latLngString) {
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
  final trimmed = description.split(", ").toList();
  return "${trimmed[0]}, ${trimmed[1]}, ${trimmed[2]}";
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
