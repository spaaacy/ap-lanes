import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:ap_lanes/util/location_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DriverGoButton extends StatelessWidget {
  const DriverGoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<DriverHomeState>(context);

    if (state.driverState == DriverState.ongoing) return const SizedBox.shrink();

    return Positioned.fill(
      bottom: 100.0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ElevatedButton(
          onPressed: () async {
            final locationPermissionsGranted = await handleAdditionalLocationPermission(context);
            if (locationPermissionsGranted) {
              state.driverState == DriverState.searching ? state.stopSearching : state.startSearching;
            }
          },
          style: ElevatedButtonTheme.of(context).style?.copyWith(
                shape: const MaterialStatePropertyAll(CircleBorder()),
                padding: const MaterialStatePropertyAll(EdgeInsets.all(24.0)),
                elevation: const MaterialStatePropertyAll(6.0),
              ),
          child: state.driverState == DriverState.searching
              ? const Icon(
                  Icons.close,
                  size: 20,
                )
              : const Text("GO"),
        ),
      ),
    );
  }
}
