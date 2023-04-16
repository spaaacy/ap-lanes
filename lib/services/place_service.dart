import 'dart:convert';

import 'package:apu_rideshare/data/model/map/suggestion.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

import '../util/constants.dart';

class PlaceService {
  final client = Client();

  Future<List<Suggestion>> fetchSuggestions(BuildContext context, String input, String sessionToken) async {
    if (input.isEmpty) {
      return [];
    }

    final lang = Localizations.localeOf(context).languageCode;
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

  Future<LatLng> getLatLong(BuildContext context, String placeId) async { // String sessionToken
    if (placeId.isEmpty) {
      return const LatLng(0.0, 0.0);
    }

    final lang = Localizations.localeOf(context).languageCode;

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

  Future<List<String>> fetchAddressFromLatLng(BuildContext context, LatLng latLng) async {
    final lang = Localizations.localeOf(context).languageCode;
    final request =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$androidApiKey&language=$lang&result_type=street_address';
    final response = await client.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['status'] == 'OK') {
        return result['results'].map<String>((result) {
          return result['formatted_address'];
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
}
