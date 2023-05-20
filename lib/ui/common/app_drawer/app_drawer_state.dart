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
  final FeedbackRepo _feedbackRepo = FeedbackRepo();
  late final UserWrapperState _userWrapperState;

  AppDrawerState(this._context) {
    _userWrapperState = Provider.of<UserWrapperState>(_context, listen: false);
  }

  bool get isDriverMode => _userWrapperState.userMode == UserMode.driverMode;

  QueryDocumentSnapshot<User>? get user {
    if (isDriverMode) {
      return Provider.of<DriverHomeState>(_context).user;
    } else {
      return Provider.of<PassengerHomeState>(_context).user;
    }
  }

  void submitFeedback(String feedback) {
    _feedbackRepo.createFeedback(
      remote.Feedback(
        feedback: feedback,
      ),
    );
  }
}
