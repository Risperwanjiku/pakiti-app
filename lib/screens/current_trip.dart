import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/pakiti_app_bar.dart';
import '../widgets/trip_line.dart';
import '../widgets/trip_parcel_row.dart';
import 'login.dart';

// A trip on the way, then at the other end while the clerk scans the parcels off.
class CurrentTripScreen extends StatefulWidget {
  const CurrentTripScreen({
    super.key,
    required this.trip,
    required this.onChanged,
    this.service,
  });

  // departed or arrived, since a trip that is loading has its own screen
  final Trip trip;

  // hands back the trip after a refresh, or null once it has ended
  final ValueChanged<Trip?> onChanged;

  // tests pass in a fake one
  final TripService? service;

  @override
  State<CurrentTripScreen> createState() => _CurrentTripScreenState();
}

class _CurrentTripScreenState extends State<CurrentTripScreen> {
  late final TripService _tripService = widget.service ?? TripService();

  bool _ending = false;

  // pulling down shows the parcels the clerk has scanned off since
  Future<void> _refresh() async {
    try {
      final trip = await _tripService.fetchCurrent();

      if (!mounted) return;

      widget.onChanged(trip);
    } on ApiException catch (e) {
      if (!mounted) return;

      _showError(e);
    }
  }

  Future<void> _endTrip() async {
    setState(() => _ending = true);

    try {
      // asks again first, in case the clerk scanned more off since the screen last asked
      final trip = await _tripService.fetchCurrent();

      if (!mounted) return;

      if (trip == null) {
        widget.onChanged(null);
        return;
      }

      widget.onChanged(trip);

      var anyway = false;

      if (trip.stillOnBoard.isNotEmpty) {
        anyway = await _checkBeforeEnding(trip) ?? false;

        if (!mounted) return;

        if (!anyway) {
          setState(() => _ending = false);
          return;
        }
      }

      await _tripService.end(trip.id, anyway: anyway);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Trip ended.')));
      widget.onChanged(null);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _ending = false);
      _showError(e);
    }
  }

  // true when the conductor ends the trip with the parcels still on board
  Future<bool?> _checkBeforeEnding(Trip trip) {
    final left = trip.stillOnBoard;
    final one = left.length == 1;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    one
                        ? '1 parcel is still on the vehicle'
                        : '${left.length} parcels are still on the vehicle',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  for (final parcel in left) ...[
                    const SizedBox(height: 12),
                    _buildLeftOnBoard(parcel),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Check the boot and under the seats, then hand ${one ? 'it' : 'them'} '
                    'to the clerk at ${trip.toOffice} to scan off.',
                    style: const TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(one ? "I'll hand it over" : "I'll hand them over"),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('End the trip anyway'),
                  ),
                  Text(
                    one
                        ? "The admin is told it wasn't handed over."
                        : "The admin is told they weren't handed over.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftOnBoard(TripParcel parcel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parcel.trackingNo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          Text(
            '${parcel.contents}, ${parcel.size.label.toLowerCase()}',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          Text(
            'For ${parcel.receiverName}',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
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

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final arrived = trip.status == TripStatus.arrived;
    final stillOnBoard = trip.stillOnBoard;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: const PakitiAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _buildTripCard(trip),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    arrived ? 'Parcels' : 'On board',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                Text(
                  arrived
                      ? (stillOnBoard.isEmpty ? 'All scanned off' : '${stillOnBoard.length} still on board')
                      : _count(trip.parcels.length),
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TripParcelCard(
              rows: arrived
                  ? [
                      // the ones still on board first, since they are what is left to do
                      for (final parcel in stillOnBoard)
                        TripParcelRow(
                          mark: ParcelMark.ring,
                          trackingNo: parcel.trackingNo,
                          receiverName: parcel.receiverName,
                          note: 'Still on board',
                          noteColor: AppColors.statusArrived,
                        ),
                      for (final parcel in trip.parcels.where((parcel) => parcel.offAt != null))
                        TripParcelRow(
                          mark: ParcelMark.tick,
                          trackingNo: parcel.trackingNo,
                          receiverName: parcel.receiverName,
                          note: 'Off at ${clockTime(parcel.offAt!)}',
                        ),
                    ]
                  : [
                      for (final parcel in trip.parcels)
                        TripParcelRow(
                          mark: ParcelMark.box,
                          trackingNo: parcel.trackingNo,
                          receiverName: parcel.receiverName,
                        ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final arrived = trip.status == TripStatus.arrived;
    final departedAt = trip.departedAt;
    final arrivedAt = trip.arrivedAt;
    final expected = trip.expectedArrival;
    final minutes = trip.minutes;
    final off = trip.parcels.length - trip.stillOnBoard.length;

    final String headline;

    if (arrived) {
      headline = '$off of ${_count(trip.parcels.length)} scanned off';
    } else if (expected != null) {
      headline = 'Expected in ${trip.to} about ${clockTime(expected)}';
    } else {
      headline = 'On the way to ${trip.to}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildTag(arrived ? 'In ${trip.to}' : 'On the way', arrived: arrived),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 14),
          TripLine(
            from: trip.from,
            fromNote: departedAt == null ? '' : 'Left at ${clockTime(departedAt)}',
            to: trip.to,
            toNote: arrived && arrivedAt != null
                ? 'Arrived at ${clockTime(arrivedAt)}'
                : (minutes == null ? '' : 'About ${travelTime(minutes)}'),
            arrived: arrived,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                size: 20,
                color: AppColors.statusBooked,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  arrived
                      ? '${trip.vehicle}, at ${trip.toOffice}'
                      : '${trip.vehicle}, ${_count(trip.stillOnBoard.length)} on board',
                  style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _ending ? null : _endTrip,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              disabledForegroundColor: AppColors.navy,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.navy, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: Text(_ending ? 'Ending…' : 'End trip'),
          ),
          const SizedBox(height: 8),
          Text(
            'End it once the clerk in ${trip.to} has scanned the parcels off.',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {required bool arrived}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: arrived ? AppColors.statusArrivedBg : AppColors.statusOnTheWayBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: arrived ? AppColors.statusArrived : AppColors.statusOnTheWay,
        ),
      ),
    );
  }

  String _count(int parcels) => parcels == 1 ? '1 parcel' : '$parcels parcels';
}