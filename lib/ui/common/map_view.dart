import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/map_helper.dart';

class MapView extends StatelessWidget {
  
  final LatLng? userLatLng;
  final Set<Polyline> polylines;
  final GoogleMapController? mapController;
  final Function(GoogleMapController) onMapCreated;
  final Function(bool) setShouldCenter;
  final Map<MarkerId, Marker> markers;

  const MapView({
    super.key,
    this.userLatLng,
    required this.setShouldCenter,
    required this.polylines,
    required this.onMapCreated,
    required this.mapController,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return userLatLng == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              GoogleMap(
                polylines: polylines,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: onMapCreated,
                initialCameraPosition: CameraPosition(target: userLatLng!, zoom: 17.0),
                onCameraMove: (_) {
                  setShouldCenter(false);
                },
                markers: markers.values.toSet(),
              ),
              Positioned.fill(
                bottom: 24.0,
                right: 24.0,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        MapHelper.resetCamera(mapController, userLatLng!);
                        setShouldCenter(true);
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
