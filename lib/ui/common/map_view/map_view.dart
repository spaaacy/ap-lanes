import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _State();
}

class _State extends State<MapView> with TickerProviderStateMixin {
  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    context.read<MapViewState>().ticker = this;
    animationController = context.read<MapViewState>().animationController;
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
                    interactiveFlags: mapViewState.shouldCenter ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
                    center: mapViewState.currentPosition,
                    zoom: 17,
                    minZoom: 7,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      minZoom: 1,
                      maxZoom: 18,
                      backgroundColor: Colors.white,
                      urlTemplate:
                          'https://{s}.tile.jawg.io/jawg-sunny/{z}/{x}/{y}{r}.png?access-token=WdQDiqGUjI4uwIVOFpp11bNpyin0ZxbRZ9FTxAB2b9Y0Fq6uFOARf8w297TPqGzJ',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      tileProvider: FMTC.instance('mapStore').getTileProvider(),
                    ),
                    MarkerLayer(markers: mapViewState.markers.values.toList()),
                    PolylineLayer(
                      polylines: mapViewState.polylines.toList(),
                    )
                  ]),
              Positioned.fill(
                  child: Align(
                alignment: Alignment.bottomLeft,
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(

                              title: const Text("Map Attributions"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextButton(
                                    onPressed: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'),
                                        mode: LaunchMode.externalApplication),
                                    child: const Text("© OpenStreetMap Contributors"),
                                  ),
                                  TextButton(
                                    onPressed: () => launchUrl(Uri.parse('https://www.jawg.io/en/'),
                                        mode: LaunchMode.externalApplication),
                                    child: const Text("© Jawg Maps"),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, "Okay");
                                    },
                                    child: const Text("Okay")),
                              ]);
                        });
                  },
                ),
              ))
            ],
          );
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

}
