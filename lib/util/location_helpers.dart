import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLng getLatLngFromString(String latLngString) {
  var latLngValues = latLngString.split(',').map((e) => double.parse(e.trim())).toList();
  return LatLng(latLngValues[0], latLngValues[1]);
}