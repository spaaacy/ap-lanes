import 'package:apu_rideshare/services/auth_service.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:apu_rideshare/ui/passenger/components/search_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../util/greeting.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Greeting.getGreeting()),
        actions: <Widget>[
          IconButton(
              onPressed: () {
                context.read<AuthService>().signOut();
              },
              icon: const Icon(Icons.logout_rounded))
        ],
      ),
      body: Stack(
        children: [
          const CustomMap(),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: SearchTextField(controller: _searchController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
