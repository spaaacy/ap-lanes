import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/remote/metadata.dart' as model;

class MetadataRepo {
  final _metadataRef = FirebaseFirestore.instance
      .collection("metadata")
      .withConverter(fromFirestore: model.Metadata.fromFirestore, toFirestore: (model.Metadata metadata, _) => metadata.toFirestore());

  Future<model.Metadata?> getPricing() async {
    final snapshot = await _metadataRef.doc('pricing').get();
    if (snapshot.exists) {
      return snapshot.data();
    }
    return null;
  }

}
