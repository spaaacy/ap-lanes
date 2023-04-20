import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerInfo {
  String markerId;
  LatLng position;
  BitmapDescriptor? icon;

  MarkerInfo({required this.markerId, required this.position, this.icon});
}
