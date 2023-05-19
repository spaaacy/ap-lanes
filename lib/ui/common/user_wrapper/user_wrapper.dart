import 'package:ap_lanes/data/repo/journey_repo.dart';
import 'package:ap_lanes/ui/driver/driver_home.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../passenger/passenger_home.dart';
import '../../passenger/passenger_home_state.dart';
import 'user_wrapper_state.dart';

class UserWrapper extends StatelessWidget {
  const UserWrapper({Key? key}) : super(key: key);

  Future<bool> _hasOngoingJourney(BuildContext context, UserWrapperState userWrapperState) async {
    final firebaseUser = context.read<firebase_auth.User?>();
    final JourneyRepo journeyRepo = JourneyRepo();

    if (await journeyRepo.hasOngoingJourney(firebaseUser!.uid)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final userWrapperState = context.watch<UserWrapperState>();

    _hasOngoingJourney(context, userWrapperState).then((hasOngoingJourney) {
      if (hasOngoingJourney) {
        userWrapperState.userMode = UserMode.driverMode;
      }
    });

    if (userWrapperState.userMode == UserMode.passengerMode) {
      return ChangeNotifierProvider(
        create: (context) => PassengerHomeState(context),
        child: const PassengerHome(),
      );
    } else {
      return ChangeNotifierProvider<DriverHomeState>(
        create: (context) => DriverHomeState(context),
        child: const DriverHome(),
      );
    }
  }
}
