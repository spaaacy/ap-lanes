import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../common/custom_map.dart';

class DriverHome extends StatefulWidget {
  DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Welcome Driver"), actions: <Widget>[
          IconButton(
              onPressed: () {
                context.read<AuthService>().signOut();
              },
              icon: Icon(Icons.logout_rounded))
        ]),
        body: Stack(children: [

          CustomMap(),

          Positioned.fill(
              bottom: 100.0,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                      onPressed: () {}, // TODO: Add GO functionality
                      child: Text("GO"),
                      style: ElevatedButtonTheme.of(context).style?.copyWith(
                          shape: MaterialStatePropertyAll(CircleBorder()),
                          padding:
                              MaterialStatePropertyAll(EdgeInsets.all(24.0))))))

        ]));
  }
}
