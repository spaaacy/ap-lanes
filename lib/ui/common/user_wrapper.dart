import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../driver/driver_home.dart';
import '../passenger/passenger_home.dart';
import '../passenger/state/passenger_home_state.dart';
import 'user_mode_state.dart';

class UserWrapper extends StatelessWidget {
  const UserWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userMode = context.watch<UserModeState>().userMode;

    if (userMode == UserMode.passengerMode) {
      return ChangeNotifierProvider(
        create: (context) => PassengerHomeState()..initialize(context),
        child: const PassengerHome(),
      );
    } else {
      return const DriverHome();
    }

  }
}

