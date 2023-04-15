import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/model/firestore/user.dart';
import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:apu_rideshare/ui/common/app_drawer.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:apu_rideshare/ui/passenger/components/passenger_go_button.dart';
import 'package:apu_rideshare/ui/passenger/components/search_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/firestore/passenger.dart';
import '../../data/repo/journey_repo.dart';
import '../../data/repo/user_repo.dart';
import '../../util/greeting.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final _searchController = TextEditingController();
  final _passengerRepo = PassengerRepo();
  final _userRepo = UserRepo();
  final _journeyRepo = JourneyRepo();

  late final firebase_auth.User? firebaseUser;
  QueryDocumentSnapshot<Passenger>? _passenger;
  QueryDocumentSnapshot<User>? _user;
  QueryDocumentSnapshot<Journey>? _journey;

  late final bool _isSearching;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _passengerRepo.getPassenger(firebaseUser!.uid).then((passenger) {
          setState(() {
            _passenger = passenger;
            _isSearching = _passenger?.data().isSearching == true;
          });
        });

        _userRepo.getUser(firebaseUser!.uid).then((userData) {
          setState(() {
            _user = userData;
          });
        });

        _journeyRepo.listenForJourney(firebaseUser!.uid, (journey) {
          setState(() {
            _journey = journey;
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
      body:
      _passenger == null ?
          const Align(child: CircularProgressIndicator()) :
      Stack(
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
          Positioned.fill(
            bottom: 100.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: PassengerGoButton(passenger: _passenger!, isSearching: _isSearching, journey: _journey, firebaseUser: firebaseUser),
            ),
          )
        ],
      ),
    );
  }
}
