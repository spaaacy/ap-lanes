import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../util/constants.dart' as constants;
import '../../util/ui_helpers.dart' as ui_helper;

class SignUpScreen extends StatelessWidget {
  SignUpScreen({Key? key}) : super(key: key);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();
  final _emailRegExp = RegExp(
    r"(tp\d{6}@mail\.apu\.edu\.my|[\w\d.!#$%&'*+/=?^_`{|}~-]+@apu\.edu\.my)",
    caseSensitive: false,
  );

  final _phoneRegExp = RegExp(r"\+60\d{8,10}");

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
                  if (value == null || value.isEmpty) { // || !_emailRegExp.hasMatch(value)) {
                    return 'Your email must belong to APU';
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
                decoration: const InputDecoration(hintText: "Password"),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Your phone number cannot be empty';
                  }

                  if (!_phoneRegExp.hasMatch(value)) {
                    return "Phone number format: +60XXXXXXXXX";
                  }

                  return null;
                },
                controller: phoneNumberController,
                decoration: const InputDecoration(hintText: "Phone Number"),
              ),
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
                          String phoneNumber = phoneNumberController.text.trim();

                          String result = await context.read<AuthService>().signUp(
                                email: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName,
                                phoneNumber: phoneNumber,
                              );

                          if (context.mounted) {
                            if (result == constants.signedIn) {
                              Navigator.of(context).pop(); // pop loader
                              Navigator.of(context).pop(); // pop signup page
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Verify your email to continue")),
                              );
                            } else {
                              Navigator.of(context).pop(); // pop loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)),
                              );ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)),
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
