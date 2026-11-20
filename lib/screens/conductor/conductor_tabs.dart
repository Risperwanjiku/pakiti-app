import 'package:flutter/material.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/screens/account/profile_screen.dart';
import 'package:pakiti_app/screens/conductor/current_trip_screen.dart';
import 'package:pakiti_app/screens/conductor/load_parcels_screen.dart';
import 'package:pakiti_app/screens/conductor/start_trip_screen.dart';
import 'package:pakiti_app/services/trip_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/pakiti_app_bar.dart';

// The conductor's side of the app. It holds the trip that is open, if there is one.
// While that trip is loading, the loading screen takes the whole screen. Otherwise
// there are two tabs: the trip, and Profile.
class ConductorTabs extends StatefulWidget {
  const ConductorTabs({super.key, required this.user, this.service, this.camera = true});

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

  int _tabIndex = 0;
  Trip? _trip;
  bool _checkingTrip = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _checkTrip();
  }

  // a trip may already be open from before the app was closed
  Future<void> _checkTrip() async {
    try {
      final trip = await _tripService.fetchCurrentTrip();

      if (!mounted) return;

      setState(() {
        _trip = trip;
        _checkingTrip = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _checkingTrip = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _checkingTrip = true;
      _error = null;
    });
    _checkTrip();
  }

  // each screen hands back the trip after a change, or null once it is over
  void _updateTrip(Trip? trip) {
    setState(() => _trip = trip);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    if (trip != null && trip.status == TripStatus.loading) {
      return LoadParcelsScreen(
        trip: trip,
        onChanged: _updateTrip,
        service: _tripService,
        camera: widget.camera,
      );
    }

    return Scaffold(
      body: _tabIndex == 0 ? _buildTripTab(trip) : ProfileScreen(user: widget.user),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppColors.navTint,
        onDestinationSelected: (tab) => setState(() => _tabIndex = tab),
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

  Widget _buildTripTab(Trip? trip) {
    final error = _error;

    if (_checkingTrip || error != null) {
      return Scaffold(
        backgroundColor: AppColors.page,
        appBar: const PakitiAppBar(),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: error == null
                ? const CircularProgressIndicator()
                : LoadErrorCard(error: error, onRetry: _retry, onLogIn: () => goToLogin(context)),
          ),
        ),
      );
    }

    if (trip == null) {
      return StartTripScreen(user: widget.user, onStarted: _updateTrip, service: _tripService);
    }

    return CurrentTripScreen(trip: trip, onChanged: _updateTrip, service: _tripService);
  }
}
