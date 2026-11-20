import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// The parcel's town in red next to the town it was checked against, so the
// reason it can't go on or come off shows at a glance.
class TownComparison extends StatelessWidget {
  const TownComparison({
    super.key,
    required this.parcelLabel,
    required this.parcelTown,
    required this.otherLabel,
    required this.otherTown,
  });

  // like This parcel goes to and Nakuru
  final String parcelLabel;
  final String parcelTown;

  // like You're at and Nairobi
  final String otherLabel;
  final String otherTown;

  @override
  Widget build(BuildContext context) {
    // the two boxes stay the same height when a label runs onto two lines
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTown(parcelLabel, parcelTown, wrong: true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTown(otherLabel, otherTown)),
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
