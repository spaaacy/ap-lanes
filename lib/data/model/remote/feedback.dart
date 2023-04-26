import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String feedback;
  DateTime timestamp;

  Feedback({
    required this.feedback,
    DateTime? retrievedTimestamp,
  }): timestamp = retrievedTimestamp ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      if (feedback != null) "feedback": feedback,
      if (timestamp != null) "timestamp": timestamp.microsecondsSinceEpoch,
    };
  }

  factory Feedback.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Feedback(
      feedback: data?['feedback'],
      retrievedTimestamp: DateTime.fromMillisecondsSinceEpoch(data?['timestamp']),
    );
  }
}
