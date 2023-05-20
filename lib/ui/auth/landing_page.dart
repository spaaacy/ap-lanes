import 'package:ap_lanes/ui/auth/signup_screen.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to",
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8.0),
              SizedBox(height: 50, child: Image.asset("assets/icons/logo.png", width: 100))
            ],
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SignUpScreen()
                        )
                      );
                    },
                    child: const Text("Sign Up")),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen()
                        )
                      );
                    },
                    child: const Text("Login")),
              ),
            ],
          )
        ],
      ),
    ));
  }
}
