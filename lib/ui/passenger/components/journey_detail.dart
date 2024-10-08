import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../util/location_helpers.dart';
import '../passenger_home_state.dart';

class JourneyDetail extends StatelessWidget {
  const JourneyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PassengerHomeState>(context);

    if (!state.isSearching && !state.hasDriver) return const SizedBox.shrink();

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: (state.journey != null) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  elevation: 6.0,
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...?(() {
                          if (!state.hasDriver) {
                            return [
                              Text(
                                "Finding a driver...",
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8.0)
                            ];
                          }
                        }()),
                        ...?(() {
                          if (state.journey != null) {
                            return [
                              Text("FROM",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(trimDescription(state.journey!.data().startDescription),
                                  style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("TO", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(trimDescription(state.journey!.data().endDescription),
                                  style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("PRICE",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text("RM ${state.journey!.data().price}", style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("PAYMENT MODE",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(state.journey!.data().paymentMode.toUpperCase(),
                                  style: Theme.of(context).textTheme.titleSmall),
                            ];
                          }
                        }())
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                ...?(() {
                  if (state.hasDriver) {
                    return [
                      Row(
                        children: [
                          if (!state.isPickedUp)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 4.0),
                              onPressed: () {
                                showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Cancel journey"),
                                        content: const Text("Are you sure you would like to cancel your journey?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, "No");
                                              },
                                              child: const Text("No")),
                                          TextButton(
                                              onPressed: () async {
                                                try {
                                                  await state.cancelJourneyAsPassenger();
                                                } catch (exception) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                      content: Text(
                                                          "Sorry, you cannot cancel the journey after being picked up.")));
                                                } finally {
                                                  Navigator.pop(context, "Yes");
                                                }
                                              },
                                              child: const Text("Yes")),
                                        ],
                                      );
                                    });
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                                child: Text("Cancel"),
                              ),
                            )
                        ],
                      )
                    ];
                  }
                }())
              ],
            ),
          ),
        ),
      ),
    );
  }
}
