import 'package:flutter/material.dart';

import '../models/staff_user.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pakiti_app_bar.dart';
import 'current_trip.dart';
import 'load_parcels.dart';
import 'login.dart';
import 'profile.dart';
import 'start_trip.dart';

// The conductor's side of the app. It holds the trip that is open, if there is one.
// While that trip is loading, the loading screen takes the whole screen. Otherwise
// there are two tabs: the trip, and Profile.
class ConductorTabs extends StatefulWidget {
  const ConductorTabs({
    super.key,
    required this.user,
    this.service,
    this.camera = true,
  });

  final StaffUser user;

  // tests pass in a fake one
  final TripService? service;

  // false in tests, where there is no camera
  final bool camera;

  @override
  State<ConductorTabs> createState() => _ConductorTabsState();
}

class _ConductorTabsState extends State<ConductorTabs> {
  late final TripService _tripService = widget.service ?? TripService();

  int _tab = 0;
  Trip? _trip;
  bool _checking = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _checkTrip();
  }

  // a trip may already be open from before the app was closed
  Future<void> _checkTrip() async {
    try {
      final trip = await _tripService.fetchCurrent();

      if (!mounted) return;

      setState(() {
        _trip = trip;
        _checking = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _checking = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _checking = true;
      _error = null;
    });
    _checkTrip();
  }

  // each screen hands back the trip after a change, or null once it is over
  void _tripChanged(Trip? trip) {
    setState(() => _trip = trip);
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    if (trip != null && trip.status == TripStatus.loading) {
      return LoadParcelsScreen(
        trip: trip,
        onChanged: _tripChanged,
        service: _tripService,
        camera: widget.camera,
      );
    }

    return Scaffold(
      body: _tab == 0 ? _buildTrip(trip) : ProfileScreen(user: widget.user),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.navTint,
        onDestinationSelected: (tab) => setState(() => _tab = tab),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTrip(Trip? trip) {
    final error = _error;

    if (_checking || error != null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        appBar: const PakitiAppBar(),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: error == null ? const CircularProgressIndicator() : _buildError(error),
          ),
        ),
      );
    }

    if (trip == null) {
      return StartTripScreen(
        user: widget.user,
        onStarted: _tripChanged,
        service: _tripService,
      );
    }

    return CurrentTripScreen(
      trip: trip,
      onChanged: _tripChanged,
      service: _tripService,
    );
  }

  Widget _buildError(Object error) {
    final sessionEnded = error is ApiException && error.statusCode == 401;
    final message = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sessionEnded ? _goToLogin : _retry,
            child: Text(sessionEnded ? 'Log in again' : 'Try again'),
          ),
        ],
      ),
    );
  }
}