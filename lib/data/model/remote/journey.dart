import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../../util/location_helpers.dart';

class PaymentMode {
  static String cash = "CASH";
  static String card = "CARD";
  static String qr = "QR";
}

class Journey {
  final String userId;
  final LatLng startLatLng;
  final LatLng endLatLng;
  final String startDescription;
  final String endDescription;
  bool isCompleted;
  bool isPickedUp;
  bool isCancelled;
  String driverId;
  String distance;
  String price;
  String paymentMode;
  DateTime createdAt;

  Journey({
    required this.userId,
    required this.startLatLng,
    required this.endLatLng,
    required this.startDescription,
    required this.endDescription,
    required this.distance,
    required this.price,
    required this.paymentMode,
    this.isCompleted = false,
    this.isCancelled = false,
    this.isPickedUp = false,
    this.driverId = "",
    DateTime? createdOn,
  }) : createdAt = createdOn ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (startLatLng != null) "startLatLng": '${startLatLng.latitude}, ${startLatLng.longitude}',
      if (endLatLng != null) "endLatLng": '${endLatLng.latitude}, ${endLatLng.longitude}',
      if (startDescription != null) "startDescription": startDescription,
      if (endDescription != null) "endDescription": endDescription,
      if (isCompleted != null) "isCompleted": isCompleted,
      if (isCancelled != null) "isCancelled": isCancelled,
      if (isPickedUp != null) "isPickedUp": isPickedUp,
      if (driverId != null) "driverId": driverId,
      if (distance != null) "distance": distance,
      if (price != null) "price": price,
      if (paymentMode != null) "paymentMode": paymentMode,
      if (createdAt != null) "createdAt": createdAt.millisecondsSinceEpoch,
    };
  }

  factory Journey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Journey(
      userId: data?['userId'],
      startLatLng: getLatLngFromString(data?['startLatLng']),
      endLatLng: getLatLngFromString(data?['endLatLng']),
      startDescription: data?['startDescription'],
      endDescription: data?['endDescription'],
      isCompleted: data?['isCompleted'],
      isCancelled: data?['isCancelled'],
      isPickedUp: data?['isPickedUp'],
      driverId: data?['driverId'],
      distance: data?['distance'],
      price: data?['price'],
      paymentMode: data?['paymentMode'],
      createdOn: DateTime.fromMillisecondsSinceEpoch(data!['createdAt']),
    );
  }
}
