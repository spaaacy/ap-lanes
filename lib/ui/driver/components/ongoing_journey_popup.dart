import 'package:apu_rideshare/util/ext_map_launchers.dart';
import 'package:apu_rideshare/util/location_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/model/firestore/journey.dart';
import '../../../data/model/firestore/user.dart';
import '../../../data/repo/user_repo.dart';

enum DriverAction { idle, pickingUp, droppingOff }

class OngoingJourneyPopup extends StatelessWidget {
  OngoingJourneyPopup({
    super.key,
    required this.activeJourney,
    required this.onPickUp,
    required this.onDropOff,
  });

  final DocumentSnapshot<Journey>? activeJourney;
  final UserRepo _userRepo = UserRepo();
  final void Function(DocumentSnapshot<Journey>?) onPickUp;
  final void Function(DocumentSnapshot<Journey>?) onDropOff;

  @override
  Widget build(BuildContext context) {
    final buttonBarTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    DriverAction getCurrentDriverAction() {
      if (activeJourney == null) return DriverAction.idle;

      DriverAction action = DriverAction.pickingUp;
      if (activeJourney!.data()!.isPickedUp && !activeJourney!.data()!.isCompleted) {
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

    return TweenAnimationBuilder(
      curve: Curves.bounceInOut,
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: activeJourney != null ? 1 : 0, end: activeJourney != null ? 0 : 1),
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
                          future: _userRepo.getUser(activeJourney!.data()!.userId),
                          builder: (context, passengerSnapshot) {
                            return Text(
                              passengerSnapshot.hasData ? '${passengerSnapshot.data?.data().fullName}' : 'Loading...',
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
                          // todo: Change based on is picking up or dropping off
                          'Placeholder Here (Put address here when place_id has been added to Journey model)',
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
                        onPressed: () => onPickUp(activeJourney),
                        child: Text(
                          activeJourney?.get('isPickedUp') == true ? 'UNDO PICK-UP' : 'PICK-UP',
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
                        onPressed: () => onDropOff(activeJourney),
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
                            !activeJourney!.data()!.isPickedUp ? Colors.blue : Colors.green,
                          ),
                        ),
                        onPressed: () {
                          if (!activeJourney!.data()!.isPickedUp) {
                            launchWaze(getLatLngFromString(activeJourney!.data()!.startLatLng));
                          } else {
                            launchWaze(getLatLngFromString(activeJourney!.data()!.endLatLng));
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
