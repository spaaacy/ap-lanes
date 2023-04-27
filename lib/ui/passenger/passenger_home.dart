import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/constants.dart';
import '../../util/greeting.dart';
import '../../util/map_helper.dart';
import '../common/app_drawer.dart';
import '../common/map_view.dart';
import 'components/go_button.dart';
import 'components/journey_detail.dart';
import 'components/search_bar.dart';
import 'state/passenger_home_state.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  late PassengerHomeState _state;

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _state = context.read<PassengerHomeState>();
      _state.userIcon = await MapHelper.getCustomIcon('assets/icons/user.png', userIconSize);
      _state.driverIcon = await MapHelper.getCustomIcon('assets/icons/driver.png', userIconSize);
      _state.locationIcon = await MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize);

      if (mounted) {
        _state.initializeLocation(context);
        await _state.initializeFirestore(context);
      }
    });
  }

  bool isLoading() {
    return _state.user == null || _state.passenger == null;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading()
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
    : Scaffold(
      appBar: AppBar(
        title: Text(
          getGreeting(_state.lastName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      drawer: AppDrawer(
          user: _state.user,
          isDriver: false,
          isNavigationLocked: _state.isSearching,
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
                  userLatLng: _state.currentPosition,
                  setShouldCenter: (shouldCenter) {
                    setState(() {
                      _state.shouldCenter = shouldCenter;
                    });
                  },
                  markers: _state.markers,
                  polylines: _state.polylines,
                  onMapCreated: (controller) async {
                    setState(() {
                      _state.mapController = controller;
                    });
                    _state.mapStyle = await MapHelper.getMapStyle();
                    controller.setMapStyle(_state.mapStyle);
                  },
                  mapController: _state.mapController,
                ),
                if (_state.isSearching || _state.hasDriver)
                  JourneyDetail(),
                ...?(() {
                  if (!_state.isSearching && !_state.hasDriver) {
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
                  if (_state.destinationLatLng != null || _state.isSearching) {
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

  @override
  void dispose() async {
    _state.disposeListener();
    super.dispose();
  }


}
