import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchWaze(double lat, double lng) async {
  var url = 'waze://?ll=${lat.toString()},${lng.toString()}';
  var fallbackUrl = 'https://waze.com/ul?ll=${lat.toString()},${lng.toString()}&navigate=yes';
  try {
    bool launched = false;
    if (!kIsWeb) {
      launched = await launchUrl(Uri.parse(url));
    }
    if (!launched) {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  } catch (e) {
    await launchUrl(Uri.parse(fallbackUrl));
  }
}

Future<void> launchGoogleMaps(double lat, double lng) async {
  var url = 'google.navigation:q=${lat.toString()},${lng.toString()}';
  var fallbackUrl =
      'https://www.google.com/maps/search/?api=1&query=${lat.toString()},${lng.toString()}';
  try {
    bool launched = false;
    if (!kIsWeb) {
      launched = await launchUrl(Uri.parse(url));
    }
    if (!launched) {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  } catch (e) {
    await launchUrl(Uri.parse(fallbackUrl));
  }
}