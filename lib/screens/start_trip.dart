import 'package:flutter/material.dart';

import '../models/staff_user.dart';
import '../models/trip.dart';
import '../models/trip_choices.dart';
import '../services/api_client.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/pakiti_app_bar.dart';
import 'login.dart';

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
  RouteChoice? _route;
  VehicleChoice? _vehicle;
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
        _route = choices.routes.where((route) => route.id == _route?.id).firstOrNull ??
            choices.suggestedRoute;
        _vehicle = choices.vehicles
                .where((vehicle) => vehicle.id == _vehicle?.id && !vehicle.busy)
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

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _chooseRoute(TripChoices choices) async {
    final route = await showModalBottomSheet<RouteChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RouteSheet(routes: choices.routes, chosen: _route),
    );

    if (route != null && mounted) {
      setState(() => _route = route);
    }
  }

  Future<void> _chooseVehicle(TripChoices choices) async {
    final vehicle = await showModalBottomSheet<VehicleChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VehicleSheet(vehicles: choices.vehicles, chosen: _vehicle),
    );

    if (vehicle != null && mounted) {
      setState(() => _vehicle = vehicle);
    }
  }

  // before a first trip nothing is filled in, so the lists open one after the other
  Future<void> _chooseMissing(TripChoices choices) async {
    if (_route == null) {
      await _chooseRoute(choices);
    }

    if (mounted && _route != null && _vehicle == null) {
      await _chooseVehicle(choices);
    }
  }

  Future<void> _start(TripChoices choices) async {
    final route = _route;
    final vehicle = _vehicle;

    // the button isn't greyed out, so a tap asks for whatever is still missing
    if (route == null || vehicle == null) {
      await _chooseMissing(choices);
      return;
    }

    setState(() => _starting = true);

    try {
      final trip = await _tripService.start(route.id, vehicle.id);

      if (!mounted) return;

      widget.onStarted(trip);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _starting = false);
      _showError(e);

      // the vehicle may have gone out with someone else in the meantime
      _fetchChoices();
    }
  }

  void _showError(ApiException error) {
    final sessionEnded = error.statusCode == 401;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: sessionEnded
              ? SnackBarAction(label: 'Log in again', onPressed: _goToLogin)
              : null,
        ),
      );
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
            Text(
              'Habari, ${widget.user.firstName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 16),
            if (error != null)
              _buildError(error)
            else if (choices == null)
              _buildPlaceholder()
            else
              ..._buildChoices(choices),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChoices(TripChoices choices) {
    final route = _route;
    final vehicle = _vehicle;

    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildChoice(
              label: 'Route',
              value: route?.name,
              note: route == null ? null : 'About ${travelTime(route.minutes)}',
              onChange: () => _chooseRoute(choices),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.page),
            _buildChoice(
              label: 'Vehicle',
              value: vehicle?.regNumber,
              note: _vehicleNote(choices, vehicle),
              onChange: () => _chooseVehicle(choices),
            ),
          ],
        ),
      ),
      if (route != null) ...[
        const SizedBox(height: 12),
        Text(
          _waiting(route),
          style: const TextStyle(fontSize: 14, color: AppColors.statusBooked),
        ),
      ],
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _starting ? null : () => _start(choices),
        child: _starting
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Starting…'),
                ],
              )
            : const Text('Start loading'),
      ),
    ];
  }

  Widget _buildChoice({
    required String label,
    required String? value,
    required String? note,
    required VoidCallback onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                Text(
                  value ?? 'Not chosen yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value == null ? AppColors.grey : AppColors.darkText,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _starting ? null : onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(value == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
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

  String _waiting(RouteChoice route) {
    final where = 'at ${route.from} for ${route.to}';

    return switch (route.waiting) {
      0 => 'No parcels are waiting $where.',
      1 => '1 parcel is waiting $where.',
      _ => '${route.waiting} parcels are waiting $where.',
    };
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(),
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

// every route, under the town it leaves from
class _RouteSheet extends StatelessWidget {
  const _RouteSheet({required this.routes, required this.chosen});

  final List<RouteChoice> routes;
  final RouteChoice? chosen;

  @override
  Widget build(BuildContext context) {
    // routes with parcels waiting go first, so the one that matters isn't far down the list
    final ordered = [
      ...routes.where((route) => route.waiting > 0),
      ...routes.where((route) => route.waiting == 0),
    ];
    final towns = {for (final route in ordered) route.from};

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose the route',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final town in towns) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                      child: Text(
                        'From $town',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    for (final route in ordered.where((route) => route.from == town))
                      _SheetRow(
                        title: 'To ${route.to}',
                        note: switch (route.waiting) {
                          0 => 'Nothing waiting',
                          1 => '1 parcel waiting',
                          _ => '${route.waiting} parcels waiting',
                        },
                        noteColor: route.waiting > 0 ? AppColors.link : AppColors.grey,
                        chosen: route.id == chosen?.id,
                        onTap: () => Navigator.of(context).pop(route),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSheet extends StatelessWidget {
  const _VehicleSheet({required this.vehicles, required this.chosen});

  final List<VehicleChoice> vehicles;
  final VehicleChoice? chosen;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose the vehicle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final vehicle in vehicles)
                    _SheetRow(
                      title: vehicle.regNumber,
                      note: vehicle.busy
                          ? 'On another trip'
                          : (vehicle.fleetNumber == null ? null : 'Fleet number ${vehicle.fleetNumber}'),
                      chosen: vehicle.id == chosen?.id,
                      // a vehicle out on another trip can't be picked
                      onTap: vehicle.busy ? null : () => Navigator.of(context).pop(vehicle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.title,
    this.note,
    this.noteColor = AppColors.grey,
    required this.chosen,
    required this.onTap,
  });

  final String title;
  final String? note;
  final Color noteColor;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.darkText : AppColors.grey,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: noteColor == AppColors.grey ? FontWeight.w400 : FontWeight.w500,
                        color: noteColor,
                      ),
                    ),
                ],
              ),
            ),
            if (chosen) const Icon(Icons.check, color: AppColors.link),
          ],
        ),
      ),
    );
  }
}