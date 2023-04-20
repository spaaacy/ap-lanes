import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLng getLatLngFromString(String? latLngString) {
  LatLng latLng;
  if (latLngString != null) {
    List<double>? latLngList = latLngString.split(',').map((e) => double.tryParse(e.trim()) ?? 0).toList();
    latLng = LatLng(latLngList[0], latLngList[1]);
  } else {
    latLng = const LatLng(0.0, 0.0);
  }
  return latLng;
}
