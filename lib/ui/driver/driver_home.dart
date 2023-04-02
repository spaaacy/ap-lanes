import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final LatLng _center = const LatLng(25.2888083, 55.3779617);

  @override
  void initState() {
    _getCustomIcon();
    _getCurrentPosition();
    super.initState();
  }

  LatLng? _currentPosition;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;

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

  void _getCustomIcon() {
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(), "assets/marker_icon.png")
        .then(
        (icon) {
          setState(() {
            _markerIcon = icon;
          });
        }
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
                      CameraPosition(target: _currentPosition!, zoom: 15.0),
                  markers: {
                    Marker(
                        icon: _markerIcon,
                        markerId: MarkerId("current_location"),
                        position: _currentPosition!)
                        // position: _center)
                  },
                ),

                Positioned.fill(
                    bottom: 50.0,
                    child: Align(alignment: Alignment.bottomCenter,
                        child: ElevatedButton(onPressed: () {}, child: Text("Go"),
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor)))
                )

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