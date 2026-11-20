import 'package:flutter/material.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// On the Hand over screen. Who the parcel is for, so the clerk can check it against their ID.
class ReceiverIdCard extends StatelessWidget {
  const ReceiverIdCard({super.key, required this.booking});

  final BookedParcel booking;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Receiver', style: TextStyle(fontSize: 12, color: AppColors.grey)),
          Text(
            booking.receiverName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          Text(
            localPhone(booking.receiverPhone),
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          const SizedBox(height: 10),
          const Text(
            'Check that their ID shows this name.',
            style: TextStyle(fontSize: 13, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }
}
