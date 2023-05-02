import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/driver/new_driver_home_state.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JourneyRequestPopup extends StatelessWidget {
  const JourneyRequestPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<NewDriverHomeState>(context);
    if (!state.isSearching) return const SizedBox.shrink();

    final MapViewState mapViewState = context.watch<MapViewState>();

    final matchmakingButtonTheme = FilledButtonTheme.of(context).style?.copyWith(
          elevation: const MaterialStatePropertyAll(2),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        );

    return Positioned.fill(
      left: 12,
      right: 12,
      top: 12,
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
            child: state.availableJourney == null
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
                        trimDescription(state.availableJourney!.data().startDescription),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TO',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      Text(
                        trimDescription(state.availableJourney!.data().endDescription),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DISTANCE',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      Text(
                        "${MapHelper.calculateRouteDistance(mapViewState.polylines.firstOrNull).toStringAsFixed(2)} km",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          ...?(() {
            if (state.availableJourney != null) {
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
                        onPressed: () => state.onRequestPopupNavigate(RequestNavigationDirection.backward),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: matchmakingButtonTheme?.copyWith(
                          backgroundColor: const MaterialStatePropertyAll(Colors.green),
                        ),
                        // todo: onPressed: () => state.onJourneyAccept(),
                        onPressed: () => {},
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
                        onPressed: () => state.onRequestPopupNavigate(RequestNavigationDirection.forward),
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
    );
  }
}
