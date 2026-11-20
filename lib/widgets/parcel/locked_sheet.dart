import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';

// After the fifth wrong code. Only the admin can unlock the parcel, so there is
// nothing to choose here, just the way back to it.
Future<void> showLockedSheet(BuildContext context, String trackingNo) {
  return showPakitiSheet<void>(
    context,
    builder: (_) => _LockedSheet(trackingNo: trackingNo),
  );
}

class _LockedSheet extends StatelessWidget {
  const _LockedSheet({required this.trackingNo});

  final String trackingNo;

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'This parcel is locked',
      children: [
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'The code was wrong 5 times, so '),
              TextSpan(
                text: trackingNo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const TextSpan(
                text: " can't be handed over for now. Ask the admin to unlock it.",
              ),
            ],
          ),
          style: const TextStyle(fontSize: 16, color: AppColors.grey),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to the parcel'),
        ),
      ],
    );
  }
}
