import 'package:ap_lanes/ui/passenger/passenger_home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../util/url_helpers.dart';

class DriverDetail extends StatelessWidget {
  const DriverDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PassengerHomeState>();

    if (!state.hasDriver) return const SizedBox.shrink();

    return Positioned.fill(
        bottom: 24.0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: AnimatedOpacity(
              opacity: (state.hasDriver) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                          decoration: const BoxDecoration(
                              color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(25))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              state.driverName!.toUpperCase(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                            ),
                          )),
                      const SizedBox(width: 8.0),
                      Container(
                          decoration: const BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(25))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              state.driverLicensePlate!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                          )),
                      const Spacer(),
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
                          icon: const Icon(Icons.phone, color: Colors.black,)),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    decoration:
                        const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("VEHICLE DETAILS", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400, color: Colors.black54)),
                            const Spacer(),
                            Text("${state.vehicleColor}, ${state.vehicleManufacturer!} ${state.vehicleModel}", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
