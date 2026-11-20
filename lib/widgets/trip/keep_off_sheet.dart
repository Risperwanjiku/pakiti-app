import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';
import 'package:pakiti_app/widgets/common/town_comparison.dart';

// The two towns that don't match, like where the parcel goes and where the vehicle goes.
class TownMismatch {
  const TownMismatch({
    required this.parcelLabel,
    required this.parcelTown,
    required this.vehicleLabel,
    required this.vehicleTown,
  });

  final String parcelLabel;
  final String parcelTown;
  final String vehicleLabel;
  final String vehicleTown;
}

// Tells the conductor a scanned parcel can't go on this vehicle, and why.
// The message reads: before, then the tracking number in bold, then after.
Future<void> showKeepOffSheet(
  BuildContext context, {
  required String trackingNo,
  String before = '',
  required String after,
  TownMismatch? mismatch,
}) {
  return showPakitiSheet<void>(
    context,
    builder: (_) =>
        _KeepOffSheet(trackingNo: trackingNo, before: before, after: after, mismatch: mismatch),
  );
}

class _KeepOffSheet extends StatelessWidget {
  const _KeepOffSheet({
    required this.trackingNo,
    required this.before,
    required this.after,
    required this.mismatch,
  });

  final String trackingNo;
  final String before;
  final String after;
  final TownMismatch? mismatch;

  @override
  Widget build(BuildContext context) {
    final mismatch = this.mismatch;

    return SheetBody(
      title: 'Keep this one off',
      children: [
        if (mismatch != null) ...[
          const SizedBox(height: 16),
          TownComparison(
            parcelLabel: mismatch.parcelLabel,
            parcelTown: mismatch.parcelTown,
            otherLabel: mismatch.vehicleLabel,
            otherTown: mismatch.vehicleTown,
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
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText),
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
    );
  }
}
