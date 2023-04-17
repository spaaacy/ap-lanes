import 'package:apu_rideshare/services/place_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constants.dart';

class MapHelper {
  static void drawRoute(LatLng userLatLng, bool toApu, Set<Polyline> polylines, Function onFetch) {
    final placeService = PlaceService();

    if (userLatLng != null && toApu != null) {
      LatLng start = toApu ? userLatLng! : apuLatLng;
      LatLng end = toApu ? apuLatLng : userLatLng!;

      polylines.clear();
      placeService.generateRoute(start, end).then((polylines) {
        onFetch(polylines);
      });
    }
  }

  static void setCameraToRoute(GoogleMapController mapController, Set<Polyline> polylines) {
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

    mapController.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)), 20));
  }
}
