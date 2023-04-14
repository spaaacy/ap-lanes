import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/repo/journey_repo.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerGoButton extends StatefulWidget{
  PassengerGoButton({super.key});

  @override
  State<PassengerGoButton> createState() => _PassengerGoButtonState();


}

class _PassengerGoButtonState extends State<PassengerGoButton> {
  final _journeyRepo = JourneyRepo();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<firebase_auth.User?>();

    return ElevatedButton(
      onPressed: () {
        _journeyRepo.createJourney(
          Journey(
            userId: user.uid,

          )
        )
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
