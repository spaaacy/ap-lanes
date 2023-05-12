import 'package:ap_lanes/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../util/constants.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Form(
        key: _signInFormKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(hintText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }

                  return null;
                },
              ),
              TextFormField(
                obscureText: true,
                controller: passwordController,
                decoration: const InputDecoration(hintText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();

                      if (_signInFormKey.currentState!.validate()) {
                        String result = await context
                            .read<AuthService>()
                            .signIn(email: email, password: password);
                        if (context.mounted) {
                          if (result == signedIn) {
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text("Login"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
