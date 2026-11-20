import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/models/load_result.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/services/trip_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/common/section_title.dart';
import 'package:pakiti_app/widgets/scan/label_scanner.dart';
import 'package:pakiti_app/widgets/scan/type_number_sheet.dart';
import 'package:pakiti_app/widgets/trip/depart_bar.dart';
import 'package:pakiti_app/widgets/trip/empty_trip_list.dart';
import 'package:pakiti_app/widgets/trip/keep_off_sheet.dart';
import 'package:pakiti_app/widgets/trip/trip_parcel_row.dart';

class LoadParcelsScreen extends StatefulWidget {
  const LoadParcelsScreen({
    super.key,
    required this.trip,
    required this.onChanged,
    this.service,
    this.camera = true,
  });

  final Trip trip;

  // hands back the trip after each change, or null once it is cancelled
  final ValueChanged<Trip?> onChanged;

  // tests pass in a fake one
  final TripService? service;

  // false in tests, where there is no camera
  final bool camera;

  @override
  State<LoadParcelsScreen> createState() => _LoadParcelsScreenState();
}

class _LoadParcelsScreenState extends State<LoadParcelsScreen> {
  late final TripService _tripService = widget.service ?? TripService();

  // a scan, a sheet or Depart is being dealt with, so the camera waits
  bool _busy = false;
  bool _departing = false;

  Future<void> _loadParcel(String trackingNo) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      final result = await _tripService.loadParcel(widget.trip.id, trackingNo);

      if (!mounted) return;

      widget.onChanged(result.trip);
      await _showScanResult(result);
    } catch (error) {
      if (!mounted) return;

      _buzzWarning();
      showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showScanResult(LoadResult result) async {
    final parcel = result.parcel;
    final trip = widget.trip;

    switch (result.outcome) {
      case LoadOutcome.loaded:
        HapticFeedback.mediumImpact();
      case LoadOutcome.alreadyOnBoard:
        HapticFeedback.mediumImpact();
        showMessage(context, '${parcel.trackingNo} is already on board.');
      case LoadOutcome.wrongRoute:
        _buzzWarning();

        // booked at another office, so it shouldn't be here at all
        if (parcel.from != trip.from) {
          await showKeepOffSheet(
            context,
            trackingNo: parcel.trackingNo,
            before: 'Give ',
            after: ' to the clerk at ${trip.from} to sort out.',
            mismatch: TownMismatch(
              parcelLabel: 'This parcel is from',
              parcelTown: parcel.from,
              vehicleLabel: 'This vehicle is at',
              vehicleTown: trip.from,
            ),
          );
        } else {
          await showKeepOffSheet(
            context,
            trackingNo: parcel.trackingNo,
            before: 'Give ',
            after: ' back to the clerk at ${trip.from} so it goes on a ${parcel.to} vehicle.',
            mismatch: TownMismatch(
              parcelLabel: 'This parcel goes to',
              parcelTown: parcel.to,
              vehicleLabel: 'This vehicle goes to',
              vehicleTown: trip.to,
            ),
          );
        }
      case LoadOutcome.otherVehicle:
        _buzzWarning();
        await showKeepOffSheet(
          context,
          trackingNo: parcel.trackingNo,
          after:
              ' was scanned onto ${parcel.vehicle} first. Hand it to the conductor of that vehicle.',
        );
      case LoadOutcome.alreadyLeft:
        _buzzWarning();
        await showKeepOffSheet(
          context,
          trackingNo: parcel.trackingNo,
          after: _alreadyLeftReason(parcel),
        );
    }
  }

  String _alreadyLeftReason(ScannedParcel parcel) {
    return switch (parcel.status) {
      ParcelStatus.arrived => ' has already arrived in ${parcel.to}.',
      ParcelStatus.collected => ' has already been collected.',
      _ => ' has already left ${parcel.from}.',
    };
  }

  // a light tap when a parcel goes on, and this longer buzz when it has to stay off
  void _buzzWarning() {
    HapticFeedback.vibrate();
  }

  Future<void> _typeTrackingNumber() async {
    if (_busy) {
      return;
    }

    // the camera waits while the sheet is open
    setState(() => _busy = true);
    final trackingNo = await showTypeNumberSheet(context, action: 'Load parcel');

    if (!mounted) return;

    setState(() => _busy = false);

    if (trackingNo != null) {
      await _loadParcel(trackingNo);
    }
  }

  Future<void> _depart() async {
    // the button stays blue with nothing on board, so a tap says what is missing
    if (widget.trip.parcels.isEmpty) {
      showMessage(context, 'Scan at least one parcel onto the vehicle before you depart.');
      return;
    }

    setState(() {
      _busy = true;
      _departing = true;
    });

    try {
      final trip = await _tripService.departTrip(widget.trip.id);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      widget.onChanged(trip);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _departing = false;
      });
      showError(context, error);
    }
  }

  // only offered while nothing is on board, since a trip with parcels on it has to go
  Future<void> _cancelTrip() async {
    setState(() => _busy = true);

    try {
      await _tripService.cancelTrip(widget.trip.id);

      if (!mounted) return;

      widget.onChanged(null);
    } catch (error) {
      if (!mounted) return;

      setState(() => _busy = false);
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final onBoard = trip.parcels.length;
    final canGoBack = trip.parcels.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PageAppBar(
        title: 'Loading for ${trip.to}',
        // going back cancels the trip, so it is only offered while nothing is on board
        leading: canGoBack
            ? IconButton(
                tooltip: 'Back',
                onPressed: _busy ? null : _cancelTrip,
                icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
              )
            : null,
      ),
      body: Column(
        children: [
          LabelScanner(
            paused: _busy,
            camera: widget.camera,
            onScanned: _loadParcel,
            onTypeNumber: _typeTrackingNumber,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                // no count when a list is empty, since the note under it already says so
                SectionTitle(title: 'On board', note: onBoard == 0 ? null : parcelCount(onBoard)),
                const SizedBox(height: 8),
                if (trip.parcels.isEmpty)
                  const EmptyTripList(
                    text: 'Nothing on board yet. Scan a label to load the parcel.',
                  )
                else
                  TripParcelCard(
                    rows: [
                      // the newest first, so the one just scanned is at the top
                      for (final parcel in trip.parcels.reversed) _buildOnBoardRow(parcel),
                    ],
                  ),
                const SizedBox(height: 20),
                SectionTitle(
                  title: 'Still at ${trip.from}',
                  note: trip.waiting.isEmpty ? null : parcelCount(trip.waiting.length),
                ),
                const SizedBox(height: 8),
                if (trip.waiting.isEmpty)
                  EmptyTripList(
                    text: trip.parcels.isEmpty
                        ? 'Nothing is waiting at ${trip.from} for ${trip.to}.'
                        : 'Nothing else is waiting at ${trip.from} for ${trip.to}.',
                  )
                else
                  TripParcelCard(
                    rows: [
                      for (final parcel in trip.waiting)
                        TripParcelRow(
                          mark: ParcelMark.ring,
                          trackingNo: parcel.trackingNo,
                          receiverName: parcel.receiverName,
                          muted: true,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DepartBar(
        label: onBoard == 0 ? 'Depart' : 'Depart with ${parcelCount(onBoard)}',
        departing: _departing,
        onDepart: _busy ? null : _depart,
      ),
    );
  }

  Widget _buildOnBoardRow(TripParcel parcel) {
    final loadedAt = parcel.loadedAt;
    final justNow =
        loadedAt != null && DateTime.now().difference(loadedAt) < const Duration(minutes: 1);

    return TripParcelRow(
      mark: ParcelMark.tick,
      trackingNo: parcel.trackingNo,
      receiverName: parcel.receiverName,
      note: loadedAt == null ? null : (justNow ? 'Just now' : clockTime(loadedAt)),
      noteColor: justNow ? AppColors.statusCollected : AppColors.grey,
    );
  }
}
