import 'package:apu_rideshare/services/place_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/model/firestore/journey.dart';

class JourneyRequestPopup extends StatelessWidget {
  const JourneyRequestPopup({
    super.key,
    required this.isMatchmaking,
    required this.journey,
    required this.onReject,
    required this.onAccept,
  });

  final bool isMatchmaking;
  final QueryDocumentSnapshot<Journey>? journey;
  final void Function() onReject;
  final void Function(QueryDocumentSnapshot<Journey>) onAccept;

  LatLng getLatLngFromString(String latLngString) {
    var latLngValues = latLngString.split(',').map((e) => double.parse(e.trim())).toList();
    return LatLng(latLngValues[0], latLngValues[1]);
  }

  @override
  Widget build(BuildContext context) {
    final PlaceService placeService = PlaceService();
    String lang = Localizations.localeOf(context).languageCode;

    final matchmakingButtonTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return TweenAnimationBuilder(
      curve: Curves.bounceInOut,
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: isMatchmaking ? 1 : 0, end: isMatchmaking ? 0 : 1),
      builder: (_, topOffset, w) {
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'FROM',
                                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey.shade500),
                              ),
                              FutureBuilder(
                                future: isMatchmaking
                                    ? placeService.fetchAddressFromLatLng(
                                        lang,
                                        getLatLngFromString(journey!.data().startPoint),
                                      )
                                    : Future.value(null),
                                builder: (context, addressSnapshot) {
                                  return Text(
                                    addressSnapshot.data ?? "Loading...",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  );
                                },
                              ),
                              const Icon(Icons.arrow_downward),
                              Text(
                                'TO',
                                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey.shade500),
                              ),
                              FutureBuilder(
                                future: isMatchmaking
                                    ? placeService.fetchAddressFromLatLng(
                                        lang,
                                        getLatLngFromString(journey!.data().destination),
                                      )
                                    : Future.value(null),
                                builder: (context, addressSnapshot) {
                                  return Text(
                                    textAlign: TextAlign.center,
                                    addressSnapshot.data ?? "Loading...",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  );
                                },
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
                      child: FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.red),
                        ),
                        onPressed: journey == null ? null : onReject,
                        child: Text(
                          'REJECT',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
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
