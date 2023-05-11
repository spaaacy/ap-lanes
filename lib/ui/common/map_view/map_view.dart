import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _State();
}

class _State extends State<MapView> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    context.read<MapViewState>().mapView = this;
  }

  @override
  Widget build(BuildContext context) {
    final MapViewState mapViewState = context.watch<MapViewState>();

    return mapViewState.currentPosition == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              FlutterMap(
                  mapController: mapViewState.mapController,
                  options: MapOptions(
                    onMapReady: () => mapViewState.isMapReady = true,
                    interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    center: mapViewState.currentPosition,
                    zoom: 17,
                    minZoom: 7,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      minZoom: 1,
                      maxZoom: 18,
                      backgroundColor: Colors.black,
                      urlTemplate:
                          'https://{s}.tile.jawg.io/jawg-sunny/{z}/{x}/{y}{r}.png?access-token=WdQDiqGUjI4uwIVOFpp11bNpyin0ZxbRZ9FTxAB2b9Y0Fq6uFOARf8w297TPqGzJ',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      // tileProvider: FMTC.instance('mapStore').getTileProvider(),
                    ),
                    MarkerLayer(markers: mapViewState.markers.values.toList()),
                    PolylineLayer(
                      polylines: mapViewState.polylines.toList(),
                    )
                  ]),
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
                          await mapViewState.resetCamera();
                        },
                        style: ElevatedButtonTheme.of(context).style?.copyWith(
                              shape: const MaterialStatePropertyAll(CircleBorder()),
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
