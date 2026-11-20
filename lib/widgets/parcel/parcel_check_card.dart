import 'package:flutter/material.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_thumb.dart';

// On the Hand over screen. The photo from booking sits next to what's inside, so the
// receiver can see it is their parcel, in the same state, before taking it away.
class ParcelCheckCard extends StatelessWidget {
  const ParcelCheckCard({
    super.key,
    required this.booking,
    required this.photo,
    required this.hasPhoto,
    required this.onViewPhoto,
  });

  final BookedParcel booking;
  final ImageProvider photo;

  // old parcels from before photos were needed have nothing to check against
  final bool hasPhoto;
  final VoidCallback onViewPhoto;

  @override
  Widget build(BuildContext context) {
    final receiver = booking.receiverName.split(' ').first;

    return WhiteCard(
      padding: EdgeInsets.fromLTRB(hasPhoto ? 12 : 16, 12, hasPhoto ? 8 : 16, 12),
      child: Row(
        children: [
          if (hasPhoto) ...[
            ParcelThumb(photo: photo),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.contents,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  hasPhoto
                      ? '${booking.size.label}. Let $receiver check it matches this photo.'
                      : '${booking.size.label}. Let $receiver check it before taking it.',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (hasPhoto)
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
      ),
    );
  }
}
