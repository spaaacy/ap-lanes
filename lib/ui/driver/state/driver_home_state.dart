import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/model/firestore/driver.dart';
import '../../../data/model/firestore/user.dart';

class DriverHomeState extends ChangeNotifier {
  QueryDocumentSnapshot<User>? user;
  QueryDocumentSnapshot<Driver>? driver;
  bool isMatchmaking = false;
  GoogleMapController? mapController;
  DocumentSnapshot<Journey>? activeJourney;
}
