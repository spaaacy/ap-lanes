import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../util/map_helper.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final MapViewState mapViewState = context.watch<MapViewState>();
    final currentPosition = mapViewState.currentPosition;

    return currentPosition == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              GoogleMap(
                markers: mapViewState.markers.values.toSet(),
                polylines: mapViewState.polylines,
                onMapCreated: (controller) => mapViewState.onMapCreated(controller),
                initialCameraPosition: CameraPosition(target: currentPosition, zoom: 17.0),
                rotateGesturesEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                buildingsEnabled: false,
              ),
              if (mapViewState.shouldCenter)
                Positioned.fill(
                  bottom: 24.0,
                  right: 24.0,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      height: 60,
                      width: 60,
                      child: ElevatedButton(
                        onPressed: () async {
                          await MapHelper.resetCamera(mapViewState.mapController, currentPosition);
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
