import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/load_result.dart';
import '../models/parcel_status.dart';
import '../models/trip.dart';
import '../services/api_client.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../widgets/label_scanner.dart';
import '../widgets/trip_parcel_row.dart';
import '../widgets/type_number_sheet.dart';
import 'login.dart';

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

  Future<void> _load(String trackingNo) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      final result = await _tripService.load(widget.trip.id, trackingNo);

      if (!mounted) return;

      widget.onChanged(result.trip);
      await _tell(result);
    } on ApiException catch (e) {
      if (!mounted) return;

      _buzzWarning();
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _tell(LoadResult result) async {
    final parcel = result.parcel;

    switch (result.outcome) {
      case LoadOutcome.loaded:
        HapticFeedback.mediumImpact();
      case LoadOutcome.alreadyOnBoard:
        HapticFeedback.mediumImpact();
        _showMessage('${parcel.trackingNo} is already on board.');
      case LoadOutcome.wrongRoute:
        _buzzWarning();
        await _showKeepOff(
          parcel.trackingNo,
          before: 'Give ',
          after: ' back to the clerk at ${widget.trip.from} so it goes on a ${parcel.to} vehicle.',
          parcelGoesTo: parcel.to,
        );
      case LoadOutcome.otherVehicle:
        _buzzWarning();
        await _showKeepOff(
          parcel.trackingNo,
          after: ' was scanned onto ${parcel.vehicle} first. Hand it to the conductor of that vehicle.',
        );
      case LoadOutcome.alreadyLeft:
        _buzzWarning();
        await _showKeepOff(parcel.trackingNo, after: _alreadyLeft(parcel));
    }
  }

  String _alreadyLeft(ScannedParcel parcel) {
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

  Future<void> _typeNumber() async {
    if (_busy) {
      return;
    }

    // the camera waits while the sheet is open
    setState(() => _busy = true);
    final trackingNo = await showTypeNumberSheet(context, action: 'Load parcel');

    if (!mounted) return;

    setState(() => _busy = false);

    if (trackingNo != null) {
      await _load(trackingNo);
    }
  }

  Future<void> _depart() async {
    setState(() {
      _busy = true;
      _departing = true;
    });

    try {
      final trip = await _tripService.depart(widget.trip.id);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      widget.onChanged(trip);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _departing = false;
      });
      _showError(e);
    }
  }

  // only offered while nothing is on board, since a trip with parcels on it has to go
  Future<void> _cancel() async {
    setState(() => _busy = true);

    try {
      await _tripService.cancel(widget.trip.id);

      if (!mounted) return;

      widget.onChanged(null);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);
      _showError(e);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _showKeepOff(
    String trackingNo, {
    String before = '',
    required String after,
    String? parcelGoesTo,
  }) {
    return showModalBottomSheet<void>(
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.statusLateBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline, color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keep this one off',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  if (parcelGoesTo != null) ...[
                    const SizedBox(height: 16),
                    // the two boxes stay the same height when a label runs onto two lines
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildGoesTo(
                              'This parcel goes to',
                              parcelGoesTo,
                              wrong: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGoesTo('This vehicle goes to', widget.trip.to),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, color: AppColors.grey),
                      children: [
                        TextSpan(text: before),
                        TextSpan(
                          text: trackingNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        TextSpan(text: after),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Carry on scanning'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoesTo(String label, String town, {bool wrong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: wrong ? AppColors.statusLateBg : AppColors.page,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: wrong ? AppColors.error : AppColors.grey,
            ),
          ),
          Text(
            town,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final canGoBack = trip.parcels.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: canGoBack
            ? IconButton(
                tooltip: 'Back',
                onPressed: _busy ? null : _cancel,
                icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
              )
            : null,
        titleSpacing: canGoBack ? 4 : 24,
        title: Text(
          'Loading for ${trip.to}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: Column(
        children: [
          LabelScanner(
            paused: _busy,
            camera: widget.camera,
            onScanned: _load,
            onTypeNumber: _typeNumber,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _buildTitle('On board', _count(trip.parcels.length)),
                const SizedBox(height: 8),
                if (trip.parcels.isEmpty)
                  _buildEmpty('Nothing on board yet. Scan a label to load the parcel.')
                else
                  TripParcelCard(
                    rows: [
                      // the newest first, so the one just scanned is at the top
                      for (final parcel in trip.parcels.reversed) _buildOnBoard(parcel),
                    ],
                  ),
                const SizedBox(height: 20),
                _buildTitle('Still at ${trip.from}', _count(trip.waiting.length)),
                const SizedBox(height: 8),
                if (trip.waiting.isEmpty)
                  _buildEmpty('Nothing else is waiting at ${trip.from} for ${trip.to}.')
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
      bottomNavigationBar: _buildDepartBar(trip),
    );
  }

  Widget _buildOnBoard(TripParcel parcel) {
    final loadedAt = parcel.loadedAt;
    final justNow = loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(minutes: 1);

    return TripParcelRow(
      mark: ParcelMark.tick,
      trackingNo: parcel.trackingNo,
      receiverName: parcel.receiverName,
      note: loadedAt == null ? null : (justNow ? 'Just now' : clockTime(loadedAt)),
      noteColor: justNow ? AppColors.statusCollected : AppColors.grey,
    );
  }

  Widget _buildTitle(String title, String count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.grey),
      ),
    );
  }

  Widget _buildDepartBar(Trip trip) {
    final onBoard = trip.parcels.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: onBoard == 0 || _busy ? null : _depart,
              child: _departing
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
                        Text('Departing…'),
                      ],
                    )
                  : Text(onBoard == 0 ? 'Depart' : 'Depart with ${_count(onBoard)}'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Each receiver gets an SMS when you depart.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _count(int parcels) => parcels == 1 ? '1 parcel' : '$parcels parcels';
}