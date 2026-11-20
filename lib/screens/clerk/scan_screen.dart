import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/clerk_service.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/scan/arrival_sheet.dart';
import 'package:pakiti_app/widgets/scan/arrivals_today.dart';
import 'package:pakiti_app/widgets/scan/arrived_card.dart';
import 'package:pakiti_app/widgets/scan/label_scanner.dart';
import 'package:pakiti_app/widgets/scan/not_here_sheet.dart';
import 'package:pakiti_app/widgets/scan/type_number_sheet.dart';

// The clerk's Scan tab, for scanning parcels off a vehicle when it comes in.
class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.onSeeAll,
    this.service,
    this.parcelService,
    this.camera = true,
  });

  // opens the Parcels tab on Arrived
  final VoidCallback onSeeAll;

  // tests pass in fake ones
  final ClerkService? service;
  final ParcelService? parcelService;

  // false in tests, where there is no camera
  final bool camera;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ClerkService _clerkService = widget.service ?? ClerkService();
  late final ParcelService _parcelService = widget.parcelService ?? ParcelService();

  late Future<List<ArrivedParcel>> _arrivals;

  // the last parcel marked as arrived, shown over the camera until the next scan
  ArrivalResult? _lastArrival;

  // a scan or a sheet is being dealt with, so the camera waits
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _arrivals = _clerkService.fetchArrivals();
  }

  void _reloadArrivals() {
    setState(() {
      _arrivals = _clerkService.fetchArrivals();
    });
  }

  Future<void> _checkParcel(String trackingNo) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _lastArrival = null;
    });

    try {
      final check = await _clerkService.checkArrival(trackingNo);

      if (!mounted) return;

      await _showCheck(check);
    } on ApiException catch (error) {
      if (!mounted) return;

      _buzzWarning();
      showApiError(context, error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showCheck(ArrivalCheck check) async {
    final trackingNo = check.trackingNo;

    switch (check.verdict) {
      case ArrivalVerdict.arriving:
        await _offerArrival(check.parcel!);
      case ArrivalVerdict.notHere:
        _buzzWarning();
        await showNotHereSheet(context, trackingNo: trackingNo, to: check.to, here: check.here);
      case ArrivalVerdict.arrived:
        _warn('$trackingNo was already marked as arrived.');
      case ArrivalVerdict.collected:
        _warn('$trackingNo has already been collected.');
      case ArrivalVerdict.notLoaded:
        _warn("$trackingNo was never scanned onto a vehicle, so it can't be marked as arrived.");
      case ArrivalVerdict.notDeparted:
        _warn("The conductor hasn't marked this trip as departed yet.");
      case ArrivalVerdict.outgoing:
        _warn('$trackingNo is going out from this office, not coming in.');
    }
  }

  // the clerk checks the parcel against its photo before it is marked
  Future<void> _offerArrival(IncomingParcel parcel) async {
    final marked = await showArrivalSheet(
      context,
      parcel: parcel,
      photo: _parcelService.photoOf(parcel.trackingNo),
    );

    if (!marked || !mounted) {
      return;
    }

    try {
      final result = await _clerkService.markArrived(parcel.trackingNo);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      setState(() {
        _lastArrival = result;
        _arrivals = Future.value(result.arrivals);
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      _buzzWarning();
      showApiError(context, error);
    }
  }

  void _warn(String message) {
    _buzzWarning();
    showMessage(context, message);
  }

  // a light tap when a parcel is marked, and this longer buzz when it can't be
  void _buzzWarning() {
    HapticFeedback.vibrate();
  }

  Future<void> _typeTrackingNumber() async {
    if (_busy) {
      return;
    }

    // the camera waits while the sheet is open
    setState(() => _busy = true);
    final trackingNo = await showTypeNumberSheet(context, action: 'Find parcel');

    if (!mounted) return;

    setState(() => _busy = false);

    if (trackingNo != null) {
      await _checkParcel(trackingNo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastArrival = _lastArrival;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: const PageAppBar(title: 'Scan', isTab: true),
      body: Column(
        children: [
          Stack(
            children: [
              LabelScanner(
                height: 430,
                frame: 200,
                frameTop: 70,
                paused: _busy,
                camera: widget.camera,
                // the card takes the hint's place, so the two don't sit on top of each other
                showHint: lastArrival == null,
                onScanned: _checkParcel,
                onTypeNumber: _typeTrackingNumber,
              ),
              if (lastArrival != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 72,
                  child: ArrivedCard(
                    trackingNo: lastArrival.trackingNo,
                    receiverName: lastArrival.receiverName,
                  ),
                ),
            ],
          ),
          Expanded(
            child: ArrivalsToday(
              arrivals: _arrivals,
              onRetry: _reloadArrivals,
              onSeeAll: widget.onSeeAll,
            ),
          ),
        ],
      ),
    );
  }
}
