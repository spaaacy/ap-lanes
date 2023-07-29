import 'package:firebase_database/firebase_database.dart';

class MetadataRepo {

  final _metadataRef = FirebaseDatabase.instance.ref("metadata");

  Future<int?> getBaseRate() async {
    final snapshot = await _metadataRef.child("base_rate").get();
    if (snapshot.exists) {
      return int.parse('${snapshot.value}');
    } else {
      return null;
    }
  }

  Future<int?> getKmRate() async {
    final snapshot = await _metadataRef.child("km_rate").get();
    if (snapshot.exists) {
      return int.parse('${snapshot.value}');
    } else {
      return null;
    }
  }

}