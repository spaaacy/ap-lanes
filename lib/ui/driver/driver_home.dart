import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DriverHome extends StatefulWidget {

  DriverHome();

  @override
  State<DriverHome> createState() => _DriverHomeState();

}

class _DriverHomeState extends State<DriverHome> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome Driver")
      ),
      body: Center(child: Text("Driver Home"))
    );
  }
}