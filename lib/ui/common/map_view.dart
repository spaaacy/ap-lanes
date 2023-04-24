import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../util/map_helper.dart';

class MapView extends StatelessWidget {
  
  LatLng? userLatLng;
  Set<Polyline> polylines;
  GoogleMapController? mapController;
  final Function(GoogleMapController) setMapController;
  final Function(bool) setShouldCenter;
  Map<MarkerId, Marker> markers;

  MapView({
    super.key,
    this.userLatLng,
    required this.setShouldCenter,
    required this.polylines,
    required this.setMapController,
    required this.mapController,
    required this.markers,
  });
  
  late String _mapStyle;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    setMapController(controller);
    _mapStyle = await MapHelper.getMapStyle();
    controller.setMapStyle(_mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return userLatLng == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              GoogleMap(
                polylines: polylines != null ? polylines! : <Polyline>{},
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
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
                  child: Container(
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
