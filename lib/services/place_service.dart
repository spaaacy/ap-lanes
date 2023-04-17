import 'dart:convert';

import 'package:apu_rideshare/data/model/map/suggestion.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

import '../util/constants.dart';

class PlaceService {
  final client = Client();

  Future<List<Suggestion>> fetchSuggestions(String lang, String input, String sessionToken) async {
    if (input.isEmpty) {
      return [];
    }

    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=establishment&language=$lang&components=country:my&key=$androidApiKey&sessiontoken=$sessionToken';
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

  Future<LatLng> fetchLatLong(String lang, String placeId, String sessionToken) async {
    // String sessionToken
    if (placeId.isEmpty) {
      return const LatLng(0.0, 0.0);
    }

    final request = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&language=$lang&key=$androidApiKey";

    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result["status"] == "OK") {
        return LatLng(result["result"]["geometry"]["location"]["lat"], result["result"]["geometry"]["location"]["lng"]);
      }

      if (result["status"] == "ZERO_RESULTS") {
        return const LatLng(0.0, 0.0);
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  // TODO: Deprecate this @wooneusean
  Future<String> fetchAddressFromLatLng(String lang, LatLng latLng) async {
    final request =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&region=my&key=$androidApiKey&language=$lang'; // &result_type=subpremise|neighborhood|colloquial_area|establishment|point_of_interest|street_address
    final response = await client.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['status'] == 'OK') {
        return result['results'][0]['formatted_address'];
      }

      if (result['status'] == 'ZERO_RESULTS') {
        return 'Unknown Location';
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<Polyline> generateRoute(LatLng start, LatLng end) async {
    logger.d("POPPY: CALLED");
    final polylinePoints = PolylinePoints();
    final points = <LatLng>[];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(androidApiKey,
        PointLatLng(start.latitude, start.longitude),
        PointLatLng(end.latitude, end.longitude),
        travelMode: TravelMode.driving
    );

    if (result.status == "OK") {
      logger.d("POPPY: FOUND");
      result.points.forEach((PointLatLng point) {
        points.add(LatLng(point.latitude, point.longitude));
      });
    }
    logger.d("POPPY: NOT FOUND");

    final polyline = Polyline(
      polylineId: PolylineId("polyline"),
      points: points,
      width: 5,
      color: Colors.black87,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    return polyline;
  }

}
