import 'package:ap_lanes/data/repo/feedback_repo.dart';
import 'package:ap_lanes/ui/common/user_wrapper/user_wrapper_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/model/remote/feedback.dart' as remote;

class AppDrawerProvider extends ChangeNotifier {
  final BuildContext _context;
  final FeedbackRepo feedbackRepo = FeedbackRepo();

  AppDrawerProvider(this._context);

  // bool isDriverMode() => _context.read()<UserWrapperState>().userMode == UserMode.driverMode;

  void submitFeedback(String feedback) {
    feedbackRepo.createFeedback(
      remote.Feedback(
        feedback: feedback,
      ),
    );
  }
}
