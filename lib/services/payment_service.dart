import 'dart:convert';

import 'package:ap_lanes/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';


class PaymentService {

  dynamic paymentIntent;
  dynamic setupIntent;
  final client = Client();

  Future<bool> displayPaymentSheet(String distance, String customerId) async {
    try {
      // create ephemeral key for customer
      final ephemeralKey = await _createEphemeralKey(customerId);

      // create payment intent on the server
      paymentIntent = await _createPaymentIntent(distance, defaultCurrency, customerId);
      // setupIntent = await _createSetupIntent(customerId);

      // initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // setupIntentClientSecret: setupIntent,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          paymentIntentClientSecret: paymentIntent,
          merchantDisplayName: 'APLanes',
        ),
      );

      return await _displayPaymentSheet();
    } catch (e) {
      throw Exception(e);
    }
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
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: body
      );
      final result = json.decode(response.body);
      return result['id'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> _createPaymentIntent(String distance, String currency, String customerId) async {
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
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      final result = json.decode(response.body);
      return result['client_secret'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> _createSetupIntent(String customerId) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'customer': customerId,
      };

      //Make post request to Stripe
      var response = await client.post(
        Uri.parse(
            'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreateSetupIntent'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      final result = json.decode(response.body);
      return result['client_secret'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  _createEphemeralKey(String customerId) async {
    try {
      var response = await client.post(
        Uri.parse('https://asia-east2-apu-rideshare.cloudfunctions.net/StripeCreateEphemeralKey'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {'customer': customerId},
      );
      final result = json.decode(response.body);
      return result['secret'];
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> _displayPaymentSheet() async {
    var success = false;
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        paymentIntent = null;
        // setupIntent = null;
        success = true;
      }).onError((error, stackTrace) => throw Exception(error));
    } on StripeException catch (e) {
      if (kDebugMode) {
        print('Error is:---> $e');
      }
      success = false;
    } catch (e) {
      if (kDebugMode) {
        print('$e');
      }
      success = false;
    }
    return success;
  }

}