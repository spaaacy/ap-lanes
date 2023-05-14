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

    return Positioned.fill(
      bottom: 24.0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Align(
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                  decoration:
                  const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(25))),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Your Driver", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),),
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
                  icon: const Icon(Icons.phone)),
            ],
          ),
          Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.driverName!, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8.0),
                          Text(state.driverLicensePlate!, style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.vehicleManufacturer!, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8.0),
                          Text(state.vehicleModel!, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8.0),
                          Text(state.vehicleColor!, style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                    ],

                  )),
          ),
        ],
      ),
    ),
        ));
  }
}
