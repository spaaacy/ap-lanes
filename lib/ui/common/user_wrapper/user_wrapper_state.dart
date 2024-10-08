import 'package:flutter/material.dart';

enum UserMode {passengerMode, driverMode}

class UserWrapperState extends ChangeNotifier {
  UserMode _userMode = UserMode.passengerMode;

  UserMode get userMode => _userMode;

  set userMode(UserMode value) {
    _userMode = value;
    notifyListeners();
  }
}

