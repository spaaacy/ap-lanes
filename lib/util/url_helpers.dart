import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchWaze(LatLng latLng) async {
  var url = 'waze://?ll=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  var fallbackUrl = 'https://waze.com/ul?ll=${latLng.latitude.toString()},${latLng.longitude.toString()}&navigate=yes';
  launchDeepLink(url, fallbackUrl: fallbackUrl);
}

Future<void> launchGoogleMaps(LatLng latLng) async {
  var url = 'google.navigation:q=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  var fallbackUrl =
      'https://www.google.com/maps/search/?api=1&query=${latLng.latitude.toString()},${latLng.longitude.toString()}';
  launchDeepLink(url, fallbackUrl: fallbackUrl);
}

Future<void> launchWhatApp(String phone) async {
  var url = Uri.parse('whatsapp://send?phone=$phone');
  var fallbackUrl = Uri.parse('https://wa.me/$phone');
  await canLaunchUrl(url)? launchUrl(url) : launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
}

Future<void> launchDeepLink(String url, {required String fallbackUrl}) async {
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
