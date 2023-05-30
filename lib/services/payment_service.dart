import 'dart:convert';

import 'package:ap_lanes/services/notification_service.dart';
import 'package:ap_lanes/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';

class PaymentService {
  Map<String, dynamic>? _paymentIntent;
  dynamic setupIntent;
  final client = Client();
  final notificationService = NotificationService();

  Future<String?> displayPaymentSheet(
      String distance, String customerId) async {
    try {
      // create ephemeral key for customer
      final ephemeralKey = await _createEphemeralKey(customerId);

      // create payment intent on the server
      _paymentIntent = await _createPaymentIntent(
          distance, malaysiaCurrencyCode, customerId);

      // initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey,
            paymentIntentClientSecret: _paymentIntent!['client_secret'],
            merchantDisplayName: 'APLanes',
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: malaysiaCountryCode,
              currencyCode: malaysiaCurrencyCode,
              testEnv: true, // TODO: Change for production
            )),
      );

      return await _displayPaymentSheet();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<String?> _displayPaymentSheet() async {
    String? paymentIntentId;
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        paymentIntentId = _paymentIntent!['id'];
        _paymentIntent = null;
      }).onError((error, stackTrace) => throw Exception(error));
    } on StripeException catch (e) {
      if (kDebugMode) {
        print('Error is:---> $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('$e');
      }
    }
    return paymentIntentId;
  }

  Future<String> createCustomer(String email, String name, String phone) async {
    try {
      Map<String, dynamic> body = {
        'email': email,
        'name': name,
        'phone': phone,
      };
      final response = await client.post(
          Uri.parse(
              'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreateCustomer'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body);
      final result = json.decode(response.body);

      if (result['error'] != null) {
        throw Exception(result['error']);
      }
      return result['id'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(
      String distance, String currency, String customerId) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'distance': distance,
        'currency': currency,
        'customer': customerId,
      };

      //Make post request to Stripe
      var response = await client.post(
        Uri.parse(
            'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreatePaymentIntent'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      final result = json.decode(response.body);

      if (result['error'] != null) {
        throw Exception(result['error']);
      }
      return result;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  _createEphemeralKey(String customerId) async {
    try {
      var response = await client.post(
        Uri.parse(
            'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreateEphemeralKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'customer': customerId},
      );
      final result = json.decode(response.body);

      if (result['error'] != null) {
        throw Exception(result['error']);
      }
      return result['secret'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> createRefund(String paymentIntent) async {
    try {
      client.post(
        Uri.parse(
            'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreateRefund'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'payment_intent': paymentIntent},
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
