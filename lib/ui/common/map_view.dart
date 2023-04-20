import 'package:apu_rideshare/data/model/map/marker_info.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/map_helper.dart';

class MapView extends StatefulWidget {
  LatLng? userLatLng;
  Set<Polyline> polylines;
  GoogleMapController? mapController;
  final Function(GoogleMapController) setMapController;
  final Function(bool) setShouldCenter;
  Set<MarkerInfo> markers;

  MapView({
    super.key,
    this.userLatLng,
    required this.setShouldCenter,
    required this.polylines,
    required this.setMapController,
    required this.mapController,
    required this.markers,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late String _mapStyle;

  late BitmapDescriptor _locationIcon;

  @override
  void initState() {
    super.initState();

    MapHelper.getMapStyle().then((string) {
      _mapStyle = string;
    });
    MapHelper.getCustomIcon('assets/icons/location.png', locationIconSize)
        .then((icon) => setState(() => _locationIcon = icon));
  }

  void _onMapCreated(GoogleMapController controller) {
    widget.setMapController(controller);
    controller.setMapStyle(_mapStyle);
  }

  Set<Marker> getMarkers() {
    return widget.markers
        .map((e) => Marker(markerId: MarkerId(e.markerId), position: e.position, icon: e.icon ?? _locationIcon))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return widget.userLatLng == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              GoogleMap(
                polylines: widget.polylines != null ? widget.polylines! : <Polyline>{},
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: widget.userLatLng!, zoom: 17.0),
                onCameraMove: (_) {
                  widget.setShouldCenter(false);
                },
                markers: getMarkers(),
              ),
              Positioned.fill(
                bottom: 24.0,
                right: 24.0,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    height: 60,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        MapHelper.resetCamera(widget.mapController, widget.userLatLng!);
                        widget.setShouldCenter(true);
                      },
                      style: ElevatedButtonTheme.of(context).style?.copyWith(
                            shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            padding: const MaterialStatePropertyAll(EdgeInsets.all(16.0)),
                            elevation: const MaterialStatePropertyAll(4.0),
                          ),
                      child: const Icon(
                        Icons.my_location,
                        semanticLabel: 'Recenter Map',
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
