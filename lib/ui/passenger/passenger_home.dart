import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view/map_view.dart';
import '../common/map_view/map_view_state.dart';
import 'components/go_button.dart';
import 'components/journey_detail.dart';
import 'components/search_bar.dart';
import 'passenger_home_state.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PassengerHomeState>(context);
    final mapViewState = Provider.of<MapViewState>(context);

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
                content:
                    Text("You cannot change to driver mode while you are searching for a driver or are in a journey."),
              ),
            );
          }),
      body: Stack(
              children: [
                MapView(
                  userLatLng: mapViewState.currentPosition,
                  setShouldCenter: (shouldCenter) {
                    state.shouldCenter = shouldCenter;
                  },
                  markers: mapViewState.markers,
                  polylines: mapViewState.polylines,
                  onMapCreated: (controller) async {
                    state.mapController = controller;
                    state.mapStyle = await MapHelper.getMapStyle();
                    controller.setMapStyle(state.mapStyle);
                  },
                  mapController: state.mapController,
                ),
                if (state.isSearching || state.hasDriver)
                  const JourneyDetail(),
                ...?(() {
                  if (!state.isSearching && !state.hasDriver) {
                    return [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SearchBar(),
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
