import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';

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
    builder: (_) => _KeepOffSheet(
      trackingNo: trackingNo,
      before: before,
      after: after,
      mismatch: mismatch,
    ),
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Keep this one off',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              if (mismatch != null) ...[
                const SizedBox(height: 16),
                _buildComparison(mismatch),
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
  }

  // the parcel's town in red next to the vehicle's, so the reason shows at a glance
  Widget _buildComparison(TownMismatch mismatch) {
    // the two boxes stay the same height when a label runs onto two lines
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildTown(mismatch.parcelLabel, mismatch.parcelTown, wrong: true),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildTown(mismatch.vehicleLabel, mismatch.vehicleTown)),
        ],
      ),
    );
  }

  Widget _buildTown(String label, String town, {bool wrong = false}) {
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
}
