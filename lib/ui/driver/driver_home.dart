
import 'package:ap_lanes/ui/common/map_view/map_view.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/greeting.dart';
import '../common/app_drawer.dart';
import 'components/journey_request_popup.dart';
import 'components/ongoing_journey_popup.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<DriverHomeState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getGreeting(state.user?.data().lastName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
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
          }),
      body: Stack(
        children: [
         const MapView(),
          Positioned.fill(
            bottom: 100.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: (() {
                if (state.activeJourney == null) {
                  return ElevatedButton(
                    onPressed: state.updateJourneyRequestListener,
                    style: ElevatedButtonTheme.of(context).style?.copyWith(
                          shape: const MaterialStatePropertyAll(CircleBorder()),
                          padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                          elevation: const MaterialStatePropertyAll(6.0),
                        ),
                    child: state.isSearching
                        ? const Icon(
                            Icons.close,
                            size: 20,
                          )
                        : const Text("GO"),
                  );
                }
              }()),
            ),
          ),
          (() {
            if (state.activeJourney != null) {
              return const OngoingJourneyPopup();
            } else {
              return const JourneyRequestPopup();
            }
          }()),
        ],
      ),
    );
  }
}
