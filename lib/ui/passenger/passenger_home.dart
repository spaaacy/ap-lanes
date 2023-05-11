import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/ui_helpers.dart';
import '../common/app_drawer.dart';
import '../common/map_view/map_view.dart';
import 'components/go_button.dart';
import 'components/journey_detail.dart';
import 'components/search_bar.dart' as passenger_view;
import 'passenger_home_state.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PassengerHomeState>(context);

    return (state.user == null || state.passenger == null)
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
      appBar: AppBar(
        title: Text(
          getGreeting(state.lastName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      drawer: AppDrawer(
          user: state.user,
          isDriver: false,
          isNavigationLocked: state.isSearching,
          onNavigateWhenLocked: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "You cannot change to driver mode while you are searching for a driver or are in a journey."),
              ),
            );
          }),
      body: Stack(
        children: [
          const MapView(),
          if (state.isSearching || state.hasDriver) const JourneyDetail(),
          ...?(() {
            if (!state.isSearching && !state.hasDriver) {
              return [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: passenger_view.SearchBar(),
                    ),
                  ),
                ),
              ];
            }
          }()),
          ...?(() {
            if (state.destinationLatLng != null || state.isSearching) {
              return [
                const Positioned.fill(
                  bottom: 100.0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GoButton(),
                  ),
                )
              ];
            }
          }()),
        ],
      ),
    );
  }
}