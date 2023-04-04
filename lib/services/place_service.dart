
import 'dart:convert';

import 'package:apu_rideshare/data/model/map/suggestion.dart';
import 'package:http/http.dart';

import '../util/constants.dart';

class PlaceService {
  final sessionToken;
  PlaceService({this.sessionToken = ""});

  final client = Client();

  Future<List<Suggestion>> fetchSuggestions(String input, String lang) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=address&language=$lang&components=country:ch&key=$ANDROID_API_KEY&sessiontoken=$sessionToken';
    final response = await client.get(request as Uri);

    if (response.statusCode == 200) {

      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return result['prediction']
            .map<Suggestion>((prediction) =>
              Suggestion(placeId: prediction['place_id'],
              description: prediction['description'])
            )
            .toList();
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