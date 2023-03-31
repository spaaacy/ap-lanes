import 'package:apu_rideshare/ui/passenger/passenger_home.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:flutter/cupertino.dart';
import 'driver/driver_home.dart';

class UserWrapper extends StatelessWidget {

  final String userType;

  UserWrapper({required this.userType});

  @override build(BuildContext context) {
    if (userType == DRIVER) {
      return DriverHome();
    } else {
      return PassengerHome();
    }
  }

}