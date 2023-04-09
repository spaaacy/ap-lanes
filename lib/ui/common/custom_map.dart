import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/location_permissions.dart';
import '../../util/resize_asset.dart';

class CustomMap extends StatefulWidget {
  CustomMap({super.key});

  @override
  State<CustomMap> createState() => _CustomMapState();

}

class _CustomMapState extends State<CustomMap> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  late String _mapStyle;

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
    return
      _currentPosition == null ? Center(child: CircularProgressIndicator()) :
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
    );
  }

}