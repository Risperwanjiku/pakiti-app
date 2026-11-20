import 'package:flutter/material.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/services/trip_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/greeting.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';
import 'package:pakiti_app/widgets/common/load_error_card.dart';
import 'package:pakiti_app/widgets/common/pakiti_app_bar.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/trip/route_sheet.dart';
import 'package:pakiti_app/widgets/trip/trip_choice_row.dart';
import 'package:pakiti_app/widgets/trip/vehicle_sheet.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({
    super.key,
    required this.user,
    required this.onStarted,
    this.service,
  });

  final StaffUser user;

  // hands the new trip back, so the loading screen can open
  final ValueChanged<Trip> onStarted;

  // tests pass in a fake one
  final TripService? service;

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  late final TripService _tripService = widget.service ?? TripService();

  TripChoices? _choices;
  Object? _error;
  RouteChoice? _chosenRoute;
  VehicleChoice? _chosenVehicle;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _fetchChoices();
  }

  Future<void> _fetchChoices() async {
    try {
      final choices = await _tripService.fetchChoices();

      if (!mounted) return;

      setState(() {
        _choices = choices;
        _error = null;

        // a refresh keeps what the conductor picked, unless the vehicle has been taken since
        _chosenRoute = choices.routes.where((route) => route.id == _chosenRoute?.id).firstOrNull ??
            choices.suggestedRoute;
        _chosenVehicle = choices.vehicles
                .where((vehicle) => vehicle.id == _chosenVehicle?.id && !vehicle.busy)
                .firstOrNull ??
            choices.suggestedVehicle;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _fetchChoices();
  }

  Future<void> _chooseRoute(TripChoices choices) async {
    final route = await showRouteSheet(context, routes: choices.routes, chosen: _chosenRoute);

    if (route != null && mounted) {
      setState(() => _chosenRoute = route);
    }
  }

  Future<void> _chooseVehicle(TripChoices choices) async {
    final vehicle = await showVehicleSheet(context, vehicles: choices.vehicles, chosen: _chosenVehicle);

    if (vehicle != null && mounted) {
      setState(() => _chosenVehicle = vehicle);
    }
  }

  // before a first trip nothing is filled in, so the lists open one after the other
  Future<void> _chooseMissing(TripChoices choices) async {
    if (_chosenRoute == null) {
      await _chooseRoute(choices);
    }

    if (mounted && _chosenRoute != null && _chosenVehicle == null) {
      await _chooseVehicle(choices);
    }
  }

  Future<void> _startLoading(TripChoices choices) async {
    final route = _chosenRoute;
    final vehicle = _chosenVehicle;

    // the button isn't greyed out, so a tap asks for whatever is still missing
    if (route == null || vehicle == null) {
      await _chooseMissing(choices);
      return;
    }

    setState(() => _starting = true);

    try {
      final trip = await _tripService.startTrip(route.id, vehicle.id);

      if (!mounted) return;

      widget.onStarted(trip);
    } catch (error) {
      if (!mounted) return;

      setState(() => _starting = false);
      showError(context, error);

      // the vehicle may have gone out with someone else in the meantime
      _fetchChoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices;
    final error = _error;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: const PakitiAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchChoices,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Greeting(firstName: widget.user.firstName),
            const SizedBox(height: 16),
            if (error != null)
              LoadErrorCard(error: error, onRetry: _retry, onLogIn: () => goToLogin(context))
            else if (choices == null)
              _buildLoadingBox()
            else
              ..._buildChoices(choices),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChoices(TripChoices choices) {
    final route = _chosenRoute;
    final vehicle = _chosenVehicle;

    return [
      WhiteCard(
        child: Column(
          children: [
            TripChoiceRow(
              label: 'Route',
              value: route?.name,
              note: route == null ? null : 'About ${travelTime(route.travelMinutes)}',
              onChange: _starting ? null : () => _chooseRoute(choices),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.page),
            TripChoiceRow(
              label: 'Vehicle',
              value: vehicle?.regNumber,
              note: _vehicleNote(choices, vehicle),
              onChange: _starting ? null : () => _chooseVehicle(choices),
            ),
          ],
        ),
      ),
      if (route != null) ...[
        const SizedBox(height: 12),
        Text(
          _waitingText(route),
          style: const TextStyle(fontSize: 14, color: AppColors.statusBooked),
        ),
      ],
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _starting ? null : () => _startLoading(choices),
        child: _starting ? const BusyLabel('Starting…') : const Text('Start loading'),
      ),
    ];
  }

  String? _vehicleNote(TripChoices choices, VehicleChoice? vehicle) {
    if (vehicle == null) {
      return null;
    }

    if (vehicle.id == choices.suggestedVehicleId) {
      return 'The one from your last trip';
    }

    final fleetNumber = vehicle.fleetNumber;

    return fleetNumber == null ? null : 'Fleet number $fleetNumber';
  }

  String _waitingText(RouteChoice route) {
    final where = 'at ${route.from} for ${route.to}';

    return switch (route.waiting) {
      0 => 'No parcels are waiting $where.',
      1 => '1 parcel is waiting $where.',
      _ => '${route.waiting} parcels are waiting $where.',
    };
  }

  Widget _buildLoadingBox() {
    return const SizedBox(
      height: 160,
      child: WhiteCard(child: Center(child: CircularProgressIndicator())),
    );
  }
}
