import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/model/remote/journey.dart';
import '../../../data/repo/journey_repo.dart';
import '../../../util/location_helpers.dart';

class JourneyDetail extends StatelessWidget {
  final String? driverName;
  final String? driverLicensePlate;
  final bool hasDriver;
  final bool isPickedUp;
  final bool inJourney;
  final QueryDocumentSnapshot<Journey>? journey;

  JourneyDetail({
    super.key,
    required this.driverName,
    required this.driverLicensePlate,
    required this.hasDriver,
    required this.isPickedUp,
    required this.inJourney,
    required this.journey,
  });

  final _journeyRepo = JourneyRepo();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: (inJourney) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(() {
                          if (driverName != null && driverLicensePlate != null) {
                            return [
                              Text("Your Driver",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(driverName!, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("License Plate",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(driverLicensePlate!, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                            ];
                          } else {
                            return [
                              Text(
                                "Finding an driver...",
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              )
                            ];
                          }
                        }()),
                        const SizedBox(height: 8.0),
                        ...?(() {
                          if (journey != null) {
                            return [
                              Text("TO", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(trimDescription(journey!.data().endDescription), style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("FROM",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(trimDescription(journey!.data().startDescription), style: Theme.of(context).textTheme.titleSmall),
                            ];
                          }
                        }())
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                ...?(() {
                  if (hasDriver && !isPickedUp) {
                    return [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Cancel journey"),
                                  content: const Text("Are you sure you would like to cancel your journey?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, "No");
                                        },
                                        child: const Text("No")),
                                    TextButton(
                                        onPressed: () async {
                                          try {
                                            await _journeyRepo.cancelJourneyAsPassenger(journey!);
                                          } catch (exception) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                content: Text(
                                                    "Sorry, you cannot cancel the journey after being picked up.")));
                                          } finally {
                                            Navigator.pop(context, "Yes");
                                          }
                                        },
                                        child: const Text("Yes")),
                                  ],
                                );
                              });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Text("Cancel"),
                        ),
                      )
                    ];
                  }
                }())
              ],
            ),
          ),
        ),
      ),
    );
  }
}
