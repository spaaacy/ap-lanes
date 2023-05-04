import 'package:ap_lanes/ui/common/map_view/map_view_state.dart';
import 'package:ap_lanes/ui/driver/components/journey_request_popup_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:ap_lanes/util/map_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JourneyRequestPopup extends StatelessWidget {
  const JourneyRequestPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<DriverHomeState>(context);
    if (state.driverState != DriverState.searching) return const SizedBox.shrink();
    final requestState = Provider.of<JourneyRequestPopupState>(context);

    final MapViewState mapViewState = context.watch<MapViewState>();

    final isBusy = requestState.availableJourney == null || requestState.isLoadingJourneyRequests;

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
            child: isBusy
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading...',
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
                        requestState.availableJourneyPassenger?.data().getFullName() ?? 'Loading...',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FROM',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      Text(
                        trimDescription(requestState.availableJourney!.data().startDescription),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TO',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black45),
                      ),
                      Text(
                        trimDescription(requestState.availableJourney!.data().endDescription),
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
          ...(() {
            return [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 0,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: isBusy
                          ? null
                          : () => requestState.onRequestPopupNavigate(RequestNavigationDirection.backward),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: isBusy ? null : () => requestState.onJourneyAccept(),
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
                      style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed:
                          isBusy ? null : () => requestState.onRequestPopupNavigate(RequestNavigationDirection.forward),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ],
              )
            ];
          }()),
        ],
      ),
    );
  }
}
