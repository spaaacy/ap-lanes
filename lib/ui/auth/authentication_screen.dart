import 'package:apu_rideshare/services/authentication_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({
    Key? key,
    required this.passwordController,
    required this.emailController,
  }) : super(key: key);

  final TextEditingController passwordController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In")),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email"
              )
            ),

            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: "Password"
              )
            ),

            ElevatedButton(
              onPressed: () {
                context.read<AuthenticationService>().signIn(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim()
                );
              },
              child: Text("Sign In")
            ),

            ElevatedButton(
              onPressed: () {
                context.read<AuthenticationService>().signUp(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim()
                );
              },
              child: Text("Sign Up")
            )

          ],
        ),

    );
  }
}
