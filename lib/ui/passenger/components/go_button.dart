import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../passenger_home_state.dart';

class GoButton extends StatelessWidget {
  const GoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();
    final state = Provider.of<PassengerHomeState>(context);

    if (!state.hasDriver) {
      return ElevatedButton(
          onPressed: () {
            if (firebaseUser != null) {
              if (!state.isSearching) {
                state.isSearching = true;
                state.createJourney(context);
              } else {
                state.isSearching = false;
                state.deleteJourney();
              }
            }
          },
          style: ElevatedButtonTheme.of(context).style?.copyWith(
                shape: const MaterialStatePropertyAll(CircleBorder()),
                padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                elevation: const MaterialStatePropertyAll(6.0),
              ),
          child: !state.isSearching
              ? const Text("GO")
              : const Icon(
                  Icons.close,
                  semanticLabel: "Cancel Search",
                  size: 20,
                ));
    } else {
      return const SizedBox.shrink();
    }
  }
}
