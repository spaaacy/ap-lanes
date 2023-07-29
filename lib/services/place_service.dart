import 'dart:convert';

import 'package:ap_lanes/util/location_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';

import '../data/model/local/suggestion.dart';
import '../util/constants.dart';

class PlaceService {
  final client = Client();
  late String mapsApiKey = dotenv.env['MAPS_API_KEY']!;

  Future<List<Suggestion>> fetchSuggestions(
      String input, LatLng? currentLocation, String lang, String sessionToken) async {
    if (input.isEmpty) {
      return [];
    }

    currentLocation ??= apuLatLng;
    final request =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&radius=5000&location=${currentLocation.latitude}%2C${currentLocation.longitude}&types=establishment&language=$lang&components=country:my&key=$mapsApiKey&sessiontoken=$sessionToken";
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

  Future<Polyline> fetchRoute(LatLng start, LatLng end) async {
    final request =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${start.latitude},${start.longitude}&origin=${end.latitude},${end.longitude}&mode=driving&key=$mapsApiKey&region=my";

    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result["status"] == "OK" && result["routes"] != null && result["routes"].isNotEmpty) {
        final List<LatLng> points = decodeEncodedPolyline(result["routes"][0]["overview_polyline"]["points"]);

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

  Future<LatLng> fetchLatLng(String placeId, String lang, String sessionToken) async {
    if (placeId.isEmpty) {
      return LatLng(0.0, 0.0);
    }

    final request =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry/location&language=$lang&key=$mapsApiKey&sessiontoken=$sessionToken";

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
}