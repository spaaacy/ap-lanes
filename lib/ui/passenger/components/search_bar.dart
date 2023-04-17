import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../services/place_service.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(LatLng) onLatLng;
  final Function(bool) updateToApu;
  bool toApu;
  LatLng? userLocation;
  final Function() clearUserLocation;
  final Function(String) onDescription;

  SearchBar(
      {super.key,
      required this.controller,
      required this.onLatLng,
      required this.updateToApu,
      required this.toApu,
      required this.userLocation,
      required this.clearUserLocation,
      required this.onDescription});

  String _sessionToken = Uuid().v4();
  final _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Column(children: [
      TypeAheadField(
        keepSuggestionsOnLoading: true,
        hideOnEmpty: true,
        hideOnLoading: true,
        hideOnError: true,
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12.0),
          ),
          elevation: 0.0,
        ),
        suggestionsCallback: (pattern) async {
          final results = await _placeService.fetchSuggestions(lang, pattern, _sessionToken);
          return results.take(4);
        },
        itemBuilder: (context, suggestion) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              suggestion.description,
              style: const TextStyle(fontSize: 16.0),
            ),
          );
        },
        onSuggestionSelected: (suggestion) {
          _placeService.getLatLong(lang, suggestion.placeId, _sessionToken).then((latLng) => onLatLng(latLng));
          onDescription(suggestion.description);
          controller.text = suggestion.description;
          _sessionToken = Uuid().v4();
        },
        textFieldConfiguration: TextFieldConfiguration(
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: userLocation != null
                ? IconButton(
                    icon: Icon(Icons.close),
                    color: Colors.black,
                    onPressed: () {
                      clearUserLocation();
                      controller.text = "";
                    })
                : null,
            border: OutlineInputBorder(borderSide: BorderSide.none),
            hintText: "Where do you wish to go?",
            filled: true,
            fillColor: Colors.white70,
          ),
        ),
      ),
      const SizedBox(
        height: 8.0,
      ),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(toApu ? "TO APU" : "FROM APU", style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(
          width: 8.0,
        ),
        Switch(
          activeColor: Colors.black,
          value: toApu,
          onChanged: (value) => updateToApu(value),
        ),
      ])
    ]);
  }
}
