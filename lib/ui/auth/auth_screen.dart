import 'package:apu_rideshare/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(hintText: "Email")),
            TextField(
                obscureText: true,
                controller: passwordController,
                decoration: const InputDecoration(hintText: "Password")),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        String email = emailController.text.trim();
                        String password = passwordController.text.trim();

                        context.read<AuthService>().signUp(email: email, password: password);
                      },
                      child: const Text("Sign Up")),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        String email = emailController.text.trim();
                        String password = passwordController.text.trim();

                        context.read<AuthService>().signIn(email: email, password: password);
                      },
                      child: const Text("Sign In")),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
