import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';
import '../../../data/repo/journey_repo.dart';

class JourneyDetail extends StatefulWidget {
  final bool hasDriver;
  final bool isPickedUp;
  final QueryDocumentSnapshot<Journey>? journey;
  final List<String> journeyDetails;

  const JourneyDetail({
    super.key,
    required this.hasDriver,
    required this.isPickedUp,
    required this.journey,
    required this.journeyDetails,
  });

  @override
  State<JourneyDetail> createState() => _JourneyDetailState();
}

class _JourneyDetailState extends State<JourneyDetail> {

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: (widget.journeyDetails.isNotEmpty) ? 1.0 : 0.0,
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.journeyDetails.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Text(
                              widget.journeyDetails[index],
                              style: Theme.of(context).textTheme.titleSmall,
                            );
                          },
                        ),

                        SizedBox(height: 8.0,),

                        Text("TO",style: Theme.of(context).textTheme.bodyMedium ,),
                        Text(widget.journey!.data().endDescription, style: Theme.of(context).textTheme.titleSmall)
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
                                            await FirebaseFirestore.instance.runTransaction((transaction) async {
                                              final snapshot = await transaction.get(widget.journey!.reference);
                                              if (snapshot.data()?.isPickedUp != true) {
                                                widget.journey!.reference.update({"isCancelled": true});
                                              } else {
                                                throw Exception("Cannot cancel after picking up.");
                                              }
                                            });
                                          } catch (exception) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Sorry, you cannot cancel the journey after being picked up."))
                                            );
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
