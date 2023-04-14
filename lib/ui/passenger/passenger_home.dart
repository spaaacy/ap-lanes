import 'package:apu_rideshare/data/model/firestore/user.dart';
import 'package:apu_rideshare/ui/common/app_drawer.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:apu_rideshare/ui/passenger/components/search_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../data/repo/user_repo.dart';
import '../../util/greeting.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();
  late final firebase_auth.User? firebaseUser;
  final _userRepo = UserRepo();
  QueryDocumentSnapshot<User>? _user;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _userRepo.getUser(firebaseUser!.uid).then((userData) {
          setState(() {
            _user = userData;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Greeting.getGreeting(),
        ),
      ),
      drawer: AppDrawer(user: _user, isDriver: false),
      body: Stack(
        children: [
          const CustomMap(),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: SearchTextField(controller: _searchController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
