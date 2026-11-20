import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/detail_row.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// what's inside, size, value and fee, and the photo taken at booking if there is one
class ParcelFactsCard extends StatelessWidget {
  const ParcelFactsCard({
    super.key,
    required this.details,
    required this.photo,
    required this.onViewPhoto,
  });

  final ParcelDetails details;
  final ImageProvider photo;
  final VoidCallback onViewPhoto;

  @override
  Widget build(BuildContext context) {
    final booking = details.booking;

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
          if (details.hasBookingPhoto) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.page),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _buildPhotoRow(),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildPhotoRow() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: photo,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              return frame == null && !wasSynchronouslyLoaded
                  ? _buildPhotoBox(Icons.photo_outlined)
                  : child;
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPhotoBox(Icons.image_not_supported_outlined);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo at booking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                dayAndTime(details.booking.bookedAt),
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onViewPhoto,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.link,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          child: const Text('View'),
        ),
      ],
    );
  }

  // stands in for the photo while it loads, or if it fails
  Widget _buildPhotoBox(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.page,
      child: Icon(icon, color: AppColors.border),
    );
  }
}
