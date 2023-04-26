import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/feedback.dart';

class FeedbackRepo {
  final _feedbackRef = FirebaseFirestore.instance
      .collection("feedback")
      .withConverter(fromFirestore: Feedback.fromFirestore, toFirestore: (Feedback feedback, _) => feedback.toFirestore());

  Future<void> createFeedback(Feedback feedback) async {
    _feedbackRef.add(feedback);
  }

}
