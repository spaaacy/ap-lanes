import 'dart:async';

import 'package:apu_rideshare/data/model/firestore/journey.dart';
import 'package:apu_rideshare/data/model/firestore/user.dart';
import 'package:apu_rideshare/data/repo/passenger_repo.dart';
import 'package:apu_rideshare/ui/common/app_drawer.dart';
import 'package:apu_rideshare/ui/common/custom_map.dart';
import 'package:apu_rideshare/ui/passenger/components/passenger_go_button.dart';
import 'package:apu_rideshare/ui/passenger/components/search_bar.dart';
import 'package:apu_rideshare/util/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
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
  LatLng? _userLocation;

  late bool _isSearching;
  bool _toApu = false;

  late StreamSubscription<QuerySnapshot<Journey>> _journeyStream;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      firebaseUser = Provider.of<firebase_auth.User?>(context, listen: false);
      if (firebaseUser != null) {
        _passengerRepo.getPassenger(firebaseUser!.uid).then((passenger) {
          _passenger = passenger;
          _isSearching = _passenger?.data().isSearching == true;
        });

        _userRepo.getUser(firebaseUser!.uid).then((userData) {
          setState(() {
            _user = userData;
          });
        });

        _journeyStream = _journeyRepo.listenForJourney(firebaseUser!.uid, (journey) {
          _journey = journey;
        });
      }
    });
  }

  @override
  void dispose() async {
    await _journeyStream.cancel();
    super.dispose();
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
      body: _passenger == null
          ? const Align(child: CircularProgressIndicator())
          : Stack(
              children: [
                const CustomMap(),
                if (!_isSearching)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SearchBar(
                          toApu: _toApu,
                          updateToApu: (toApu) {
                            setState(() {
                              _toApu = toApu;
                            });
                          },
                          controller: _searchController,
                          onSearch: (latLng) {
                            setState(() {
                              _userLocation = latLng;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                if (_userLocation != null || _isSearching)
                  Positioned.fill(
                    bottom: 100.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: PassengerGoButton(
                        isSearching: _isSearching,
                        updateIsSearching: (isSearching) {
                          _passengerRepo.updateIsSearching(_passenger!, isSearching);
                          setState(() {
                            _isSearching = isSearching;
                          });
                        },
                        createJourney: () {
                          final userLocation = "${_userLocation!.latitude}, ${_userLocation!.longitude}";
                          _journeyRepo.createJourney(Journey(
                            userId: firebaseUser!.uid,
                            startPoint: _toApu ? userLocation : apuLatLng, // APU
                            destination: _toApu ? apuLatLng : userLocation,
                          ));
                        },
                        deleteJourney: () {
                          _journeyRepo.deleteJourney(_journey);
                        },
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
