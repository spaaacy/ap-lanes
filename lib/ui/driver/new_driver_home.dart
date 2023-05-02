import 'package:ap_lanes/ui/common/app_drawer.dart';
import 'package:ap_lanes/ui/common/map_view/map_view.dart';
import 'package:ap_lanes/ui/driver/components/driver_go_button.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup.dart';
import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup.dart';
import 'package:ap_lanes/ui/driver/new_driver_home_state.dart';
import 'package:ap_lanes/util/greeting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewDriverHome extends StatelessWidget {
  const NewDriverHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<NewDriverHomeState>(context);

    return Scaffold(
      drawer: AppDrawer(
        user: state.user,
        isDriver: true,
        isNavigationLocked: state.isSearching || state.activeJourney != null,
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
      body: state.isLoading()
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: const [
                MapView(),
                DriverGoButton(),
                OngoingJourneyPopup(),
                JourneyRequestPopup(),
              ],
            ),
    );
  }
}
