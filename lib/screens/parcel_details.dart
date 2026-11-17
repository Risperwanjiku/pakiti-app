import 'package:flutter/material.dart';

import '../models/parcel_details.dart';
import '../models/parcel_status.dart';
import '../services/api_client.dart';
import '../services/parcel_service.dart';
import '../theme/app_colors.dart';
import '../utils/call.dart';
import '../utils/format.dart';
import '../widgets/dashed_line.dart';
import '../widgets/parcel_history.dart';
import '../widgets/status_tag.dart';
import 'login.dart';
import 'parcel_photo.dart';

class ParcelDetailsScreen extends StatefulWidget {
  const ParcelDetailsScreen({super.key, required this.trackingNo, this.service});

  final String trackingNo;

  // tests pass in a fake one
  final ParcelService? service;

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen> {
  late final ParcelService _service = widget.service ?? ParcelService();

  // made once, so the small photo and the full one share one download
  late final ImageProvider _photo = _service.photo(widget.trackingNo);

  late Future<ParcelDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = _service.details(widget.trackingNo);
  }

  Future<void> _refresh() async {
    setState(() {
      _details = _service.details(widget.trackingNo);
    });
    await _details.then((_) {}, onError: (_) {});
  }

  void _retry() {
    setState(() {
      _details = _service.details(widget.trackingNo);
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _call(String phone) async {
    if (await callNumber(phone)) {
      return;
    }

    if (mounted) {
      _showMessage("The phone app didn't open. The number is ${localPhone(phone)}.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelPhotoScreen(photo: _photo, trackingNo: widget.trackingNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        title: Text(
          widget.trackingNo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<ParcelDetails>(
          future: _details,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildContent(snapshot),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(AsyncSnapshot<ParcelDetails> snapshot) {
    final loading = snapshot.connectionState == ConnectionState.waiting;
    final details = snapshot.data;

    if (snapshot.hasError && !loading) {
      return [_buildError(snapshot.error)];
    }

    if (details == null) {
      return [
        _buildPlaceholder(200),
        const SizedBox(height: 16),
        _buildPlaceholder(160),
        const SizedBox(height: 16),
        _buildPlaceholder(220),
      ];
    }

    return [
      // a changed record matters more than anything else on the page
      if (!details.recordChecked) ...[
        _buildWarning(),
        const SizedBox(height: 16),
      ],
      _buildWhereNow(details),
      const SizedBox(height: 16),
      _buildPeople(details),
      const SizedBox(height: 16),
      _buildParcel(details),
      const SizedBox(height: 24),
      _buildHistory(details),
    ];
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusLateBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gpp_maybe_outlined, size: 22, color: AppColors.statusLate),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This record has changed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusLate,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Something in this parcel's record was changed after it was "
                  'saved. Tell your admin before you hand the parcel over.',
                  style: TextStyle(fontSize: 13, color: AppColors.darkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhereNow(ParcelDetails details) {
    final vehicle = details.vehicle;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusTag(status: details.status, isLate: details.isLate),
                const SizedBox(height: 6),
                Text(
                  _headline(details),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 14),
                _buildTrip(details),
              ],
            ),
          ),
          if (vehicle != null) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.page),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus_outlined,
                    size: 20,
                    color: AppColors.statusBooked,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${vehicle.regNumber}, conductor ${vehicle.conductor}',
                      style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                    ),
                  ),
                  _buildCallButton(
                    vehicle.conductorPhone,
                    'Call ${vehicle.conductor}, the conductor',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _headline(ParcelDetails details) {
    final booking = details.booking;
    final expected = details.expectedArrival;
    final vehicle = details.vehicle;

    return switch (details.status) {
      ParcelStatus.booked => 'Waiting at ${details.fromOffice}',
      ParcelStatus.loaded => vehicle == null
          ? 'Loaded, about to leave ${booking.from}'
          : 'Loaded onto ${vehicle.regNumber}',
      ParcelStatus.inTransit => expected == null
          ? 'On the way to ${booking.to}'
          : details.isLate
              ? 'Was expected in ${booking.to} at ${clockTime(expected)}'
              : 'Expected in ${booking.to} about ${clockTime(expected)}',
      ParcelStatus.arrived => 'Ready for collection at ${details.toOffice}',
      ParcelStatus.collected => 'Collected by ${booking.receiverName}',
    };
  }

  Widget _buildTrip(ParcelDetails details) {
    final booking = details.booking;
    final arrived = details.status == ParcelStatus.arrived ||
        details.status == ParcelStatus.collected;

    return Column(
      children: [
        SizedBox(
          height: 16,
          child: Row(
            children: [
              _buildTripDot(filled: true),
              const SizedBox(width: 6),
              Expanded(
                child: arrived
                    ? Container(height: 2, color: AppColors.navy)
                    : const DashedLine(color: AppColors.divider),
              ),
              const SizedBox(width: 6),
              _buildTripDot(filled: arrived),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTripEnd(booking.from, _leftNote(details))),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTripEnd(booking.to, _rightNote(details), atEnd: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripDot({required bool filled}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: 2),
      ),
    );
  }

  Widget _buildTripEnd(String town, String note, {bool atEnd = false}) {
    return Column(
      crossAxisAlignment: atEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          town,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        Text(
          note,
          textAlign: atEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  String _leftNote(ParcelDetails details) {
    final left = details.timeOf(CustodyStep.departed);
    final loaded = details.timeOf(CustodyStep.loaded);

    if (left != null) {
      return 'Left at ${clockTime(left)}';
    }

    if (loaded != null) {
      return 'Loaded at ${clockTime(loaded)}';
    }

    return 'Booked at ${clockTime(details.booking.bookedAt)}';
  }

  String _rightNote(ParcelDetails details) {
    final arrived = details.timeOf(CustodyStep.arrived);

    return arrived == null
        ? travelTime(details.travelMinutes)
        : 'Arrived at ${clockTime(arrived)}';
  }

  Widget _buildPeople(ParcelDetails details) {
    final booking = details.booking;

    return _buildCard(
      child: Column(
        children: [
          _buildPerson('Sender', booking.senderName, booking.senderPhone),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          _buildPerson('Receiver', booking.receiverName, booking.receiverPhone),
        ],
      ),
    );
  }

  Widget _buildPerson(String role, String name, String phone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  localPhone(phone),
                  style: const TextStyle(fontSize: 14, color: AppColors.grey),
                ),
              ],
            ),
          ),
          _buildCallButton(phone, 'Call $name'),
        ],
      ),
    );
  }

  Widget _buildCallButton(String phone, String label) {
    return IconButton(
      tooltip: label,
      onPressed: () => _call(phone),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.navTint,
        fixedSize: const Size(44, 44),
      ),
      icon: const Icon(Icons.call_outlined, size: 20, color: AppColors.navy),
    );
  }

  Widget _buildParcel(ParcelDetails details) {
    final booking = details.booking;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Parcel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFact("What's inside", booking.contents),
                _buildFact('Size', booking.size.label),
                _buildFact('Value', ksh(booking.value)),
                _buildFact('Fee paid', ksh(booking.fee)),
              ],
            ),
          ),
          if (details.hasBookingPhoto) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.page),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _buildPhotoRow(details),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(ParcelDetails details) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: _photo,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              return frame == null && !wasSynchronouslyLoaded
                  ? _buildPhotoBox(Icons.photo_outlined)
                  : child;
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPhotoBox(Icons.image_not_supported_outlined);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo at booking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                dayAndTime(details.booking.bookedAt),
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _openPhoto,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.link,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          child: const Text('View'),
        ),
      ],
    );
  }

  Widget _buildPhotoBox(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.page,
      child: Icon(icon, color: AppColors.border),
    );
  }

  Widget _buildHistory(ParcelDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: ParcelHistory(details: details),
              ),
              if (details.recordChecked) ...[
                const Divider(height: 1, thickness: 1, color: AppColors.page),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.statusCollected,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Custody record checked. ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.statusCollected,
                                ),
                              ),
                              TextSpan(
                                text: 'Nothing has changed since each hand-off was recorded.',
                              ),
                            ],
                          ),
                          style: TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object? error) {
    final sessionEnded = error is ApiException && error.statusCode == 401;
    final notFound = error is ApiException && error.statusCode == 404;
    final message = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';

    return _buildCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
          ),
          // trying again won't find a parcel that isn't there
          if (!notFound) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: sessionEnded ? _goToLogin : _retry,
              child: Text(sessionEnded ? 'Log in again' : 'Try again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}