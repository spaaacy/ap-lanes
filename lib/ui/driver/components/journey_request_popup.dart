import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/model/firestore/journey.dart';

class JourneyRequestPopup extends StatelessWidget {
  const JourneyRequestPopup({
    super.key,
    required this.isSearching,
    required this.journey,
    required this.onNavigate,
    required this.onAccept,
  });

  final bool isSearching;
  final QueryDocumentSnapshot<Journey>? journey;
  final void Function(int direction) onNavigate;
  final void Function(QueryDocumentSnapshot<Journey>) onAccept;

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
                Material(
                  elevation: 2,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: journey == null
                        ? Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 24),
                                Text(
                                  'Looking for Requests',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FROM',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black45),
                              ),
                              Text(
                                journey!.data().startDescription,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'TO',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black45),
                              ),
                              Text(
                                journey!.data().endDescription,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 0,
                      child: FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.blue),
                        ),
                        onPressed: journey == null ? null : () => onNavigate(-1),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.green),
                        ),
                        onPressed: journey == null ? null : () => onAccept(journey!),
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
                        onPressed: journey == null ? null : () => onNavigate(1),
                        child: const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
