import 'package:flutter/material.dart';

import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';

// Asked when the conductor ends a trip with parcels not yet scanned off.
// Gives back true to end the trip anyway, false to hand them over first,
// or null when the sheet is closed.
Future<bool?> showStillOnBoardSheet(BuildContext context, Trip trip) {
  return showPakitiSheet<bool>(
    context,
    builder: (_) => _StillOnBoardSheet(trip: trip),
  );
}

class _StillOnBoardSheet extends StatelessWidget {
  const _StillOnBoardSheet({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final stillOnBoard = trip.stillOnBoard;
    final justOne = stillOnBoard.length == 1;

    return SheetBody(
      title: justOne
          ? '1 parcel is still on the vehicle'
          : '${stillOnBoard.length} parcels are still on the vehicle',
      children: [
        for (final parcel in stillOnBoard) ...[
          const SizedBox(height: 12),
          _buildParcel(parcel),
        ],
        const SizedBox(height: 12),
        Text(
          'Check the boot and under the seats, then hand ${justOne ? 'it' : 'them'} '
          'to the clerk at ${trip.toOffice} to scan off.',
          style: const TextStyle(fontSize: 16, color: AppColors.grey),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(justOne ? "I'll hand it over" : "I'll hand them over"),
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
          justOne
              ? "The admin is told it wasn't handed over."
              : "The admin is told they weren't handed over.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildParcel(TripParcel parcel) {
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
}
