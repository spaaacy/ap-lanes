import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../util/location_helpers.dart';
import '../../../util/url_helpers.dart';
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
            opacity: (state.inJourney) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(() {
                          if (state.driverName != null &&
                              state.driverLicensePlate != null &&
                              state.driverPhone != null) {
                            return [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Your Driver",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                                      Text(state.driverName!, style: Theme.of(context).textTheme.titleSmall),
                                      const SizedBox(height: 8.0),
                                      Text("License Plate",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                                      Text(state.driverLicensePlate!, style: Theme.of(context).textTheme.titleSmall),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (state.driverPhone != null)
                                    Row(
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              launchWhatsApp(state.driverPhone!);
                                            },
                                            icon: SvgPicture.asset(
                                              'assets/icons/whatsapp.svg',
                                              height: 30,
                                              width: 30,
                                            )),
                                        IconButton(
                                            onPressed: () {
                                              launchUrl(Uri.parse("tel://${state.driverPhone!.trim()}"));
                                            },
                                            icon: const Icon(Icons.phone)),
                                      ],
                                    ),
                                ],
                              )
                            ];
                          } else {
                            return [
                              Text(
                                "Finding an driver...",
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              )
                            ];
                          }
                        }()),
                        const SizedBox(height: 8.0),
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
                              Text("PRICE", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text("RM ${state.journey!.data().price}", style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 8.0),
                              Text("PAYMENT MODE", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                              Text(state.journey!.data().paymentMode.toUpperCase(), style: Theme.of(context).textTheme.titleSmall),
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
                          ...?(() {
                            if (!state.isPickedUp) {
                              return [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                              ];
                            }
                          }()),
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
