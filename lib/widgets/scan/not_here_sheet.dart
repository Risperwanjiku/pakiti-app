import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';
import 'package:pakiti_app/widgets/common/town_comparison.dart';

// For a parcel scanned at an office it isn't going to. It stays on the vehicle
// and carries on to its own town.
Future<void> showNotHereSheet(
  BuildContext context, {
  required String trackingNo,
  required String to,
  required String here,
}) {
  return showPakitiSheet<void>(
    context,
    builder: (_) => _NotHereSheet(trackingNo: trackingNo, to: to, here: here),
  );
}

class _NotHereSheet extends StatelessWidget {
  const _NotHereSheet({required this.trackingNo, required this.to, required this.here});

  final String trackingNo;
  final String to;
  final String here;

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'Not for this office',
      children: [
        const SizedBox(height: 16),
        TownComparison(
          parcelLabel: 'This parcel goes to',
          parcelTown: to,
          otherLabel: "You're at",
          otherTown: here,
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 16, color: AppColors.grey),
            children: [
              const TextSpan(text: 'Give '),
              TextSpan(
                text: trackingNo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              TextSpan(text: ' back to the conductor so it carries on to $to.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Scan the next parcel'),
        ),
      ],
    );
  }
}
