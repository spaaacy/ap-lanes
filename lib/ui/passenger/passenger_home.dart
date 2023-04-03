import 'package:apu_rideshare/services/auth_service.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Welcome Passenger")),
        body:
        Stack(children: [
          CustomMap(),

        ])
    );
  }
}
