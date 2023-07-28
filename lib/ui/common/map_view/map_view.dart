import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => MapViewState1();
}

class MapViewState1 extends State<MapView> with TickerProviderStateMixin {
  AnimationController? animationController;
  MapViewState2? mapViewState;

  @override
  void initState() {
    super.initState();
    context.read<MapViewState2>().mapView = this;
  }

  @override
  Widget build(BuildContext context) {
    mapViewState = context.watch<MapViewState2>();
    final token = dotenv.env['JAWG_TOKEN']!;

    return mapViewState!.currentPosition == null
        ? Center(
            child: (mapViewState!.locationPermissions) ? const CircularProgressIndicator() : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_disabled_rounded, size: 35),
                SizedBox(
                  height: 12.0,
                ),
                Text("Location has been disabled."),
                Text("Please enable locations in your settings.")
              ],
            ),
          )
        : Stack(
            children: [
              FlutterMap(
                  mapController: mapViewState!.mapController,
                  options: MapOptions(
                    onMapReady: () => mapViewState!.isMapReady = true,
                    interactiveFlags: mapViewState!.shouldCenter
                        ? InteractiveFlag.all & ~InteractiveFlag.rotate
                        : InteractiveFlag.none,
                    center: mapViewState!.currentPosition,
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
                          'https://{s}.tile.jawg.io/jawg-sunny/{z}/{x}/{y}{r}.png?access-token=$token',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      tileProvider: FMTC.instance('mapStore').getTileProvider(),
                    ),
                    MarkerLayer(markers: mapViewState!.markers.values.toList()),
                    PolylineLayer(
                      polylines: mapViewState!.polylines.toList(),
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

  void animateCamera(LatLng destLocation, double destZoom) {
    if (mapViewState != null) {
      const startedId = 'AnimatedMapController#MoveStarted';
      const inProgressId = 'AnimatedMapController#MoveInProgress';
      const finishedId = 'AnimatedMapController#MoveFinished';

      final latTween = Tween<double>(begin: mapViewState!.mapController.center.latitude, end: destLocation.latitude);
      final lngTween = Tween<double>(begin: mapViewState!.mapController.center.longitude, end: destLocation.longitude);
      final zoomTween = Tween<double>(begin: mapViewState!.mapController.zoom, end: destZoom);

      final animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

      final Animation<double> animation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);

      final startIdWithTarget = '$startedId#${destLocation.latitude},${destLocation.longitude},$destZoom';
      bool hasTriggeredMove = false;

      animationController.addListener(() {
        final String id;
        if (animation.value == 1.0) {
          id = finishedId;
        } else if (!hasTriggeredMove) {
          id = startIdWithTarget;
        } else {
          id = inProgressId;
        }

        hasTriggeredMove |= mapViewState!.mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
          id: id,
        );
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animationController.dispose();
        } else if (status == AnimationStatus.dismissed) {
          animationController.dispose();
        }
      });

      animationController.forward();
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}
