import 'package:cloud_firestore/cloud_firestore.dart';

class Metadata {
  final double kmRate;
  final double baseRate;

  Metadata({
    required this.kmRate,
    required this.baseRate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (kmRate != null) "kmRate": kmRate,
      if (baseRate != null) "baseRate": baseRate,
    };
  }

  factory Metadata.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Metadata(
      baseRate: double.parse(data?['baseRate']),
      kmRate: double.parse(data?['kmRate']),
    );
  }
}
