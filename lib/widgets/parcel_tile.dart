import 'package:flutter/material.dart';

import '../models/parcel_card.dart';
import '../theme/app_colors.dart';
import '../utils/time_ago.dart';
import 'status_tag.dart';

// one parcel in the lists on home and in search
class ParcelTile extends StatelessWidget {
  const ParcelTile({super.key, required this.parcel, required this.onTap});

  final ParcelCard parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = parcel.isOutgoing
        ? 'To ${parcel.otherName}, ${parcel.otherTown}'
        : 'From ${parcel.otherName}, ${parcel.otherTown}';

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
                      timeAgo(parcel.lastActivity),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
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