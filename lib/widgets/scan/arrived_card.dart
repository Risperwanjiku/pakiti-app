import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/done_tick.dart';

// Shows over the bottom of the camera once a parcel is marked as arrived,
// until the next label is scanned.
class ArrivedCard extends StatelessWidget {
  const ArrivedCard({super.key, required this.trackingNo, required this.receiverName});

  final String trackingNo;
  final String receiverName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x470F1B2D), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 1), child: DoneTick()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$trackingNo is in',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Ready for $receiverName to collect.',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
