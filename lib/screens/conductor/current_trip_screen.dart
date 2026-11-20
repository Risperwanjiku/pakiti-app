import 'package:flutter/material.dart';

import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/services/trip_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/pakiti_app_bar.dart';
import 'package:pakiti_app/widgets/common/section_title.dart';
import 'package:pakiti_app/widgets/trip/still_on_board_sheet.dart';
import 'package:pakiti_app/widgets/trip/trip_parcel_row.dart';
import 'package:pakiti_app/widgets/trip/trip_progress_card.dart';

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
  Future<void> _refreshTrip() async {
    try {
      final trip = await _tripService.fetchCurrentTrip();

      if (!mounted) return;

      widget.onChanged(trip);
    } catch (error) {
      if (!mounted) return;

      showError(context, error);
    }
  }

  Future<void> _endTrip() async {
    setState(() => _ending = true);

    try {
      // asks again first, in case the clerk scanned more off since the screen last asked
      final trip = await _tripService.fetchCurrentTrip();

      if (!mounted) return;

      if (trip == null) {
        widget.onChanged(null);
        return;
      }

      widget.onChanged(trip);

      var endAnyway = false;

      if (trip.stillOnBoard.isNotEmpty) {
        endAnyway = await showStillOnBoardSheet(context, trip) ?? false;

        if (!mounted) return;

        if (!endAnyway) {
          setState(() => _ending = false);
          return;
        }
      }

      await _tripService.endTrip(trip.id, anyway: endAnyway);

      if (!mounted) return;

      showMessage(context, 'Trip ended.');
      widget.onChanged(null);
    } catch (error) {
      if (!mounted) return;

      setState(() => _ending = false);
      showError(context, error);
    }
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
        onRefresh: _refreshTrip,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            TripProgressCard(trip: trip, ending: _ending, onEndTrip: _endTrip),
            const SizedBox(height: 20),
            SectionTitle(
              title: arrived ? 'Parcels' : 'On board',
              note: arrived
                  ? (stillOnBoard.isEmpty ? 'All scanned off' : '${stillOnBoard.length} still on board')
                  : parcelCount(trip.parcels.length),
            ),
            const SizedBox(height: 8),
            TripParcelCard(
              rows: arrived ? _buildArrivedRows(trip) : _buildOnTheWayRows(trip),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildArrivedRows(Trip trip) {
    return [
      // the ones still on board first, since they are what is left to do
      for (final parcel in trip.stillOnBoard)
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
    ];
  }

  List<Widget> _buildOnTheWayRows(Trip trip) {
    return [
      for (final parcel in trip.parcels)
        TripParcelRow(
          mark: ParcelMark.box,
          trackingNo: parcel.trackingNo,
          receiverName: parcel.receiverName,
        ),
    ];
  }
}
