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
  bool isSearching;
  Function(bool) updateIsSearching;
  Function() createJourney;
  Function() deleteJourney;

  PassengerGoButton(
      {super.key,
      required this.isSearching,
      required this.updateIsSearching,
      required this.createJourney,
      required this.deleteJourney
      });

  @override
  State<PassengerGoButton> createState() => _PassengerGoButtonState();
}

class _PassengerGoButtonState extends State<PassengerGoButton> {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    return ElevatedButton(
      onPressed: () {
        if (firebaseUser != null) {
          if (!widget.isSearching) {
            widget.updateIsSearching(true);
            widget.createJourney();
            } else {
            widget.updateIsSearching(false);
            widget.deleteJourney();
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
