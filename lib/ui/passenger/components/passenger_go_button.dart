import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/repo/journey_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/model/firestore/passenger.dart';
import '../../../data/repo/passenger_repo.dart';

class PassengerGoButton extends StatefulWidget {
  final QueryDocumentSnapshot<Passenger> passenger;
  PassengerGoButton({super.key, required this.passenger});

  @override
  State<PassengerGoButton> createState() => _PassengerGoButtonState();
}

class _PassengerGoButtonState extends State<PassengerGoButton> {
  final _journeyRepo = JourneyRepo();
  final _passengerRepo = PassengerRepo();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<firebase_auth.User?>();

    return ElevatedButton(
      onPressed: () {
        // Create a journey
        _journeyRepo.createJourney(Journey(
            userId: user!.uid,
            // TODO: Implement actual locations
            startPoint: "3.055513736582056, 101.69617610900454", // Parkhill
            destination: "3.0557922212826236, 101.70035141013787", // APU
            isCompleted: false));

        // Update passenger to isSearching true
        _passengerRepo
            .updateIsSearching(widget.passenger, {"isSearching": true});
      },
      style: ElevatedButtonTheme.of(context).style?.copyWith(
            shape: const MaterialStatePropertyAll(CircleBorder()),
            padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
            elevation: const MaterialStatePropertyAll(6.0),
          ),
      child: const Text("GO"),
    );
  }
}
