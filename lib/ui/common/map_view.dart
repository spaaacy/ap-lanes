import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/map_helper.dart';

class MapView extends StatefulWidget {
  LatLng? userLatLng;
  Set<Polyline>? polylines; // TODO: Make non-nullable
  GoogleMapController? mapController; // TODO: Make non-nullable
  final Function(GoogleMapController) setMapController;
  Marker? userMarker; // TODO: Make non-nullable
  Marker? destinationMarker; // TODO: Make non-nullable
  Marker? startMarker; // TODO: Make non-nullable


  MapView(
      {super.key,
      this.userLatLng,
      this.polylines,
      required this.setMapController,
      required this.mapController,
      this.userMarker,
      this.destinationMarker,
      this.startMarker
      });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late String _mapStyle;

  @override
  void initState() {
    super.initState();

    MapHelper.getMapStyle().then((string) {
      _mapStyle = string;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    widget.setMapController(controller);
    controller.setMapStyle(_mapStyle);
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
                  markers: {
                    if (widget.userMarker != null) widget.userMarker!,
                    if (widget.destinationMarker != null) widget.destinationMarker!,
                    if (widget.startMarker != null) widget.startMarker!
                  },
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
