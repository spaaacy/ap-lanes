import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../data/model/map/suggestion.dart';
import '../../../services/place_service.dart';

class SearchTextField extends StatelessWidget{
  final TextEditingController controller;
  SearchTextField({
    super.key,
    required this.controller
  });

  final _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {

    return TypeAheadField(

      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
          elevation: 0.0

        ),

      suggestionsCallback: (pattern) async {
          final results = await _placeService.fetchSuggestions(context, pattern);
          return results.take(4);
        },
        itemBuilder: (context, suggestion) {
          return Padding(
              padding: EdgeInsets.all(8.0),
              child:
              Text(
                suggestion.description,
                style: TextStyle(fontSize: 16.0)
              )
          );
        },
        onSuggestionSelected: (suggestion) {},

      textFieldConfiguration:
      const TextFieldConfiguration(
        decoration:
        InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide.none
            ),
            hintText: "Where do you wish to go?",
            filled: true,
            fillColor: Colors.white70,
        )
      ),
    );
  }

}