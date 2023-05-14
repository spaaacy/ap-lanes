import 'package:ap_lanes/ui/common/app_drawer.dart';
import 'package:ap_lanes/ui/common/map_view/map_view.dart';
import 'package:ap_lanes/ui/driver/components/driver_go_button.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup_state.dart';
import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup.dart';
import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/ui_helpers.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<DriverHomeState>(context);

    return Scaffold(
      drawer: AppDrawer(
        user: state.user,
        isDriver: true,
        isNavigationLocked: state.driverState != DriverState.idle,
        onNavigateWhenLocked: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot change to passenger mode while you are searching or carrying out a job."),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Text(
          getGreeting(state.user?.data().lastName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Stack(
        children: [
          const MapView(),
          const DriverGoButton(),
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
