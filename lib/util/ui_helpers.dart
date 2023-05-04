import 'package:flutter/material.dart';

showLoaderDialog(BuildContext context, String loadingText) {
  Dialog alert = Dialog(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(loadingText, style: const TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

String getGreeting(String? lastName) {
  var hour = DateTime.now().hour;
  final String greeting;

  if (hour <= 12) {
    greeting = 'Good Morning';
  } else if ((hour > 12) && (hour <= 16)) {
    greeting = 'Good Afternoon';
  } else if ((hour > 16) && (hour < 24)) {
    greeting = 'Good Evening';
  } else {
    greeting = 'Good Night';
  }

  if (lastName == null) {
    return greeting;
  } else {
    return "$greeting, $lastName";
  }
}
