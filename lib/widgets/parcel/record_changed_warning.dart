import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// shown at the top of a parcel when its custody record no longer checks out
class RecordChangedWarning extends StatelessWidget {
  const RecordChangedWarning({super.key});

  @override
  Widget build(BuildContext context) {
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
}
