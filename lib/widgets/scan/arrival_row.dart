import 'package:flutter/material.dart';

import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';

// a parcel in the Marked as arrived today list
class ArrivalRow extends StatelessWidget {
  const ArrivalRow({super.key, required this.parcel});

  final ArrivedParcel parcel;

  @override
  Widget build(BuildContext context) {
    final vehicle = parcel.vehicle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
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
                  vehicle == null ? 'From ${parcel.from}' : 'From ${parcel.from} on $vehicle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(clockTime(parcel.at), style: const TextStyle(fontSize: 13, color: AppColors.grey)),
        ],
      ),
    );
  }
}
