import 'package:apu_rideshare/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerHome extends StatelessWidget {
  const PassengerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Home Screen")),
        body: Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Home!"),

                // Spacer(flex: 8),

                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthService>().signOut();
                    },
                    child: Text("Sign Out")))
              ],
            ))));
  }
}
