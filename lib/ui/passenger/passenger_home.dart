import 'package:ap_lanes/ui/common/app_drawer/app_drawer_state.dart';
import 'package:ap_lanes/ui/passenger/components/driver_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/ui_helpers.dart';
import '../common/app_drawer/app_drawer.dart';
import '../common/map_view/map_view.dart';
import 'components/journey_detail.dart';
import 'components/passenger_go_button.dart';
import 'components/search_bar.dart' as passenger_view;
import 'passenger_home_state.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PassengerHomeState>(context);

    return (state.user == null)
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            appBar: AppBar(
              title: Text(
                getGreeting(state.user!.data().firstName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            drawer: ChangeNotifierProvider<AppDrawerState>(
              create: (context) => AppDrawerState(context),
              child: AppDrawer(
                isNavigationLocked: state.isSearching,
                onNavigateWhenLocked: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "You cannot change to driver mode while you are searching for a driver or are in a journey."),
                    ),
                  );
                },
              ),
            ),
            body: Stack(
                    children: [
                      const MapView(),
                      const JourneyDetail(),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: passenger_view.SearchBar(),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        bottom: 100.0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: PassengerGoButton(),
                        ),
                      ),
                      const DriverDetail(),
                    ],
                  )
          );
  }
}
