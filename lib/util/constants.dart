import 'package:latlong2/latlong.dart';

// Maps API
const String androidApiKey = "AIzaSyCjPRC6yejeI9XzZlCvvcr6qWvaTkqr408";

// Payments
// const String malaysiaCurrencyCode = 'MYR';
// const String malaysiaCountryCode = 'MY';
const String malaysiaCurrencyCode = 'USD';
const String malaysiaCountryCode = 'US';

// User Modes
const String passengerMode = "PASSENGER_MODE";
const String driverMode = "DRIVER_MODE";

// Firebase Authentication
const String signedIn = "SIGNED_IN";
const String signedUp = "SIGNED_UP";
const String unverified = "UNVERIFIED";

// Notifications
const int passengerNotificationId = 0;
const String passengerChannelId = "passenger";
const String passengerChannelName = "Passenger Notifications";
const int driverNotificationId = 1;
const String driverChannelId = "driver";
const String driverChannelName = "Driver Notifications";
const int locationNotificationId = 2;
const String locationChannelId = "location";
const String locationChannelName = "Location Notifications";

// Locations
final LatLng apuLatLng = LatLng(3.0554057, 101.7005614);
const String apuDescription = "Asia Pacific University of Technology & Innovation (APU), Jalan Teknologi 5, Technology Park Malaysia, Kuala Lumpur, Federal Territory of Kuala Lumpur, Malaysia";

// Pricing
const double baseCharge = 0.00;
const double kmCharge = 0.85;