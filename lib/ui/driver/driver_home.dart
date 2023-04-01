import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverHome extends StatefulWidget {
  DriverHome();

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {

  late GoogleMapController mapController;
  final LatLng _center = const LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome Driver")
      ),
      body: Padding(
            padding: EdgeInsets.all(12.0),
            child:

            GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                CameraPosition(target: _center, zoom: 11.0)),
            // Column(children: [


              // ElevatedButton(
              //     onPressed: () {
              //       context.read<AuthService>().signOut();
              //     },
              //     child: Text("Sign Out")),

              // Align(
              //     alignment: Alignment.bottomRight,
              //     child:
            // ])
    ));
  }
}