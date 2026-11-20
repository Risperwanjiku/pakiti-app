import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/detail_row.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_thumb.dart';

// what's inside, size, value and fee, then the photos from booking and from the handover
class ParcelFactsCard extends StatelessWidget {
  const ParcelFactsCard({
    super.key,
    required this.details,
    required this.photo,
    required this.onViewPhoto,
    required this.handoverPhoto,
    required this.onViewHandoverPhoto,
  });

  final ParcelDetails details;
  final ImageProvider photo;
  final VoidCallback onViewPhoto;

  // only shown once the receiver has collected the parcel
  final ImageProvider handoverPhoto;
  final VoidCallback onViewHandoverPhoto;

  @override
  Widget build(BuildContext context) {
    final booking = details.booking;
    final collectedAt = details.timeOf(CustodyStep.collected);

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Parcel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                DetailRow(label: "What's inside", value: booking.contents),
                DetailRow(label: 'Size', value: booking.size.label),
                DetailRow(label: 'Value', value: ksh(booking.value)),
                DetailRow(label: 'Fee paid', value: ksh(booking.fee)),
              ],
            ),
          ),
          if (details.hasBookingPhoto)
            _buildPhotoRow('Photo at booking', booking.bookedAt, photo, onViewPhoto),
          if (collectedAt != null && details.hasHandoverPhoto)
            _buildPhotoRow('Photo at handover', collectedAt, handoverPhoto, onViewHandoverPhoto),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(String title, DateTime takenAt, ImageProvider image, VoidCallback onView) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1, color: AppColors.page),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            children: [
              ParcelThumb(photo: image, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      dayAndTime(takenAt),
                      style: const TextStyle(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: Text('View', semanticsLabel: 'View the ${title.toLowerCase()}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
