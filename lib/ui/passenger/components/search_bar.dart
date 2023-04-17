import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../services/place_service.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(LatLng) onSearch;
  final Function(bool) updateToApu;
  bool toApu;
  LatLng? userLocation;
  final Function() clearUserLocation;

  SearchBar(
      {super.key,
      required this.controller,
      required this.onSearch,
      required this.updateToApu,
      required this.toApu,
      required this.userLocation,
      required this.clearUserLocation});

  String _sessionToken = const Uuid().v4();
  final _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
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
          final results = await _placeService.fetchSuggestions(context, pattern, _sessionToken);
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
          _sessionToken = const Uuid().v4();
          _placeService.getLatLong(context, suggestion.placeId).then((latLng) => onSearch(latLng));
          controller.text = suggestion.description;
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
        Text(toApu ? "TO APU" : "FROM APU", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16.0)),
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
