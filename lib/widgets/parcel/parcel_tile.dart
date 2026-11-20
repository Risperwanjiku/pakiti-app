import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_card.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/time_ago.dart';
import 'package:pakiti_app/widgets/common/placeholder_bar.dart';
import 'package:pakiti_app/widgets/common/status_tag.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

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

    // Sitting at this office for 2 days or more: booked here and still not loaded,
    // or arrived here and still not collected.
    final waited = DateTime.now().difference(parcel.lastActivity);
    final atThisOffice = parcel.isOutgoing
        ? parcel.status == ParcelStatus.booked
        : parcel.status == ParcelStatus.arrived;
    final overdue = atThisOffice && waited.inDays >= 2;

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
                        style: const TextStyle(fontSize: 14, color: AppColors.grey),
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
      child: SizedBox(
        height: 76,
        child: WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlaceholderBar(width: 96, height: 16),
              PlaceholderBar(width: 180, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
