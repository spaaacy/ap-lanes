import 'package:apu_rideshare/ui/passenger/passenger_home.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:flutter/material.dart';

import '../data/repo/user_repo.dart';
import 'driver/driver_home.dart';

class UserWrapper extends StatelessWidget {
  final String userId;

  UserWrapper({super.key, required this.userId});

  final _userRepo = UserRepo();

  @override
  build(BuildContext context) {
    return FutureBuilder<String>(
      future: _userRepo.getUserType(userId),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final userType = snapshot.data!;
          if (userType == DRIVER) {
            return const DriverHome();
          } else {
            return const PassengerHome();
          }
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
