import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/location_permissions.dart';
import '../../util/resize_asset.dart';

class CustomMap extends StatefulWidget {
  const CustomMap({super.key});

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  late String _mapStyle;
  late StreamSubscription<Position> _locationSubscription;
  bool _cameraShouldCenter = true;

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
      try {
        _locationSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
        ).listen((location) {
          final latLng = LatLng(location.latitude, location.longitude);
          /*
          fixme: Can't fix this shit no matter what.
            Putting a WillPopScope fixes this sometimes, but not all the time.
            Ignoring for now.
          */
          setState(() => _currentPosition = latLng);
          if (_cameraShouldCenter) {
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17.0));
          }
        });
      } catch (e, s) {
        print(s);
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  void _getCustomIcon() async {
    final Uint8List? resizedIcon = await ResizeAsset.getBytesFromAsset('assets/images/marker_icon.png', 150);
    _markerIcon = resizedIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.fromBytes(resizedIcon);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return _currentPosition == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : WillPopScope(
            onWillPop: () async {
              await _locationSubscription.cancel();
              return Future.value(true);
            },
            child: Stack(
              children: [
                GoogleMap(
                  onCameraMove: (position) {
                    setState(() => _cameraShouldCenter = false);
                  },
                  zoomControlsEnabled: false,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 17.0),
                  markers: {
                    Marker(
                      icon: _markerIcon,
                      markerId: const MarkerId("current_location"),
                      position: _currentPosition!,
                    )
                  },
                ),
                Positioned.fill(
                  bottom: 48.0,
                  left: 32.0,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _cameraShouldCenter = true);
                      },
                      style: ElevatedButtonTheme.of(context).style?.copyWith(
                            shape: const MaterialStatePropertyAll(CircleBorder()),
                            padding: const MaterialStatePropertyAll(EdgeInsets.all(16.0)),
                            elevation: const MaterialStatePropertyAll(4.0),
                          ),
                      child: const Icon(
                        Icons.my_location,
                        semanticLabel: 'Recenter Map',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
