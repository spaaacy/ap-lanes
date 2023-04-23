import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';
import '../../../data/repo/journey_repo.dart';

class JourneyDetail extends StatefulWidget {
  final String? driverName;
  final String? driverLicensePlate;
  final bool hasDriver;
  final bool isPickedUp;
  final bool inJourney;
  final QueryDocumentSnapshot<Journey>? journey;

  const JourneyDetail({
    super.key,
    required this.driverName,
    required this.driverLicensePlate,
    required this.hasDriver,
    required this.isPickedUp,
    required this.inJourney,
    required this.journey,
  });

  @override
  State<JourneyDetail> createState() => _JourneyDetailState();
}

class _JourneyDetailState extends State<JourneyDetail> {
  final _journeyRepo = JourneyRepo();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: (widget.inJourney) ? 1.0 : 0.0,
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
                          if (widget.driverName != null && widget.driverLicensePlate != null) {
                            return [
                              Text("Driver Name", style: Theme.of(context).textTheme.bodyMedium),
                              Text(widget.driverName!, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("License Plate", style: Theme.of(context).textTheme.bodyMedium),
                              Text(widget.driverLicensePlate!, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                            ];
                          } else {
                            return [Text("Finding an driver...", style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center,)];
                          }
                        }()),
                        SizedBox(height: 8.0),
                        ...?(() {
                          if (widget.journey != null) {
                            return [
                              Text("TO", style: Theme.of(context).textTheme.bodyMedium),
                              Text(widget.journey!.data().endDescription,
                                  style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("FROM", style: Theme.of(context).textTheme.bodyMedium),
                              Text(widget.journey!.data().startDescription,
                                  style: Theme.of(context).textTheme.titleSmall),
                            ];
                          }
                        }())
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 4.0,
                ),
                ...?(() {
                  if (widget.hasDriver && !widget.isPickedUp) {
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
                                            await _journeyRepo.cancelJourneyAsPassenger(widget.journey!);
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
