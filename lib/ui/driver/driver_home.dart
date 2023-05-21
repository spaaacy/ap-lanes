import 'package:ap_lanes/ui/common/app_drawer/app_drawer.dart';
import 'package:ap_lanes/ui/common/app_drawer/app_drawer_state.dart';
import 'package:ap_lanes/ui/common/map_view/map_view.dart';
import 'package:ap_lanes/ui/driver/components/driver_go_button.dart';
import 'package:ap_lanes/ui/driver/components/driver_vehicle_dropdown/driver_vehicle_dropdown.dart';
import 'package:ap_lanes/ui/driver/components/driver_vehicle_dropdown/driver_vehicle_dropdown_state.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup/journey_request_popup.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup/journey_request_popup_state.dart';
import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup/ongoing_journey_popup.dart';
import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup/ongoing_journey_popup_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/ui_helpers.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<DriverHomeState>(context);

    return (state.user == null)
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            drawer: ChangeNotifierProvider<AppDrawerState>(
              create: (context) => AppDrawerState(context),
              child: AppDrawer(
                isNavigationLocked: state.driverState != DriverState.idle,
                onNavigateWhenLocked: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("You cannot change to passenger mode while you are searching or carrying out a job."),
                    ),
                  );
                },
              ),
            ),
            appBar: AppBar(
              title: Text(
                getGreeting(state.user?.data().firstName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            body: Stack(
              children: [
                const MapView(),
                const DriverGoButton(),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ChangeNotifierProvider<DriverVehicleDropdownState>(
                        create: (ctx) => DriverVehicleDropdownState(ctx),
                        child: const DriverVehicleDropdown(),
                      ),
                    ),
                  ),
                ),
                ChangeNotifierProvider<JourneyRequestPopupState>(
                  create: (ctx) => JourneyRequestPopupState(ctx),
                  child: const JourneyRequestPopup(),
                ),
                ChangeNotifierProvider<OngoingJourneyPopupState>(
                  create: (ctx) => OngoingJourneyPopupState(ctx),
                  child: const OngoingJourneyPopup(),
                ),
              ],
            ),
          );
  }
}
