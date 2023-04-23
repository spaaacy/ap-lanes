import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PassengerGoButton extends StatefulWidget {
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
  State<PassengerGoButton> createState() => _PassengerGoButtonState();
}

class _PassengerGoButtonState extends State<PassengerGoButton> {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();

    if (!widget.hasDriver) {
    return
      ElevatedButton(
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
    } else {
      return SizedBox.shrink();
    }
  }
}
