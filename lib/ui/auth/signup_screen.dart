import 'package:apu_rideshare/services/auth_service.dart';
import 'package:apu_rideshare/util/constants.dart' as constants;
import 'package:apu_rideshare/util/ui_helper.dart' as ui_helper;
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({Key? key}) : super(key: key);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _signUpFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                controller: firstNameController,
                decoration: const InputDecoration(hintText: "First Name"),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
                controller: lastNameController,
                decoration: const InputDecoration(hintText: "Last Name"),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty || !EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                controller: emailController,
                decoration: const InputDecoration(hintText: "Email"),
              ),
              TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length <= 6) {
                      return 'Your password must be longer than 6 characters';
                    }

                    return null;
                  },
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(hintText: "Password")),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_signUpFormKey.currentState!.validate()) {
                          ui_helper.showLoaderDialog(context, 'Loading...');
                          String email = emailController.text.trim();
                          String password = passwordController.text.trim();
                          String firstName = firstNameController.text.trim();
                          String lastName = lastNameController.text.trim();

                          String result = await context.read<AuthService>().signUp(
                                email: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName,
                              );

                          if (context.mounted) {
                            if (result == constants.SIGNED_IN) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Something went wrong when signing up.')),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("Sign Up"),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
