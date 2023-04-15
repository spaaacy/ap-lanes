import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';

import '../../../services/place_service.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;

  SearchTextField({super.key, required this.controller});

  String _sessionToken = const Uuid().v4();
  final _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      suggestionsBoxDecoration: const SuggestionsBoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12.0),
        ),
        elevation: 0.0,
      ),
      suggestionsCallback: (pattern) async {
        final results = await _placeService.fetchSuggestions(
            context, pattern, _sessionToken);
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
      },
      textFieldConfiguration: const TextFieldConfiguration(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          hintText: "Where do you wish to go?",
          filled: true,
          fillColor: Colors.white70,
        ),
      ),
    );
  }
}
