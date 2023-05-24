import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';


class PaymentService {

  dynamic paymentIntent;
  final client = Client();

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

  Future<bool> retrieveStripePayment(String distance, String customerId) async {
    try {
      // create ephemeral key for customer
      final ephemeralKey = await _createEphemeralKey(customerId);

      // create payment intent on the server
      paymentIntent = await _createPaymentIntent(distance, 'MYR', customerId);

      // initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customerEphemeralKeySecret: ephemeralKey,
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'APLanes',
          style: ThemeMode.dark,
        ),
      );

      return await _displayPaymentSheet();
    } catch (e) {
      throw Exception(e);
    }
  }

  _createPaymentIntent(String distance, String currency, String customerId) async {
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
            'https://asia-east2-apu-rideshare.cloudfunctions.net/StripeGetPaymentIntent'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  _createEphemeralKey(String customerId) async {
    try {
      var response = await client.post(
        Uri.parse('https://asia-east2-apu-rideshare.cloudfunctions.net/StripeGetEphemeralKey'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {'customerId': customerId},
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