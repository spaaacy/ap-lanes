import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';

class JourneyDetail extends StatefulWidget {
  bool isSearching;
  QueryDocumentSnapshot<Journey>? journey;
  List<String> journeyDetails;

  JourneyDetail({super.key, required this.isSearching, required this.journey, required this.journeyDetails});

  @override
  State<JourneyDetail> createState() => _JourneyDetailState();
}

class _JourneyDetailState extends State<JourneyDetail> {
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: widget.isSearching ? 1.0 : 0.0, duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.all(Radius.circular(8))
          ),
          child:
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.0),
            itemCount: widget.journeyDetails.length,
            itemBuilder: (BuildContext context, int index) {
              return Text(
                widget.journeyDetails[index],
                style: Theme.of(context).textTheme.bodyLarge
              );
            },
          )
        )
    );
  }
}
