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

  SearchBar({super.key, required this.controller, required this.onSearch, required this.updateToApu, required this.toApu});

  String _sessionToken = const Uuid().v4();
  final _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      TypeAheadField(
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
        },
        textFieldConfiguration: const TextFieldConfiguration(
          decoration: InputDecoration(
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

      Center(child: Align(
          alignment: Alignment.centerRight,
          child: Row(children:
          [
            Text(toApu ? "TO APU" : "FROM APU", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16.0)),

            const SizedBox(width: 8.0,),

            Switch(
                value: toApu,
                onChanged: (value) => updateToApu(value),
            ),

          ]
          )
      ))

    ]);
  }
}
