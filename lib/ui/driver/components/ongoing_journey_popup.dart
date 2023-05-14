import 'dart:async';

import 'package:ap_lanes/ui/driver/components/ongoing_journey_popup_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
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
    final state = Provider.of<OngoingJourneyPopupState>(context, listen: false);

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

  void _handleContactAppLaunch(String value, String phoneNumber) {
    switch (value) {
      case 'whatsapp':
        launchWhatsApp(phoneNumber);
        break;
      case 'phone':
      default:
        launchUrl(Uri.parse("tel://${phoneNumber.trim()}"));
        break;
    }
  }

  DriverAction _getCurrentDriverAction() {
    final state = Provider.of<OngoingJourneyPopupState>(context, listen: false);

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
    final state = Provider.of<OngoingJourneyPopupState>(context, listen: false);

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
    final state = Provider.of<DriverHomeState>(context);

    if (state.driverState != DriverState.ongoing) return const SizedBox.shrink();

    final ongoingState = Provider.of<OngoingJourneyPopupState>(context);

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
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: ongoingState.isLoadingJourneyRequest
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
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
              PopupMenuButton<String>(
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
              PopupMenuButton<String>(
                onSelected: (value) => _handleContactAppLaunch(
                  value,
                  ongoingState.activeJourneyPassenger?.data().phoneNumber ?? "",
                ),
                icon: const Icon(Icons.phone, size: 22),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'phone',
                    child: Row(
                      children: const [
                        Icon(Icons.phone),
                        SizedBox(width: 8),
                        Text('Call'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/whatsapp.svg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text('WhatsApp'),
                      ],
                    ),
                  )
                ],
              ),
              (() {
                if (ongoingState.activeJourney?.get('isPickedUp') == true) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: ongoingState.isLoadingJourneyRequest ? null : () => ongoingState.onJourneyPickUp(),
                    child: const Text('UNDO PICK-UP'),
                  );
                } else {
                  return Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
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
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
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
