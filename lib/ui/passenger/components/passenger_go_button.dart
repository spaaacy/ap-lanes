import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import '../passenger_home_state.dart';

class PassengerGoButton extends StatelessWidget {
  const PassengerGoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();
    final state = Provider.of<PassengerHomeState>(context);

    if ((state.routeDistance == null && !state.isSearching) || state.inPayment) return const SizedBox.shrink();

      return ElevatedButton(
          onPressed: () {
            if (firebaseUser != null) {
              if (!state.isSearching) {
                state.createJourney(context);
              } else {
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
    }
}
