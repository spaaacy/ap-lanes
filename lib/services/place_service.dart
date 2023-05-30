import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';

import '../data/model/local/suggestion.dart';
import '../util/constants.dart';

class PlaceService {
  final client = Client();

  Future<List<Suggestion>> fetchSuggestions(String input, LatLng? currentLocation, String lang, String sessionToken) async {
    if (input.isEmpty) {
      return [];
    }

    currentLocation ??= apuLatLng;
    final request =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&radius=5000&location=${currentLocation.latitude}%2C${currentLocation.longitude}&types=establishment&language=$lang&components=country:my&key=$androidApiKey&sessiontoken=$sessionToken";
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['status'] == 'OK') {
        return result['predictions'].map<Suggestion>((prediction) {
          return Suggestion(placeId: prediction['place_id'], description: prediction['description']);
        }).toList();
      }

      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<LatLng> fetchLatLng(String placeId, String lang, String sessionToken) async {
    if (placeId.isEmpty) {
      return LatLng(0.0, 0.0);
    }

    final request =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry/location&language=$lang&key=$androidApiKey&sessiontoken=$sessionToken";

    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result["status"] == "OK") {
        return LatLng(result["result"]["geometry"]["location"]["lat"], result["result"]["geometry"]["location"]["lng"]);
      }

      if (result["status"] == "ZERO_RESULTS") {
        return LatLng(0.0, 0.0);
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch latitude longitude');
    }
  }

  Future<Polyline> _fetchRoute(LatLng start, LatLng end) async {
    final request =
        "http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson";

    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result["code"] == "Ok") {
        final points = result["routes"][0]["geometry"]["coordinates"].map<LatLng>((coordinate) {
          return LatLng(coordinate[1], coordinate[0]);
        }).toList();

        final polyline = Polyline(
          points: points,
          color: Colors.purple,
          strokeWidth: 5.0,
        );

        return polyline;
      } else {
        throw Exception('Failed to fetch a route!');
      }
    } else {
      throw Exception('Failed to fetch a route!');
    }
  }

  Future<Polyline> fetchRoute(LatLng start, LatLng end) async {
    final polylinePoints = PolylinePoints();
    final points = <LatLng>[];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      androidApiKey,
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(end.latitude, end.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.status == "OK") {
      result.points.forEach((PointLatLng point) {
        points.add(LatLng(point.latitude, point.longitude));
      });
    }

    final polyline = Polyline(
      points: points,
      color: Colors.purple,
      strokeWidth: 5.0,
    );

    return polyline;
  }

}
