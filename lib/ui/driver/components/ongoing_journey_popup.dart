import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:provider/provider.dart';

import '../../../data/model/remote/driver.dart';
import '../../../data/model/remote/journey.dart';
import '../../../data/model/remote/user.dart';
import '../../../data/repo/driver_repo.dart';
import '../../../data/repo/user_repo.dart';
import '../../../util/url_helpers.dart';
import '../driver_home_state.dart';

enum DriverAction { idle, pickingUp, droppingOff }

class OngoingJourneyPopup extends StatefulWidget {
  final DocumentSnapshot<Journey>? activeJourney;
  final void Function(DocumentSnapshot<Journey>?) onPickUp;
  final void Function(DocumentSnapshot<Journey>?) onDropOff;

  const OngoingJourneyPopup({
    super.key,
    required this.activeJourney,
    required this.onPickUp,
    required this.onDropOff,
  });

  @override
  State<OngoingJourneyPopup> createState() => _OngoingJourneyPopupState();
}

class _OngoingJourneyPopupState extends State<OngoingJourneyPopup> {
  final UserRepo _userRepo = UserRepo();
  final DriverRepo _driverRepo = DriverRepo();
  Timer? timer;

  Future<void> updateDriverLatLng() async {
    DriverHomeState state = Provider.of<DriverHomeState>(context, listen: false);
    if (state.driver == null) return;
    var pos = await Geolocator.getCurrentPosition();
    _driverRepo.updateDriver(state.driver! , {'currentLatLng': '${pos.latitude}, ${pos.longitude}'});
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 15), (timer) => updateDriverLatLng());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonBarTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    DriverAction getCurrentDriverAction() {
      if (widget.activeJourney == null) return DriverAction.idle;

      DriverAction action = DriverAction.pickingUp;
      if (widget.activeJourney!.data()!.isPickedUp && !widget.activeJourney!.data()!.isCompleted) {
        action = DriverAction.droppingOff;
      }
      return action;
    }

    String getStatusMessage() {
      switch (getCurrentDriverAction()) {
        case DriverAction.droppingOff:
          return "DROPPING OFF";
        case DriverAction.pickingUp:
          return "PICKING UP";
        case DriverAction.idle:
        default:
          return "IDLE";
      }
    }

    String getTargetLocation() {
      switch (getCurrentDriverAction()) {
        case DriverAction.droppingOff:
          return widget.activeJourney!.data()!.endDescription;
        case DriverAction.pickingUp:
          return widget.activeJourney!.data()!.startDescription;
        case DriverAction.idle:
        default:
          return "Unknown";
      }
    }

    return TweenAnimationBuilder(
      curve: Curves.bounceInOut,
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: widget.activeJourney != null ? 1 : 0, end: widget.activeJourney != null ? 0 : 1),
      builder: (_, topOffset, w) {
        return Positioned.fill(
          left: 12,
          right: 12,
          top: 12 - (200 * topOffset),
          child: Visibility(
            visible: topOffset != 1,
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
                        getStatusMessage(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      FutureBuilder<QueryDocumentSnapshot<User>?>(
                        future: _userRepo.getUser(widget.activeJourney!.data()!.userId),
                        builder: (context, passengerSnapshot) {
                          return Text(
                            passengerSnapshot.hasData
                                ? '${passengerSnapshot.data?.data().getFullName()}'
                                : 'Loading...',
                            style: Theme.of(context).textTheme.titleSmall,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AT',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      Text(
                        getTargetLocation(),
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
                        onSelected: (value) {
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

                          if (!widget.activeJourney!.data()!.isPickedUp) {
                            launchFunction(widget.activeJourney!.data()!.startLatLng);
                          } else {
                            launchFunction(widget.activeJourney!.data()!.endLatLng);
                          }
                        },
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
                    (() {
                      if (widget.activeJourney?.get('isPickedUp') == true) {
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
                          onPressed: () => widget.onPickUp(widget.activeJourney),
                          child: const Icon(Icons.undo),
                        );
                      } else {
                        return Expanded(
                          child: FilledButton(
                            style: buttonBarTheme?.copyWith(
                              backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                            ),
                            onPressed: () => widget.onPickUp(widget.activeJourney),
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
                      if (widget.activeJourney?.get('isPickedUp') == true) {
                        return [
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              style: buttonBarTheme?.copyWith(
                                backgroundColor: const MaterialStatePropertyAll(Colors.green),
                              ),
                              onPressed: () => widget.onDropOff(widget.activeJourney),
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
          ),
        );
      },
    );
  }
}
