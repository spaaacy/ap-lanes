import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

import '../../../services/place_service.dart';
import '../../../util/location_helpers.dart';
import '../passenger_home_state.dart';

class SearchBar extends StatelessWidget {
  final _placeService = PlaceService();

  SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<PassengerHomeState>();
    final mapViewState = context.watch<MapViewState2>();
    String lang = Localizations.localeOf(context).languageCode;

    if (state.isSearching || state.hasDriver || mapViewState.currentPosition == null) return const SizedBox.shrink();

    return Column(
      children: [
        Material(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          elevation: 4.0,
          child: TypeAheadField(
            keepSuggestionsOnLoading: true,
            hideOnEmpty: true,
            hideOnLoading: true,
            hideOnError: true,
            suggestionsBoxDecoration: const SuggestionsBoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              elevation: 4.0,
            ),
            suggestionsCallback: (input) async {
              final results =
                  await _placeService.fetchSuggestions(input, mapViewState.currentPosition, lang, state.sessionToken);
              return results.take(4);
            },
            itemBuilder: (context, suggestion) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  trimDescription(suggestion.description),
                  style: const TextStyle(fontSize: 16.0),
                ),
              );
            },
            onSuggestionSelected: (suggestion) async {
              await _placeService
                  .fetchLatLng(suggestion.placeId, lang, state.sessionToken)
                  .then((latLng) => state.onLatLng(context, latLng));
              state.searchController.text = trimDescription(suggestion.description);
              state.onDescription(suggestion.description);
            },
            textFieldConfiguration: TextFieldConfiguration(
              controller: state.searchController,
              decoration: InputDecoration(
                suffixIcon: (state.destinationLatLng != null || state.searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.black,
                        onPressed: () {
                          state.clearUserLocation();
                        })
                    : null,
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                hintText: "Where do you wish to go?",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 8.0,
        ),
        Row(
          children: [
            if (state.routeDistance != null)
              Material(
                elevation: 4.0,
                color: Colors.black,
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${state.routeDistance!.toStringAsFixed(2)} km",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 8.0),
            if (state.routePrice != null)
              Material(
                elevation: 4.0,
                color: Colors.black,
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "RM ${state.routePrice!.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            const Spacer(),
            Material(
              elevation: 4.0,
              color: Colors.black,
              borderRadius: const BorderRadius.all(Radius.circular(25)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  state.toApu ? "TO APU" : "FROM APU",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
            Switch(
              value: state.toApu,
              onChanged: (value) => state.updateToApu(value),
            ),
          ],
        )
      ],
    );
  }
}
