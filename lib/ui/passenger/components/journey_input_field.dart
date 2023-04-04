import 'package:flutter/material.dart';

class JourneyInputField extends StatelessWidget{
  final TextEditingController controller;
  const JourneyInputField({
    super.key,
    required this.controller
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Where do you want to go?",
            filled: true,
            fillColor: Colors.white)
    );
  }

}