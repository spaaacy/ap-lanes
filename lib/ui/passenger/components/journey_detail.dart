import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';

class JourneyDetail extends StatefulWidget {
  final bool isSearching;
  final bool hasDriver;
  final QueryDocumentSnapshot<Journey>? journey;
  final List<String> journeyDetails;

  const JourneyDetail({
    super.key,
    required this.isSearching,
    required this.hasDriver,
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
            child: Container(
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
          ),
        ),
      ),
    );

    // return TweenAnimationBuilder(
    //     curve: Curves.decelerate,
    //     duration: Duration(milliseconds: 150),
    //     tween: Tween<double>(
    //         begin: (widget.isSearching || widget.hasDriver) ? 1 : 0,
    //         end: (widget.isSearching || widget.hasDriver) ? 0 : 1),
    //     builder: (_, offset, child) {
    //       return Positioned(
    //         top: 250, // -250 * offset,
    //           child: Align(
    //             alignment: Alignment.topCenter,
    //             child: Padding(
    //               padding: const EdgeInsets.all(24.0),
    //                     child: Material(
    //                       borderRadius: BorderRadius.circular(12),
    //                       color: Colors.black54,
    //                       child: Padding(
    //                           padding: EdgeInsets.all(16.0),
    //                           child: widget.hasDriver
    //                           ?
    //                                   ListView.builder(
    //                                     shrinkWrap: true,
    //                                     physics: NeverScrollableScrollPhysics(),
    //                                     itemCount: widget.journeyDetails.length,
    //                                     itemBuilder: (BuildContext context, int index) {
    //                                       return Text(widget.journeyDetails[index],
    //                                           style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white));
    //                                     },
    //                                   )
    //                           : Text("Finding a driver",
    //                                   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
    //             ),
    //                     ),
    //             ),
    //           ),
    //       );
    //     });
  }
}
