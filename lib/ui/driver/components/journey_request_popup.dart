import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/model/remote/journey.dart';
import '../../../data/repo/user_repo.dart';

class JourneyRequestPopup extends StatelessWidget {
  JourneyRequestPopup({
    super.key,
    required this.isSearching,
    required this.journey,
    required this.onNavigate,
    required this.onAccept,
    required this.routeDistance,
  });

  final bool isSearching;
  final QueryDocumentSnapshot<Journey>? journey;
  final void Function(int direction) onNavigate;
  final void Function(QueryDocumentSnapshot<Journey>) onAccept;
  final double routeDistance;
  final UserRepo _userRepo = UserRepo();

  @override
  Widget build(BuildContext context) {
    final matchmakingButtonTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return TweenAnimationBuilder(
      curve: Curves.bounceInOut,
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: isSearching ? 1 : 0, end: isSearching ? 0 : 1),
      builder: (_, topOffset, child) {
        return Positioned.fill(
          left: 12,
          right: 12,
          top: 12 - (200 * topOffset),
          child: Visibility(
            visible: topOffset != 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: journey == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Looking for requests...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PASSENGER',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            FutureBuilder(
                              future: _userRepo.getUser(journey!.data().userId),
                              builder: (context, snapshot) {
                                var passengerName = "Loading...";

                                if (snapshot.hasData) {
                                  passengerName = snapshot.data!.data().getFullName();
                                }

                                return Text(
                                  passengerName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'FROM',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              journey!.data().startDescription,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TO',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              journey!.data().endDescription,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DISTANCE',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              "${routeDistance.toStringAsFixed(2)} km",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                ...?(() {
                  if (journey != null) {
                    return [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            flex: 0,
                            child: FilledButton(
                              style: matchmakingButtonTheme?.copyWith(
                                backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                              ),
                              onPressed: () => onNavigate(-1),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              style: matchmakingButtonTheme?.copyWith(
                                backgroundColor: const MaterialStatePropertyAll(Colors.green),
                              ),
                              onPressed: () => onAccept(journey!),
                              child: Text(
                                'ACCEPT',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 0,
                            child: FilledButton(
                              style: matchmakingButtonTheme?.copyWith(
                                backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                              ),
                              onPressed: () => onNavigate(1),
                              child: const Icon(Icons.arrow_forward, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    ];
                  }
                }()),
              ],
            ),
          ),
        );
      },
    );
  }
}
