import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/model/firestore/driver.dart';
import '../../../data/model/firestore/journey.dart';
import '../../../data/model/firestore/user.dart';

class DriverHomeState extends ChangeNotifier {
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Driver>? _driver;
  bool _isSearching = false;
  GoogleMapController? _mapController;
  DocumentSnapshot<Journey>? _activeJourney;
  Set<Polyline>? _polylines;

  Set<Polyline>? get polylines => _polylines;

  set polylines(Set<Polyline>? value) {
    _polylines = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  QueryDocumentSnapshot<Driver>? get driver => _driver;

  set driver(QueryDocumentSnapshot<Driver>? value) {
    _driver = value;
    notifyListeners();
  }

  bool get isSearching => _isSearching;

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  GoogleMapController? get mapController => _mapController;

  set mapController(GoogleMapController? value) {
    _mapController = value;
    notifyListeners();
  }

  DocumentSnapshot<Journey>? get activeJourney => _activeJourney;

  set activeJourney(DocumentSnapshot<Journey>? value) {
    _activeJourney = value;
    notifyListeners();
  }
}
