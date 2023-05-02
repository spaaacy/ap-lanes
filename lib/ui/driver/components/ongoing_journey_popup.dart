import 'dart:async';

import 'package:ap_lanes/ui/driver/new_driver_home_state.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../util/url_helpers.dart';

enum DriverAction { idle, pickingUp, droppingOff }

class OngoingJourneyPopup extends StatefulWidget {
  const OngoingJourneyPopup({super.key});

  @override
  State<OngoingJourneyPopup> createState() => _OngoingJourneyPopupState();
}

class _OngoingJourneyPopupState extends State<OngoingJourneyPopup> {
  void _handleNavigationAppLaunch(String value) {
    final state = Provider.of<NewDriverHomeState>(context, listen: false);

    Future<void> Function(LatLng latLng) launchFunction;
    switch (value) {
      case 'google-maps':
        launchFunction = launchGoogleMaps;
        break;
      case 'waze':
      default:
        launchFunction = launchWaze;
        break;
    }

    if (!state.activeJourney!.data().isPickedUp) {
      launchFunction(state.activeJourney!.data().startLatLng);
    } else {
      launchFunction(state.activeJourney!.data().endLatLng);
    }
  }

  DriverAction _getCurrentDriverAction() {
    final state = Provider.of<NewDriverHomeState>(context, listen: false);

    if (state.activeJourney == null) return DriverAction.idle;

    DriverAction action = DriverAction.pickingUp;
    if (state.activeJourney!.data().isPickedUp && !state.activeJourney!.data().isCompleted) {
      action = DriverAction.droppingOff;
    }
    return action;
  }

  String _getStatusMessage() {
    switch (_getCurrentDriverAction()) {
      case DriverAction.droppingOff:
        return "DROPPING OFF";
      case DriverAction.pickingUp:
        return "PICKING UP";
      case DriverAction.idle:
      default:
        return "IDLE";
    }
  }

  String _getTargetLocation() {
    final state = Provider.of<NewDriverHomeState>(context, listen: false);

    switch (_getCurrentDriverAction()) {
      case DriverAction.droppingOff:
        return state.activeJourney!.data().endDescription;
      case DriverAction.pickingUp:
        return state.activeJourney!.data().startDescription;
      case DriverAction.idle:
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<NewDriverHomeState>(context);

    if (state.activeJourney == null) return const SizedBox.shrink();

    final buttonBarTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return Positioned.fill(
      left: 12,
      right: 12,
      top: 12,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusMessage(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                ),
                Text(
                  'Loading...',
                  // todo: state.activeJourneyPassenger?.data().getFullName() ?? 'Loading...',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'AT',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                ),
                Text(
                  trimDescription(_getTargetLocation()),
                  style: Theme.of(context).textTheme.titleSmall,
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 44,
                width: 62,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Colors.black,
                      strokeAlign: BorderSide.strokeAlignInside,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(150),
                  ),
                ),
                child: PopupMenuButton<String>(
                  onSelected: _handleNavigationAppLaunch,
                  icon: const Icon(Icons.navigation, size: 20),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'waze',
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/waze.svg',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text('Waze')
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'google-maps',
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/google_maps.svg',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text('Google Maps')
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: buttonBarTheme?.copyWith(
                  elevation: const MaterialStatePropertyAll(0),
                  padding: const MaterialStatePropertyAll(
                    EdgeInsets.all(10),
                  ),
                  side: const MaterialStatePropertyAll(
                    BorderSide(color: Colors.black, width: 2.0),
                  ),
                  foregroundColor: const MaterialStatePropertyAll(Colors.black),
                ),
                onPressed: () => {},
                // todo: onPressed: () => launchUrl(Uri.parse("tel://${state.activeJourneyPassenger?.data().phoneNumber.trim()}")),
                child: const Icon(Icons.phone),
              ),
              const SizedBox(width: 8),
              (() {
                if (state.activeJourney?.get('isPickedUp') == true) {
                  return OutlinedButton(
                    style: buttonBarTheme?.copyWith(
                      elevation: const MaterialStatePropertyAll(0),
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.all(10),
                      ),
                      side: const MaterialStatePropertyAll(
                        BorderSide(color: Colors.blue, width: 2.0),
                      ),
                      foregroundColor: const MaterialStatePropertyAll(Colors.blue),
                    ),
                    // todo: onPressed: () => state.onJourneyPickUp(),
                    onPressed: () => {},
                    child: const Icon(Icons.undo),
                  );
                } else {
                  return Expanded(
                    child: FilledButton(
                      style: buttonBarTheme?.copyWith(
                        backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                      ),
                      // todo: onPressed: () => state.onJourneyPickUp(),
                      onPressed: () => {},
                      child: Text(
                        'PICK-UP',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                }
              }()),
              ...?(() {
                if (state.activeJourney?.get('isPickedUp') == true) {
                  return [
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: buttonBarTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.green),
                        ),
                        // todo: onPressed: () => state.onJourneyDropOff(),
                        onPressed: () => {},
                        child: Text(
                          'DROP-OFF',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    )
                  ];
                }
              }()),
            ],
          ),
        ],
      ),
    );
  }
}
