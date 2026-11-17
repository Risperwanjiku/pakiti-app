import 'package:flutter/material.dart';

import '../models/parcel_card.dart';
import '../models/parcel_status.dart';
import '../theme/app_colors.dart';
import '../utils/time_ago.dart';
import 'status_tag.dart';

// one parcel in the lists on home, in search and on the Parcels screen
class ParcelTile extends StatelessWidget {
  const ParcelTile({super.key, required this.parcel, required this.onTap});

  final ParcelCard parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = parcel.isOutgoing
        ? 'To ${parcel.otherName}, ${parcel.otherTown}'
        : 'From ${parcel.otherName}, ${parcel.otherTown}';

    // left at this office for 2 days or more without being collected
    final waited = DateTime.now().difference(parcel.lastActivity);
    final overdue = !parcel.isOutgoing &&
        parcel.status == ParcelStatus.arrived &&
        waited.inDays >= 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parcel.trackingNo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    StatusTag(status: parcel.status, isLate: parcel.isLate),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      overdue ? 'Waiting ${waited.inDays} days' : timeAgo(parcel.lastActivity),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: overdue ? FontWeight.w500 : FontWeight.w400,
                        color: overdue ? AppColors.statusArrived : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// shown in place of the tiles while they load
class ParcelTilePlaceholder extends StatelessWidget {
  const ParcelTilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_bar(96, 16), _bar(180, 14)],
        ),
      ),
    );
  }

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}