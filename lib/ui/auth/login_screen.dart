import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../util/constants.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firebaseUser = context.read<firebase_auth.User?>();

    if (firebaseUser?.email != null) {
      emailController.text = firebaseUser!.email!;
    }

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
                      String result = await authService.signIn(email: email, password: password);
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
              ),
              if (context.watch<firebase_auth.User?>() != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                      onPressed: () {
                        authService.sendEmailVerification();
                      },
                      child: const Text("Send verification email")),
                )
            ],
          ),
        ),
      ),
    );
  }
}
