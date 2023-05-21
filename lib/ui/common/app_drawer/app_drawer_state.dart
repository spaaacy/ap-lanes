import 'package:ap_lanes/data/repo/feedback_repo.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/model/remote/feedback.dart' as remote;

class AppDrawerState extends ChangeNotifier {
  final BuildContext _context;
  final FeedbackRepo feedbackRepo = FeedbackRepo();

  AppDrawerState(this._context);

  // bool isDriverMode() => _context.read()<UserWrapperState>().userMode == UserMode.driverMode;

  void submitFeedback(String feedback) {
    feedbackRepo.create(
      remote.Feedback(
        feedback: feedback,
      ),
    );
  }
}
