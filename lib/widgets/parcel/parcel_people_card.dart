import 'package:flutter/material.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/call_button.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// the sender and the receiver, each with a button to call them
class ParcelPeopleCard extends StatelessWidget {
  const ParcelPeopleCard({super.key, required this.booking, required this.onCall});

  final BookedParcel booking;

  // gets the phone number to call
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        children: [
          _buildPerson('Sender', booking.senderName, booking.senderPhone),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          _buildPerson('Receiver', booking.receiverName, booking.receiverPhone),
        ],
      ),
    );
  }

  Widget _buildPerson(String role, String name, String phone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  localPhone(phone),
                  style: const TextStyle(fontSize: 14, color: AppColors.grey),
                ),
              ],
            ),
          ),
          CallButton(label: 'Call $name', onPressed: () => onCall(phone)),
        ],
      ),
    );
  }
}
