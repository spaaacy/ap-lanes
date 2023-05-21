import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<bool> initPaymentSheet(BuildContext context) async {
  try {
    // 1. create payment intent on the server
    final data = {}; // await _createTestPaymentSheet();

    // 2. initialize the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        // Enable custom flow
        customFlow: true,
        // Main params
        merchantDisplayName: 'Flutter Stripe Store Demo',
        paymentIntentClientSecret: data['paymentIntent'],
        // Customer keys
        customerEphemeralKeySecret: data['ephemeralKey'],
        customerId: data['customer'],
        // Extra options
        style: ThemeMode.dark,
      ),
    );
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    rethrow;
  }
}