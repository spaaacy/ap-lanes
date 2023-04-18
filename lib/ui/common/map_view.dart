import 'dart:async';

import 'package:apu_rideshare/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/map_helper.dart';

class MapView extends StatefulWidget {
  LatLng? destinationLatLng;
  String? userLocationDescription;
  Set<Polyline>? polylines; // TODO: Make non-nullable
  GoogleMapController? mapController; // TODO: Make non-nullable
  final Function(GoogleMapController) setMapController;
  BitmapDescriptor? destinationIcon; // TODO: Make non-nullable
  Marker? destinationMarker; // TODO: Make non-nullable

  MapView(
      {super.key,
      this.destinationLatLng,
      this.userLocationDescription,
      this.polylines,
      required this.setMapController,
      required this.mapController,
      this.destinationIcon,
      this.destinationMarker});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _cameraShouldCenter = true;
  LatLng? _currentPosition;
  late String _mapStyle;
  late StreamSubscription<Position> _locationSubscription;
  late Marker _userMarker;
  late BitmapDescriptor _userIcon;

  @override
  void initState() {
    super.initState();

    MapHelper.getMapStyle().then((string) {
      _mapStyle = string;
    });

    MapHelper.getCustomIcon('assets/images/marker_icon.png') // TODO: Use different icon
        .then((icon) => _userIcon = icon);

    _locationSubscription = MapHelper.getCurrentPosition(context).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _userMarker = Marker(markerId: const MarkerId("user-marker"), position: _currentPosition!, icon: _userIcon);
      });

      if (_cameraShouldCenter) {
        widget.mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17.0));
      }

    });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    widget.setMapController(controller);
    controller.setMapStyle(_mapStyle);
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
                  polylines: widget.polylines != null ? widget.polylines! : <Polyline>{},
                  mapToolbarEnabled: false,
                  onCameraMove: (position) {
                    setState(() => _cameraShouldCenter = false);
                  },
                  zoomControlsEnabled: false,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 17.0),
                  markers: {
                    _userMarker,
                    if (widget.destinationMarker != null) widget.destinationMarker!
                  },
                ),

                Positioned.fill(
                  bottom: 24.0,
                  right: 24.0,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _cameraShouldCenter = true);
                      },
                      style: ElevatedButtonTheme.of(context).style?.copyWith(
                            shape: MaterialStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
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
