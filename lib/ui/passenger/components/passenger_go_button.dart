import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/repo/journey_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../../../data/model/firestore/passenger.dart';
import '../../../data/repo/passenger_repo.dart';

class PassengerGoButton extends StatefulWidget {
  final QueryDocumentSnapshot<Passenger> passenger;
  bool isSearching;
  QueryDocumentSnapshot<Journey>? journey;
  firebase_auth.User? firebaseUser;

  PassengerGoButton({super.key, required this.passenger, required this.isSearching, required this.journey, required this.firebaseUser});

  @override
  State<PassengerGoButton> createState() => _PassengerGoButtonState();
}

class _PassengerGoButtonState extends State<PassengerGoButton> {
  final _journeyRepo = JourneyRepo();
  final _passengerRepo = PassengerRepo();
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (widget.firebaseUser != null) {
          if (!widget.isSearching) {

            setState(() {
              widget.isSearching = true;
            });

            // Update passenger to isSearching true
            _passengerRepo.updateIsSearching(widget.passenger, true);

            _journeyRepo.createJourney(
                  Journey(
                  userId: widget.firebaseUser!.uid,
                  // TODO: Implement actual locations
                  startPoint: "3.055513736582056, 101.69617610900454", // Parkhill
                  destination: "3.0557922212826236, 101.70035141013787", // APU
                  isCompleted: false
                  )
              );

            } else {
            setState(() {
              widget.isSearching = false;
            });

            _passengerRepo.updateIsSearching(widget.passenger, false);

            _journeyRepo.deleteJourney(widget.journey);
          }
        }
      },
      style: ElevatedButtonTheme.of(context).style?.copyWith(
            shape: const MaterialStatePropertyAll(CircleBorder()),
            padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
            elevation: const MaterialStatePropertyAll(6.0),
          ),
      child:
          !widget.isSearching ?
            const Text("GO")
            : const Icon(Icons.close, semanticLabel: "Cancel Search", size: 20,)
    );
  }
}
