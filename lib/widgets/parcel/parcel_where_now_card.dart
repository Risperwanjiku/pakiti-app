import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/call_button.dart';
import 'package:pakiti_app/widgets/common/status_tag.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/trip/trip_line.dart';

// the top card on a parcel: its status, where it is now, and the vehicle carrying it
class ParcelWhereNowCard extends StatelessWidget {
  const ParcelWhereNowCard({super.key, required this.details, required this.onCall});

  final ParcelDetails details;

  // gets the phone number to call
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    final vehicle = details.vehicle;

    return WhiteCard(
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
                  _headline(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 14),
                TripLine(
                  from: details.booking.from,
                  fromNote: _departureNote(),
                  to: details.booking.to,
                  toNote: _arrivalNote(),
                  arrived:
                      details.status == ParcelStatus.arrived ||
                      details.status == ParcelStatus.collected,
                ),
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
                  CallButton(
                    label: 'Call ${vehicle.conductor}, the conductor',
                    onPressed: () => onCall(vehicle.conductorPhone),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _headline() {
    final booking = details.booking;
    final expected = details.expectedArrival;
    final vehicle = details.vehicle;

    return switch (details.status) {
      ParcelStatus.booked => 'Waiting at ${details.fromOffice}',
      ParcelStatus.loaded =>
        vehicle == null
            ? 'Loaded, about to leave ${booking.from}'
            : 'Loaded onto ${vehicle.regNumber}',
      ParcelStatus.inTransit =>
        expected == null
            ? 'On the way to ${booking.to}'
            : details.isLate
            ? 'Was expected in ${booking.to} ${atTimeOrDay(expected)}'
            : 'Expected in ${booking.to} about ${timeWithDay(expected)}',
      ParcelStatus.arrived => 'Ready for collection at ${details.toOffice}',
      ParcelStatus.collected => 'Collected by ${booking.receiverName}',
    };
  }

  // the latest thing that happened at the start of the trip
  String _departureNote() {
    final departedAt = details.timeOf(CustodyStep.departed);
    final loadedAt = details.timeOf(CustodyStep.loaded);

    if (departedAt != null) {
      return 'Left ${atTimeOrDay(departedAt)}';
    }

    if (loadedAt != null) {
      return 'Loaded ${atTimeOrDay(loadedAt)}';
    }

    return 'Booked ${atTimeOrDay(details.booking.bookedAt)}';
  }

  String _arrivalNote() {
    final arrivedAt = details.timeOf(CustodyStep.arrived);

    return arrivedAt == null
        ? travelTime(details.travelMinutes)
        : 'Arrived ${atTimeOrDay(arrivedAt)}';
  }
}
