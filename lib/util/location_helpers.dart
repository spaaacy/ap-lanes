import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/repo/metadata_repo.dart';

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

Future<double?> calculateRoutePrice(double distance) async {
  final metadataRepo = MetadataRepo();
  final baseRate = await metadataRepo.getBaseRate();
  final kmRate = await metadataRepo.getKmRate();
  if (kmRate != null && baseRate != null) {
    return baseRate + (distance * kmRate);
  } else {
    return null;
  }
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

Future<bool> handleAdditionalLocationPermission(context) async {
  LocationPermission permission = await Geolocator.checkPermission();
  String requiredLocationOption = Platform.isAndroid ? "Allow all the time" : "Always";

  if (permission != LocationPermission.always) {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Location permissions"),
              content: Text(
                  "APLanes uses your location in the background when necessary and is required to use this application. Please select \"$requiredLocationOption\" in location settings to continue."),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, "Okay");
                    },
                    child: const Text("Okay")),
              ]);
        });

    await Geolocator.openLocationSettings();
    return false;
  }
  return true;
}

Future<bool> handleBasicLocationPermission(context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location services are disabled. Please enable the services'),
      ),
    );
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: const Text("Location permissions"),
                content: const Text("Location permissions is required to use this application"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context, "Okay");
                      },
                      child: const Text("Okay")),
                ]);
          });
      return false;
    }
  }

  return true;
}

List<LatLng> decodeEncodedPolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p =
    LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    poly.add(p);
  }
  return poly;
}
