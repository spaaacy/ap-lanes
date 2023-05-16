import 'package:ap_lanes/data/model/remote/user.dart';
import 'package:ap_lanes/data/repo/feedback_repo.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:ap_lanes/ui/passenger/passenger_home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/model/remote/feedback.dart' as remote;

class AppDrawerState extends ChangeNotifier {
  final BuildContext _context;
  final FeedbackRepo feedbackRepo = FeedbackRepo();

  QueryDocumentSnapshot<User>? _user;

  QueryDocumentSnapshot<User>? get user => _user;

  set user(QueryDocumentSnapshot<User>? value) {
    _user = value;
    notifyListeners();
  }

  AppDrawerState(this._context) {
    _user = getUserInfo(_context);
  }

  bool isDriverMode() => _context.read()<UserWrapperState>().userMode == UserMode.driverMode;

  dynamic getUserInfo(BuildContext context) {
    dynamic info = Provider.of<DriverHomeState?>(context, listen: false);
    info ??= Provider.of<PassengerHomeState?>(context, listen: false);
    if (info is DriverHomeState || info is PassengerHomeState) {
      return info.user;
    } else {
      return null;
    }
  }

  void submitFeedback(String feedback) {
    feedbackRepo.createFeedback(
      remote.Feedback(
        feedback: feedback,
      ),
    );
  }
}
