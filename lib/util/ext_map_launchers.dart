import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchWaze(LatLng latLng) async {
  var url = 'waze://?ll=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  var fallbackUrl = 'https://waze.com/ul?ll=${latLng.latitude.toString()},${latLng.longitude.toString()}&navigate=yes';
  try {
    bool launched = false;
    if (!kIsWeb) {
      launched = await launchUrl(Uri.parse(url));
    }
    if (!launched) {
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
  }
}

Future<void> launchGoogleMaps(LatLng latLng) async {
  var url = 'google.navigation:q=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  var fallbackUrl =
      'https://www.google.com/maps/search/?api=1&query=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  try {
    bool launched = false;
    if (!kIsWeb) {
      launched = await launchUrl(Uri.parse(url));
    }
    if (!launched) {
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
  }
}