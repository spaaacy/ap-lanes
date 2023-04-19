import 'dart:async';

import 'package:apu_rideshare/ui/driver/state/driver_home_state.dart';
import 'package:apu_rideshare/util/location_helpers.dart';
import 'package:apu_rideshare/util/url_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/model/firestore/driver.dart';
import '../../../data/model/firestore/journey.dart';
import '../../../data/model/firestore/user.dart';
import '../../../data/repo/user_repo.dart';

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
  Timer? timer;

  void updateDriverLatLng() {
    DriverHomeState state = Provider.of<DriverHomeState>(context, listen: false);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      if (state.driver == null) return;

      var ss = await transaction.get<Driver>(state.driver!.reference);
      var pos = await Geolocator.getCurrentPosition();

      transaction.update(ss.reference, {'currentLatLng': '${pos.latitude},${pos.longitude}'});
    });
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
                Material(
                  elevation: 2,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getStatusMessage(),
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black45),
                        ),
                        FutureBuilder<QueryDocumentSnapshot<User>>(
                          future: _userRepo.getUser(widget.activeJourney!.data()!.userId),
                          builder: (context, passengerSnapshot) {
                            return Text(
                              passengerSnapshot.hasData
                                  ? '${passengerSnapshot.data?.data().getFullName()}'
                                  : 'Loading...',
                              style: Theme.of(context).textTheme.titleMedium,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AT',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black45),
                        ),
                        Text(
                          getTargetLocation(),
                          style: Theme.of(context).textTheme.titleMedium,
                        )
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
                    Expanded(
                      child: FilledButton(
                        style: buttonBarTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                        ),
                        onPressed: () => widget.onPickUp(widget.activeJourney),
                        child: Text(
                          widget.activeJourney?.get('isPickedUp') == true ? 'UNDO PICK-UP' : 'PICK-UP',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 0,
                      child: FilledButton(
                        style: buttonBarTheme?.copyWith(
                          backgroundColor: MaterialStatePropertyAll(
                            !widget.activeJourney!.data()!.isPickedUp ? Colors.blue : Colors.green,
                          ),
                        ),
                        onPressed: () {
                          if (!widget.activeJourney!.data()!.isPickedUp) {
                            launchWaze(getLatLngFromString(widget.activeJourney!.data()!.startLatLng));
                          } else {
                            launchWaze(getLatLngFromString(widget.activeJourney!.data()!.endLatLng));
                          }
                        },
                        child: SvgPicture.asset(
                          'assets/icons/waze.svg',
                          height: 20,
                          width: 20,
                        ),
                      ),
                    )
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
