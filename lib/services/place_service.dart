import 'dart:convert';

import 'package:apu_rideshare/data/model/map/suggestion.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

import '../util/constants.dart';

class PlaceService {
  final client = Client();

  Future<List<Suggestion>> fetchSuggestions(
      BuildContext context, String input, String sessionToken) async {
    if (input.isEmpty) {
      return [];
    }

    final lang = Localizations.localeOf(context).languageCode;
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=establishment&language=$lang&components=country:my&key=$ANDROID_API_KEY&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['status'] == 'OK') {
        return result['predictions'].map<Suggestion>((prediction) {
          return Suggestion(
              placeId: prediction['place_id'],
              description: prediction['description']);
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
