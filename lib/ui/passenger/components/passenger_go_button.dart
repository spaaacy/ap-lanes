import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerGoButton extends StatelessWidget {
  bool isSearching;
  bool hasDriver;
  Function(bool) updateIsSearching;
  Function() createJourney;
  Function() deleteJourney;

  PassengerGoButton(
      {super.key,
        required this.isSearching,
        required this.hasDriver,
        required this.updateIsSearching,
        required this.createJourney,
        required this.deleteJourney
      });
  
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();

    if (!hasDriver) {
    return
      ElevatedButton(
      onPressed: () {
        if (firebaseUser != null) {
          if (!isSearching) {
            updateIsSearching(true);
            createJourney();
            } else {
            updateIsSearching(false);
            deleteJourney();
          }
        }
      },
      style: ElevatedButtonTheme.of(context).style?.copyWith(
            shape: const MaterialStatePropertyAll(CircleBorder()),
            padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
            elevation: const MaterialStatePropertyAll(6.0),
          ),
      child:
          !isSearching ?
            const Text("GO")
            : const Icon(Icons.close, semanticLabel: "Cancel Search", size: 20,)
    );
    } else {
      return SizedBox.shrink();
    }
  }
}
