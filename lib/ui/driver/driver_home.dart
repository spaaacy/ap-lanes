import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../common/custom_map.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Driver"),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              context.read<AuthService>().signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: Stack(
        children: [
          const CustomMap(),
          Positioned.fill(
            bottom: 100.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButtonTheme.of(context).style?.copyWith(
                      shape: const MaterialStatePropertyAll(CircleBorder()),
                      padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                    ), // TODO: Add GO functionality
                child: const Text("GO"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
