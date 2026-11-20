import 'package:flutter/material.dart';

import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/trip/trip_line.dart';

// The card at the top of a departed or arrived trip, with the End trip button.
class TripProgressCard extends StatelessWidget {
  const TripProgressCard({
    super.key,
    required this.trip,
    required this.ending,
    required this.onEndTrip,
  });

  final Trip trip;

  // the button says Ending… and waits while the trip ends
  final bool ending;

  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    final arrived = trip.status == TripStatus.arrived;
    final departedAt = trip.departedAt;
    final arrivedAt = trip.arrivedAt;
    final minutes = trip.expectedMinutes;

    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildStatusTag(arrived ? 'In ${trip.to}' : 'On the way', arrived: arrived),
          ),
          const SizedBox(height: 6),
          Text(
            _headline(arrived),
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
                      : '${trip.vehicle}, ${parcelCount(trip.stillOnBoard.length)} on board',
                  style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: ending ? null : onEndTrip,
            // a little smaller than the theme's, since it sits inside the trip card
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: Text(ending ? 'Ending…' : 'End trip'),
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

  String _headline(bool arrived) {
    final expectedAt = trip.expectedArrival;

    if (arrived) {
      final scannedOff = trip.parcels.length - trip.stillOnBoard.length;

      return '$scannedOff of ${parcelCount(trip.parcels.length)} scanned off';
    }

    if (expectedAt != null) {
      return 'Expected in ${trip.to} about ${timeWithDay(expectedAt)}';
    }

    return 'On the way to ${trip.to}';
  }

  Widget _buildStatusTag(String text, {required bool arrived}) {
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
}
