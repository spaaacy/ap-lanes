import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../util/location_helpers.dart';

class JourneyRequestPopup extends StatelessWidget {
  const JourneyRequestPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final MapViewState mapViewState = context.watch<MapViewState>();
    final state = Provider.of<DriverHomeState>(context);

    final matchmakingButtonTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return TweenAnimationBuilder(
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: state.isSearching ? 1 : 0, end: state.isSearching ? 0 : 1),
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
                  child: state.availableJourneySnapshot == null
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
                            Text(
                              state.availableJourneyPassenger?.data().getFullName() ?? 'Loading...',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'FROM',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              trimDescription(state.availableJourneySnapshot!.data().startDescription),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TO',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              trimDescription(state.availableJourneySnapshot!.data().endDescription),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DISTANCE',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                            ),
                            Text(
                              "${calculateRouteDistance(mapViewState.polylines.firstOrNull).toStringAsFixed(2)} km",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                ...?(() {
                  if (state.availableJourneySnapshot != null) {
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
                              onPressed: () => state.onRequestPopupNavigate(-1),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              style: matchmakingButtonTheme?.copyWith(
                                backgroundColor: const MaterialStatePropertyAll(Colors.green),
                              ),
                              onPressed: () => state.onJourneyAccept(),
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
                              onPressed: () => state.onRequestPopupNavigate(1),
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
