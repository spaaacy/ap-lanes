import 'dart:typed_data';

import 'package:apu_rideshare/util/resize_asset.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/location_permissions.dart';

class DriverHome extends StatefulWidget {
  DriverHome();

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {

  late GoogleMapController _mapController;

  @override
  void initState() {
    _getCustomIcon();

    // Fetches map style
    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });

    _getCurrentPosition();
    super.initState();
  }

  LatLng? _currentPosition;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  late String _mapStyle;

  void _getCurrentPosition() async {
    final hasPermissions = await LocationPermissions.handleLocationPermission(context);

    if (hasPermissions) {
      Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high)).listen(
          (location) {
            final latLng = LatLng(location.latitude, location.longitude);
            setState(() => _currentPosition = latLng);
            _mapController.animateCamera(CameraUpdate.newLatLng(latLng));
          }
      );
    }
  }

  void _getCustomIcon() async {
    final Uint8List? resizedIcon = await ResizeAsset.getBytesFromAsset('assets/images/marker_icon.png', 150);
    _markerIcon =
      resizedIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.fromBytes(resizedIcon);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.setMapStyle(_mapStyle);
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome Driver")
      ),
      body:
      _currentPosition == null ? Center(child: CircularProgressIndicator()) :
      Stack(children: [
                GoogleMap(

                  zoomControlsEnabled: false,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition:
                      CameraPosition(target: _currentPosition!, zoom: 17.0),
                  markers: {
                    Marker(
                        icon: _markerIcon,
                        markerId: MarkerId("current_location"),
                        position: _currentPosition!)
                        // position: _center)
                  },
                ),

                Positioned.fill(
                    bottom: 100.0,
                    child: Align(alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {}, // TODO: Add GO functionality
                          child: Text("GO"),
                          style: ElevatedButtonTheme.of(context).style?.copyWith(
                            shape: MaterialStatePropertyAll(CircleBorder()),
                            padding: MaterialStatePropertyAll(EdgeInsets.all(24.0))
                          )
                    )
                ))

              ]
      )

        // Padding(
            // padding: EdgeInsets.all(12.0),
            // child:
            // _currentPosition == null ? Center(child: CircularProgressIndicator()) :
            // GoogleMap(
            //     onMapCreated: _onMapCreated,
            //     initialCameraPosition:
            //     CameraPosition(target: _currentPosition!, zoom: 11.0)),
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
    // )
  );
  }
}