import 'package:ap_lanes/ui/driver/components/journey_request_popup_state.dart';
import 'package:ap_lanes/ui/driver/driver_home.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../passenger/passenger_home.dart';
import '../../passenger/passenger_home_state.dart';
import 'user_wrapper_state.dart';

class UserWrapper extends StatelessWidget {
  const UserWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userMode = context.watch<UserWrapperState>().userMode;

    if (userMode == UserMode.passengerMode) {
      return ChangeNotifierProvider(
        create: (context) => PassengerHomeState()..initialize(context),
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
