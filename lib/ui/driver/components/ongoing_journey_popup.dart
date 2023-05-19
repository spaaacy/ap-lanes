import 'dart:async';

import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup_provider.dart';
import 'package:ap_lanes/ui/driver/driver_home_provider.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../util/url_helpers.dart';

enum DriverAction { idle, pickingUp, droppingOff }

class OngoingJourneyPopup extends StatefulWidget {
  const OngoingJourneyPopup({super.key});

  @override
  State<OngoingJourneyPopup> createState() => _OngoingJourneyPopupState();
}

class _OngoingJourneyPopupState extends State<OngoingJourneyPopup> {
  void _handleNavigationAppLaunch(String value) {
    final state = Provider.of<OngoingJourneyPopupProvider>(context, listen: false);

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
    final state = Provider.of<OngoingJourneyPopupProvider>(context, listen: false);

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
    final state = Provider.of<OngoingJourneyPopupProvider>(context, listen: false);

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
    final state = Provider.of<DriverHomeProvider>(context);

    if (state.driverState != DriverState.ongoing) return const SizedBox.shrink();

    final ongoingState = Provider.of<OngoingJourneyPopupProvider>(context);

    return Positioned.fill(
      left: 12,
      right: 12,
      top: 12,
      child: Column(
        children: [
          Material(
            elevation: ongoingState.isLoadingJourneyRequest ? 0.0 : 4.0,
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ongoingState.isLoadingJourneyRequest
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusMessage(),
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                                ),
                                Text(
                                  ongoingState.activeJourneyPassenger?.data().getFullName() ?? 'Loading...',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                                onPressed: () {
                                  launchWhatsApp(ongoingState.activeJourneyPassenger?.data().phoneNumber ?? "");
                                },
                                icon: SvgPicture.asset(
                                  'assets/icons/whatsapp.svg',
                                  height: 30,
                                  width: 30,
                                )),
                            IconButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse("tel://${ongoingState.activeJourneyPassenger?.data().phoneNumber}"),
                                );
                              },
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AT',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                        ),
                        Text(
                          trimDescription(_getTargetLocation()),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRICE',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                                ),
                                Text(
                                  "RM ${ongoingState.activeJourney?.data().price ?? '0.00'}",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PAYMENT MODE',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                                ),
                                Text(
                                  ongoingState.activeJourney?.data().paymentMode ?? "Loading",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                height: 48,
                child: Material(
                  elevation: ongoingState.isLoadingJourneyRequest ? 0.0 : 4.0,
                  shape: const CircleBorder(),
                  child: PopupMenuButton<String>(
                    onSelected: _handleNavigationAppLaunch,
                    icon: const Icon(Icons.navigation, size: 16),
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
              ),
              const SizedBox(width: 8),
              (() {
                if (ongoingState.activeJourney?.get('isPickedUp') == true) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: ongoingState.isLoadingJourneyRequest ? 0.0 : 4.0,
                    ),
                    onPressed: ongoingState.isLoadingJourneyRequest ? null : () => ongoingState.onJourneyPickUp(),
                    child: const Text('UNDO PICK-UP'),
                  );
                } else {
                  return Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: ongoingState.isLoadingJourneyRequest ? 0.0 : 4.0,
                      ),
                      onPressed: ongoingState.isLoadingJourneyRequest ? null : () => ongoingState.onJourneyPickUp(),
                      child: Text(
                        'CONFIRM PICK-UP',
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
                if (ongoingState.activeJourney?.get('isPickedUp') == true) {
                  return [
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: ongoingState.isLoadingJourneyRequest ? 0.0 : 4.0,
                        ),
                        onPressed: ongoingState.isLoadingJourneyRequest ? null : () => ongoingState.onJourneyDropOff(),
                        child: Text(
                          'CONFIRM DROP-OFF',
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
