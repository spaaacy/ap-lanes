import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngConverter {

  static LatLng getLatLngFromString(String string) {
    final splitString = string.split(', ');
    final latitude = double.parse(splitString[0]);
    final longitude = double.parse(splitString[1]);
    return LatLng(latitude, longitude);
  }
  
}