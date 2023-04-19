import 'dart:async';
import 'dart:typed_data';

import 'package:apu_rideshare/services/place_service.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:apu_rideshare/util/resize_asset.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_permissions.dart';

class MapHelper {
  static void drawRoute(Set<Polyline> polylines, LatLng start, LatLng end, Function onFetch) async {
    final placeService = PlaceService();
    placeService.generateRoute(start, end).then((polylines) {
      onFetch(polylines);
    });
  }

  static void setCameraToRoute(GoogleMapController? mapController, Set<Polyline> polylines) {
    double minLat = polylines.first.points.first.latitude;
    double minLong = polylines.first.points.first.longitude;
    double maxLat = polylines.first.points.first.latitude;
    double maxLong = polylines.first.points.first.longitude;
    polylines.forEach((poly) {
      poly.points.forEach((point) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      });
    });

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)), 100));
  }

  static void setCameraToDriverAndPassenger(
      GoogleMapController? mapController, LatLng driverLatLng, LatLng passengerLatLng) {
    double minLat = driverLatLng.latitude;
    double minLng = driverLatLng.longitude;
    double maxLat = passengerLatLng.latitude;
    double maxLng = passengerLatLng.longitude;
    if (passengerLatLng.latitude < minLat) {
      maxLat = minLat;
      minLat = passengerLatLng.latitude;
    }
    if (passengerLatLng.longitude < minLng) {
      maxLng = minLng;
      minLng = passengerLatLng.longitude;
    }

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 50));
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

  static void resetCamera(GoogleMapController? mapController, LatLng currentPosition) {
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentPosition, 17.0));
  }
}
