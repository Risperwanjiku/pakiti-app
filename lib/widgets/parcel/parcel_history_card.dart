import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_history.dart';

// the History title and card, with a note when the custody record checks out
class ParcelHistoryCard extends StatelessWidget {
  const ParcelHistoryCard({super.key, required this.details});

  final ParcelDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: ParcelHistory(details: details),
              ),
              if (details.recordChecked) ...[
                const Divider(height: 1, thickness: 1, color: AppColors.page),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _RecordCheckedNote(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordCheckedNote extends StatelessWidget {
  const _RecordCheckedNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 18,
          color: AppColors.statusCollected,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Custody record checked. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusCollected,
                  ),
                ),
                TextSpan(
                  text: 'Nothing has changed since each hand-off was recorded.',
                ),
              ],
            ),
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
