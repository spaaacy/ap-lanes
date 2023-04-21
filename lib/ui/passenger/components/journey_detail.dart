import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';

class JourneyDetail extends StatefulWidget {
  final bool isSearching;
  final bool hasDriver;
  final bool isPickedUp;
  final QueryDocumentSnapshot<Journey>? journey;
  final List<String> journeyDetails;

  const JourneyDetail({
    super.key,
    required this.isSearching,
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
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.journeyDetails.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Text(
                        widget.journeyDetails[index],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),

                SizedBox(height: 4.0,),

                ...?(() {
                  if (widget.hasDriver && !widget.isPickedUp) {
                    return [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red
                        ),
                        onPressed: () {
                          // TODO: Call journey cancel
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
